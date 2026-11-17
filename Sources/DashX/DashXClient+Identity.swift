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
        /// Handed to a successor; only the successor's result completes it.
        case forwarded
        case done(String?)
    }

    /// Whether the load was asked for a token other than the held one, after a rejection.
    let forceRefresh: Bool
    private let lock = NSLock()
    private var outcome: Outcome = .pending
    private var waiters: [(String?) -> Void] = []

    init(forceRefresh: Bool) {
        self.forceRefresh = forceRefresh
    }

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

    /// Ignored once done or forwarded: a forwarded load's own provider no longer decides it.
    func complete(_ token: String?) {
        lock.lock()
        guard case .pending = outcome else {
            lock.unlock()
            return
        }
        finishLocked(token)
    }

    /// Stops this load's own provider from deciding it; `finishForwarding(to:)` hands its waiters
    /// on. Call in the `stateLock` hold that unbinds the provider: a provider answering after that
    /// hold but before the hand-off would otherwise complete the waiters empty. False when the
    /// load had already finished.
    func beginForwarding() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard case .pending = outcome else { return false }
        outcome = .forwarded
        return true
    }

    /// Completes a load that began forwarding with `successor`'s result. Call outside `stateLock`:
    /// a finished successor runs the waiters inline.
    func finishForwarding(to successor: TokenLoad) {
        successor.await { token in
            self.lock.lock()
            if case .done = self.outcome {
                self.lock.unlock()
                return
            }
            self.finishLocked(token)
        }
    }

    /// Call with `lock` held; releases it.
    private func finishLocked(_ token: String?) {
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

    /// Whether a delivery, the provider's or the timeout's, was already accepted.
    var isSettled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return delivered
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
    static let defaultTokenLoadTimeout: TimeInterval = 30

    /// Whether an identity token is currently held. Chat operations need one, or a bound
    /// `DashXTokenProvider` to load it.
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
            let awaitingToken = !hasToken || authFailed
            // A cached token under authenticationFailed IS the rejected token. A load the previous
            // provider left in flight is taken over, so its waiting retries reach this provider.
            let handedOff = superseded?.beginForwarding() == true ? superseded : nil
            let claimed = awaitingToken || handedOff != nil
                ? claimTokenLoadLocked(bound: bound, forceRefresh: (authFailed && hasToken) || handedOff?.forceRefresh == true)
                : nil
            stateLock.unlock()
            if let claimed {
                handedOff?.finishForwarding(to: claimed.load)
                if awaitingToken { publishDirect(.connecting) }
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
    /// a later identity session than the request's `identityGeneration`. A token-only identity
    /// ends with its token: nothing ties a next token to this user, whose open conversations a
    /// first activation would otherwise hand on. Returns the credentials the drop committed, which
    /// the public-key retry is bound to, or nil when nothing was dropped.
    func dropUnrefreshableIdentityToken(rejected: String?, identityGeneration: Int) -> CredentialVersion? {
        guard let rejected else { return nil }
        let isDroppable = {
            self._boundProvider == nil && self._account.identityToken == rejected
                && self._account.sessionGeneration == identityGeneration
        }
        stateLock.lock()
        let endsTokenOnlySession = isDroppable() && _account.uid == nil
        stateLock.unlock()
        // Detached while the expiring account still holds the token, so the realtime reset below
        // finds none of its subscriptions to fail first. Their leases learn of it only after the
        // commit: one reopened from that callback must open under the session that follows. A
        // change that wins the commit instead ends this session itself: every token change of a
        // token-only identity does.
        let notifyEnded = endsTokenOnlySession
            ? ChatCoordinator.shared.detachSessions(openedUnder: identityGeneration)
            : nil

        stateLock.lock()
        guard isDroppable() else {
            stateLock.unlock()
            notifyEnded?()
            return nil
        }
        _account.identityToken = nil
        _account.tokenEpoch += 1
        let endsSession = _account.uid == nil
        if endsSession { _account.sessionGeneration += 1 }
        persistIdentityLocked()
        let committed = _account
        // Queued in the commit's hold: the next identity can register a provider the moment the
        // lock is released, keeping these credentials until its token arrives, and a fast failure
        // of its first load must land after this reset rather than be cleared by it.
        if let runtime = _realtimeRuntime {
            runtime.onIdentityChanged(credentials: committed.credentialVersion)
        } else if endsSession && _tokenLoadInFlight == nil {
            setConnectionStateLocked(.idle)
        }
        stateLock.unlock()
        DashXLog.i(tag: #function, "Identity token expired with no provider bound; continuing unauthenticated")
        // A conversation opened under the expiring session after the detach. The next
        // identity's sessions, opened under the new generation, stay open.
        if endsSession { ChatCoordinator.shared.closeSessions(openedUnder: identityGeneration) }
        notifyEnded?()
        return committed.credentialVersion
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

    static let identityTokenUnavailableError = DashXClientError.customError(
        message: "The identity token provider supplied no token; the next call asks it again")

    /// The held token, or one from the bound provider: an in-flight load is joined, and with none
    /// in flight one starts, so a call right after registration or after a failed load reaches the
    /// provider. `.notIdentified` only when there is neither a token nor a provider; `.sessionEnded`
    /// when the identity session changes while waiting.
    func awaitIdentityToken(completion: @escaping (Result<String, DashXClientError>) -> Void) {
        stateLock.lock()
        if let token = _account.identityToken {
            stateLock.unlock()
            completion(.success(token))
            return
        }
        guard let bound = _boundProvider, bound.uid == _account.uid else {
            stateLock.unlock()
            completion(.failure(.notIdentified))
            return
        }
        let generation = _account.sessionGeneration
        let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: false)
        stateLock.unlock()
        claimed.launch?()
        awaitIdentityToken(from: claimed.load, generation: generation, completion: completion)
    }

    /// Settled by `load` alone: a re-registered provider forwards it explicitly, so a failure is
    /// final for this call and never waits on a load another call started.
    private func awaitIdentityToken(
        from load: TokenLoad,
        generation: Int,
        completion: @escaping (Result<String, DashXClientError>) -> Void
    ) {
        load.await { token in
            let current = self.account
            if current.sessionGeneration != generation {
                completion(.failure(.sessionEnded))
            } else if let token = token ?? current.identityToken {
                completion(.success(token))
            } else {
                completion(.failure(Self.identityTokenUnavailableError))
            }
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

    /// A stored realtime verdict for `credentials` left a subscriber without a socket. With a
    /// provider bound, starts or joins a load: forced while a token is held, since that token was
    /// rejected or failed to refresh. Its install reconnects and its failure fails the waiting
    /// subscribers, both the usual way. False when the credentials were replaced or no provider is
    /// bound: the verdict then stands until the host supplies a token.
    func recoverRealtimeCredentials(_ credentials: CredentialVersion) -> Bool {
        stateLock.lock()
        guard _account.credentialVersion == credentials, let bound = _boundProvider, bound.uid == _account.uid else {
            stateLock.unlock()
            return false
        }
        let claimed = claimTokenLoadLocked(bound: bound, forceRefresh: _account.identityToken != nil)
        stateLock.unlock()
        claimed.launch?()
        return true
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
        let fresh = TokenLoad(forceRefresh: forceRefresh)
        _tokenLoadInFlight = fresh
        let requestSnapshot = _account
        let timeout = _tokenLoadTimeout
        return ClaimedTokenLoad(load: fresh, launch: {
            self.launchTokenLoad(bound: bound, forceRefresh: forceRefresh, load: fresh, requestSnapshot: requestSnapshot, timeout: timeout)
        })
    }

    private func launchTokenLoad(
        bound: BoundTokenProvider,
        forceRefresh: Bool,
        load: TokenLoad,
        requestSnapshot: AccountSnapshot,
        timeout: TimeInterval
    ) {
        let callback = OnceTokenCallback { token, cause in
            self.finishTokenLoad(bound: bound, load: load, requestSnapshot: requestSnapshot, token: token, cause: cause)
        }
        // On its own queue: a provider blocking `tokenQueue` must not hold the timeout back.
        tokenTimeoutQueue.asyncAfter(deadline: .now() + timeout) {
            callback.onUnavailable(DashXClientError.customError(
                message: "The identity token provider did not respond within \(Int(timeout))s"))
        }
        tokenQueue.async {
            // Queued behind a provider that blocked, the load may have timed out or been superseded
            // meanwhile: its result would be discarded, and a forced refresh would still rotate the
            // host's credentials.
            guard !callback.isSettled, self.isCurrentTokenLoad(load, bound: bound) else {
                DashXLog.d(tag: #function, "Skipping a token load that settled while queued")
                return
            }
            bound.provider.loadToken(forceRefresh: forceRefresh, callback: callback)
        }
    }

    private func isCurrentTokenLoad(_ load: TokenLoad, bound: BoundTokenProvider) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _tokenLoadInFlight === load && _boundProvider === bound
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
