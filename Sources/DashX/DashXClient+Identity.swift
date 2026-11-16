import Foundation

/// Reference identity marks one registration: re-registering makes the predecessor's loads stale.
final class BoundTokenProvider {
    let uid: String
    let provider: DashXTokenProvider

    init(uid: String, provider: DashXTokenProvider) {
        self.uid = uid
        self.provider = provider
    }
}

/// Single-flight provider load. Completes once, after the token is installed, so an awaiting retry
/// never re-sends the rejected token.
final class TokenLoad {
    private enum Outcome {
        case pending
        case done(String?)
    }

    private let lock = NSLock()
    private var outcome: Outcome = .pending
    private var waiters: [(String?) -> Void] = []

    func await(_ completion: @escaping (String?) -> Void) {
        lock.lock()
        if case .done(let token) = outcome {
            lock.unlock()
            completion(token)
            return
        }
        waiters.append(completion)
        lock.unlock()
    }

    func complete(_ token: String?) {
        lock.lock()
        if case .done = outcome {
            lock.unlock()
            return
        }
        outcome = .done(token)
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        pending.forEach { $0(token) }
    }
}

/// Accepts only the provider's first delivery.
private final class OnceTokenCallback: DashXTokenCallback {
    private let lock = NSLock()
    private var delivered = false
    private let deliver: (_ token: String?, _ cause: Error?) -> Void

    init(_ deliver: @escaping (_ token: String?, _ cause: Error?) -> Void) {
        self.deliver = deliver
    }

    func onToken(_ token: String) {
        fire(token, nil)
    }

    func onUnavailable(_ cause: Error?) {
        fire(nil, cause)
    }

    private func fire(_ token: String?, _ cause: Error?) {
        lock.lock()
        if delivered {
            lock.unlock()
            return
        }
        delivered = true
        lock.unlock()
        deliver(token, cause)
    }
}

extension DashXClient {
    static let tokenLoadTimeout: TimeInterval = 30

    /// Whether an identity token is currently held; chat operations require one.
    public var hasIdentityToken: Bool { account.identityToken != nil }

    var identityToken: String? { account.identityToken }

    /// Stamp for the auth retry: an old-era request is never resent with a new-era token.
    var currentSessionGeneration: Int { account.sessionGeneration }

