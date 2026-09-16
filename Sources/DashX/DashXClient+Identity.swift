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

        if current.uid == nil && current.identityToken == nil {
            stateLock.lock()
            _boundProvider = bound
            _account.uid = uid
            _account.identityToken = nil
            let snapshot = _account
            stateLock.unlock()
            persistIdentity(snapshot)
            publishDirect(.connecting)
            requestTokenLoad(forceRefresh: false)
        } else if current.uid == uid {
            stateLock.lock()
            _boundProvider = bound
            let superseded = _tokenLoadInFlight
            _tokenLoadInFlight = nil
            stateLock.unlock()
            superseded?.complete(nil)
            let authFailed: Bool
            if case .authenticationFailed = connectionState { authFailed = true } else { authFailed = false }
            if current.identityToken == nil || authFailed {
                // A cached token under authenticationFailed IS the rejected token.
                publishDirect(.connecting)
                requestTokenLoad(forceRefresh: authFailed && current.identityToken != nil)
            }
        } else {
            endIdentitySession()
            stateLock.lock()
            _boundProvider = bound
            _account.uid = uid
            _account.identityToken = nil
            _account.sessionGeneration += 1
            let snapshot = _account
            stateLock.unlock()
            persistIdentity(snapshot)
            publishDirect(.connecting)
            requestTokenLoad(forceRefresh: false)
        }
    }

    /// Closes the previous identity's chat sessions and drops its provider. Persisted identity and
    /// the push subscription are untouched; that is `reset()`.
    func endIdentitySession() {
        stateLock.lock()
        _boundProvider = nil
        let superseded = _tokenLoadInFlight
        _tokenLoadInFlight = nil
        stateLock.unlock()
        superseded?.complete(nil)
        ChatCoordinator.shared.closeAllSessions()
        pushRuntime.clearVisible()
    }

    /// Drops the held token when no provider can refresh it, so requests fall back to the public
    /// key. A newer token is never cleared by an old rejection.
    func dropUnrefreshableIdentityToken(rejected: String?) -> Bool {
        guard let rejected else { return false }
        stateLock.lock()
        if _boundProvider != nil || _account.identityToken != rejected {
            stateLock.unlock()
            return false
        }
        _account.identityToken = nil
        _account.tokenEpoch += 1
        let snapshot = _account
        stateLock.unlock()
        DashXLog.i(tag: #function, "Identity token expired with no provider bound; continuing unauthenticated")
        persistIdentity(snapshot)
        realtimeRuntime?.onIdentityChanged()
        return true
    }

    /// Refreshes the token, joining any in-flight load, and reports whether a new one is installed.
    func awaitTokenRefresh(completion: @escaping (Bool) -> Void) {
        guard let load = startOrJoinTokenLoad(forceRefresh: true) else {
            completion(false)
            return
        }
        load.await { completion($0 != nil) }
    }

    func awaitTokenRefresh() async -> Bool {
        await withCheckedContinuation { continuation in
            awaitTokenRefresh { continuation.resume(returning: $0) }
        }
    }

    func onRealtimeAuthRejected(completion: @escaping (Bool) -> Void) {
        stateLock.lock()
        let bound = _boundProvider
        let uid = _account.uid
        stateLock.unlock()
        guard let bound, bound.uid == uid else {
            publishAuthFailed(nil)
            completion(false)
            return
        }
        awaitTokenRefresh(completion: completion)
    }

    private func requestTokenLoad(forceRefresh: Bool) {
        _ = startOrJoinTokenLoad(forceRefresh: forceRefresh)
    }

    /// A result is stale, and discarded, if the session generation or token epoch moved or the
    /// provider was replaced since the request.
    private func startOrJoinTokenLoad(forceRefresh: Bool) -> TokenLoad? {
        stateLock.lock()
        guard let bound = _boundProvider else {
            stateLock.unlock()
            return nil
        }
        if let inFlight = _tokenLoadInFlight {
            stateLock.unlock()
            return inFlight
        }
        let fresh = TokenLoad()
        _tokenLoadInFlight = fresh
        let requestSnapshot = _account
        stateLock.unlock()
        launchTokenLoad(bound: bound, forceRefresh: forceRefresh, load: fresh, requestSnapshot: requestSnapshot)
        return fresh
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
            installed = true
        }
        let stale = !installed && (!providerStillBound || !matchesRequest)
        // Release the slot before completing: a waiter may request another load at once, and must
        // reach the provider rather than join this finished one.
        if _tokenLoadInFlight === load { _tokenLoadInFlight = nil }
        let snapshot = _account
        stateLock.unlock()

        if installed {
            persistIdentity(snapshot)
            if let runtime = realtimeRuntime {
                runtime.onIdentityChanged(fromAuthRefresh: true)
            } else {
                ChatCoordinator.shared.onIdentityAvailable()
                publishDirect(.idle)
            }
            load.complete(token)
        } else {
            if !stale { publishAuthFailed(cause) }
            load.complete(nil)
        }
    }
}