    /// Registers a token provider for `uid`; it is asked again, with `forceRefresh`, after a rejection.
    public func setIdentityTokenProvider(uid: String, provider: DashXTokenProvider) {
        let current = account
        let bound = BoundTokenProvider(uid: uid, provider: provider)

        // Each branch claims its load in the same lock hold that commits the identity: a realtime
        // state resolved in between would otherwise see neither a token nor a pending load.
        if current.uid == nil && current.identityToken == nil {
            stateLock.lock()
            _boundProvider = bound
            _account.uid = uid
            _account.identityToken = nil
            persistIdentityLocked()
            let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: false)
            stateLock.unlock()
            publishDirect(.connecting)
            claimed.launch?()
        } else if current.uid == uid {
            stateLock.lock()
            _boundProvider = bound
            let superseded = _tokenLoadInFlight
            _tokenLoadInFlight = nil
            let authFailed: Bool
            if case .authenticationFailed = _connectionState { authFailed = true } else { authFailed = false }
            let hasToken = _account.identityToken != nil
            // A cached token under authenticationFailed IS the rejected token.
            let claimed = !hasToken || authFailed
                ? claimTokenLoadLocked(bound: bound, forceRefresh: authFailed && hasToken)
                : nil
            stateLock.unlock()
            superseded?.complete(nil)
            if let claimed {
                publishDirect(.connecting)
                claimed.launch?()
            }
        } else {
            endIdentitySession()
            stateLock.lock()
            _boundProvider = bound
            _account.uid = uid
            _account.identityToken = nil
            _account.sessionGeneration += 1
            persistIdentityLocked()
            let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: false)
            stateLock.unlock()
            publishDirect(.connecting)
            claimed.launch?()
        }
    }

    /// Closes the previous identity's chat sessions and drops its provider. Persisted identity and
    /// the push subscription are untouched; that is `reset()`.
    func endIdentitySession() {
        stateLock.lock()
        _boundProvider = nil
        let superseded = _tokenLoadInFlight
        _tokenLoadInFlight = nil
        let runtime = _realtimeRuntime
        stateLock.unlock()
        // Queued ahead of the departing sessions' unsubscribes and of the superseded refresh's
        // outcome, so neither publishes or acts on the previous identity's auth state.
        runtime?.onIdentityEnded()
        superseded?.complete(nil)
        ChatCoordinator.shared.closeAllSessions()
        pushRuntime.clearVisible()
    }

    /// Drops the held token when no provider is bound to refresh it, so requests fall back to the
    /// public key; with a provider bound the retry path refreshes instead. A newer token is never
    /// cleared by an old rejection: neither another token string nor the same string re-issued to
    /// a later identity session than the request's `identityGeneration`.
    func dropUnrefreshableIdentityToken(rejected: String?, identityGeneration: Int) -> Bool {
        guard let rejected else { return false }
        stateLock.lock()
        if _boundProvider != nil || _account.identityToken != rejected || _account.sessionGeneration != identityGeneration {
            stateLock.unlock()
            return false
        }
        _account.identityToken = nil
        _account.tokenEpoch += 1
        persistIdentityLocked()
        let credentials = _account.credentialVersion
        let runtime = _realtimeRuntime
        stateLock.unlock()
        DashXLog.i(tag: #function, "Identity token expired with no provider bound; continuing unauthenticated")
        runtime?.onIdentityChanged(credentials: credentials)
        return true
    }

    /// Refreshes the token, joining any in-flight load, and reports whether a new one is installed.
    /// With `expected`, the credentials the rejected request carried: under an earlier identity
    /// session it reports `false`, and once this session holds a newer token it reports `true` for
    /// the retry to use it. Neither asks the provider. The check and the load claim share one lock
    /// hold, so no switch or token install can slip between them.
    func awaitTokenRefresh(expected: CredentialVersion? = nil, completion: @escaping (Bool) -> Void) {
        stateLock.lock()
        if let expected {
            if expected.sessionGeneration != _account.sessionGeneration {
                stateLock.unlock()
                completion(false)
                return
            }
            if expected.tokenEpoch != _account.tokenEpoch {
                stateLock.unlock()
                completion(true)
                return
            }
        }
        guard let bound = _boundProvider else {
            stateLock.unlock()
            completion(false)
            return
        }
        let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: true)
        stateLock.unlock()
        claimed.launch?()
        claimed.load.await { completion($0 != nil) }
    }

    func awaitTokenRefresh() async -> Bool {
        await withCheckedContinuation { continuation in
            awaitTokenRefresh { continuation.resume(returning: $0) }
        }
    }

    /// A 4401 on a socket opened with `credentials`. Once they are replaced, by a later identity
    /// or a newer token of this one, the answer is `.superseded`: neither the provider nor the
    /// published state is touched, and the runtime returns the refresh attempt to the replacement,
    /// whose own change resets or recycles the socket. The version check, the provider choice and
    /// the load claim or state write share one lock hold, so no switch or token install can slip
    /// between them.
    func onRealtimeAuthRejected(credentials: CredentialVersion, completion: @escaping (AuthRefreshOutcome) -> Void) {
        stateLock.lock()
        guard _account.credentialVersion == credentials else {
            stateLock.unlock()
            completion(.superseded)
            return
        }
        guard let bound = _boundProvider, bound.uid == _account.uid else {
            setConnectionStateLocked(.authenticationFailed(cause: nil))
            stateLock.unlock()
            completion(.failed)
            return
        }
        let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: true)
        stateLock.unlock()
        claimed.launch?()
        claimed.load.await { completion($0 != nil ? .refreshed : .failed) }
    }

    struct ClaimedTokenLoad {
        let load: TokenLoad
        /// Set when this call claimed the slot for a new load; run it after releasing `stateLock`.
        let launch: (() -> Void)?
    }

    /// Call with `stateLock` held. Joins the in-flight load or claims the slot for a new one. A
    /// result is stale, and discarded, if the session generation or token epoch moved or the
    /// provider was replaced since the claim.
    func claimTokenLoadLocked(bound: BoundTokenProvider, forceRefresh: Bool) -> ClaimedTokenLoad {
        if let inFlight = _tokenLoadInFlight { return ClaimedTokenLoad(load: inFlight, launch: nil) }
        let fresh = TokenLoad()
        _tokenLoadInFlight = fresh
        let requestSnapshot = _account
        return ClaimedTokenLoad(load: fresh, launch: {
            self.launchTokenLoad(bound: bound, forceRefresh: forceRefresh, load: fresh, requestSnapshot: requestSnapshot)
        })
    }

    private func launchTokenLoad(bound: BoundTokenProvider, forceRefresh: Bool, load: TokenLoad, requestSnapshot: AccountSnapshot) {
        let callback = OnceTokenCallback { token, cause in
            self.finishTokenLoad(bound: bound, load: load, requestSnapshot: requestSnapshot, token: token, cause: cause)
        }
        tokenQueue.asyncAfter(deadline: .now() + Self.tokenLoadTimeout) {
            callback.onUnavailable(DashXClientError.customError(
                message: "The identity token provider did not respond within \(Int(Self.tokenLoadTimeout))s"))
        }
        tokenQueue.async {
            bound.provider.loadToken(forceRefresh: forceRefresh, callback: callback)
        }
    }

    private func finishTokenLoad(bound: BoundTokenProvider, load: TokenLoad, requestSnapshot: AccountSnapshot, token: String?, cause: Error?) {
        // Validate and install atomically, or a switch in between would install this token under the
        // new uid.
        stateLock.lock()
        let providerStillBound = _boundProvider === bound
        let matchesRequest = _account.sessionGeneration == requestSnapshot.sessionGeneration
            && _account.tokenEpoch == requestSnapshot.tokenEpoch
        var installed = false
        if let token, providerStillBound, matchesRequest {
            _account.identityToken = token
            _account.tokenEpoch += 1
            persistIdentityLocked()
            installed = true
        }
        let stale = !installed && (!providerStillBound || !matchesRequest)
        // Release the slot before completing: a waiter may request another load at once, and must
        // reach the provider rather than join this finished one.
        if _tokenLoadInFlight === load { _tokenLoadInFlight = nil }
        // With no runtime the client owns the state. Written in the install's lock hold, so the
        // `.idle` belongs to this account and cannot overwrite a later identity's `.connecting`.
        let runtime = _realtimeRuntime
        let installedCredentials = _account.credentialVersion
        if installed && runtime == nil { setConnectionStateLocked(.idle) }
        stateLock.unlock()

        if installed {
            // Stamped: if another change lands before the runtime runs this, it is dropped rather
            // than clear that change's state.
            runtime?.onIdentityChanged(fromAuthRefresh: true, credentials: installedCredentials)
            load.complete(token)
        } else {
            if !stale { reportCredentialsUnavailable(cause, bound: bound, requestSnapshot: requestSnapshot) }
            load.complete(nil)
        }
    }
}
