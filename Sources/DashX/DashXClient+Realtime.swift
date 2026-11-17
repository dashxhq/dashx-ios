import Foundation

extension DashXClient {
    static let defaultRealtimeBaseURI = "wss://realtime.dashx.com"

    /// Overrides the realtime endpoint (e.g. staging): an absolute `ws://` or `wss://` URL with a
    /// host. Anything else makes conversations report a configuration error. The SDK supplies the
    /// credentials: an override's `publicKey`, `identityToken` and `accountToken` are dropped, and
    /// a configured target environment replaces its `targetEnvironment`.
    public func setRealtimeBaseURI(_ uri: String?) {
        stateLock.lock()
        defer { stateLock.unlock() }
        _realtimeBaseURI = uri
    }

    /// The realtime connection's current state; listeners hear every change on the main queue.
    public var connectionState: DashXConnectionState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _connectionState
    }

    public func addConnectionStateListener(_ listener: DashXConnectionStateListener) {
        stateLock.lock()
        defer { stateLock.unlock() }
        _connectionStateListeners.append(listener)
    }

    public func removeConnectionStateListener(_ listener: DashXConnectionStateListener) {
        stateLock.lock()
        defer { stateLock.unlock() }
        _connectionStateListeners.removeAll { $0 === listener }
    }

    /// Final say on displaying a DashX notification in the foreground.
    public func setNotificationDisplayDecider(_ decider: DashXNotificationDisplayDecider?) {
        DashXPush.displayDecider = decider
    }

    var realtimeRuntime: RealtimeRuntime? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _realtimeRuntime
    }

    /// Lazily created: no chat subscribers → no runtime, no socket.
    func requireRealtimeRuntime() -> RealtimeRuntime {
        stateLock.lock()
        defer { stateLock.unlock() }
        if let existing = _realtimeRuntime { return existing }
        var created: RealtimeRuntime!
        created = RealtimeRuntime(
            endpointProvider: { self.realtimeEndpoint() },
            unmetPrerequisite: { self.realtimeUnmetPrerequisite() },
            currentCredentials: { self.account.credentialVersion },
            onAuthRejected: { credentials, completion in
                self.onRealtimeAuthRejected(credentials: credentials, completion: completion)
            },
            recoverCredentials: { self.recoverRealtimeCredentials($0) },
            publishState: { status in self.publishConnectionState(from: created, status) },
            initialForeground: _lifecycleForeground,
            socketFactory: _realtimeSocketFactory
        )
        _realtimeRuntime = created
        if case .authenticationFailed(let cause) = _connectionState {
            created.onCredentialsUnavailable(cause: cause, credentials: _account.credentialVersion)
        }
        return created
    }

    func realtimeEndpoint() -> RealtimeEndpoint? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return realtimeEndpointLocked()
    }

    /// Call with `stateLock` held: the URL and its identity stamp come from one account snapshot.
    private func realtimeEndpointLocked() -> RealtimeEndpoint? {
        // Without an identity token the socket would connect anonymously and never deliver.
        guard let publicKey = ConfigInterceptor.shared.publicKey, let token = _account.identityToken else { return nil }
        return realtimeURL(base: realtimeBaseURILocked, publicKey: publicKey, token: token).map {
            RealtimeEndpoint(url: $0, credentials: _account.credentialVersion)
        }
    }

    private var realtimeBaseURILocked: String { _realtimeBaseURI ?? Self.defaultRealtimeBaseURI }

    /// Credentials an override must never carry: only the SDK's identity token may authenticate.
    private static let realtimeOverrideStrippedParameters: Set<String> = ["accountToken"]

    /// The query values are percent-encoded, so only the base URI can make this nil.
    /// `webSocketTask(with:)` raises an exception for anything but a lowercase `ws` or `wss` URL,
    /// while `URL(string:)` accepts relative, non-WebSocket and uppercase-scheme URLs alike; so the
    /// host is required and the scheme is checked and lowercased here, before any socket exists.
    private func realtimeURL(base: String, publicKey: String, token: String) -> URL? {
        guard var components = URLComponents(string: base),
              let scheme = components.scheme?.lowercased(), scheme == "ws" || scheme == "wss",
              let host = components.host, !host.isEmpty
        else { return nil }
        components.scheme = scheme
        var parameters = [("publicKey", publicKey)]
        if let targetEnvironment = ConfigInterceptor.shared.targetEnvironment {
            parameters.append(("targetEnvironment", targetEnvironment))
        }
        parameters.append(("identityToken", token))
        // The SDK's values replace same-named items of the override, which the server's typed
        // query decoder would otherwise reject as duplicates. `accountToken` is stripped too: the
        // server lets it win over `identityToken` and then resolves no visitor, so the socket would
        // connect while every conversation subscription is denied. Unrelated items are kept.
        let replacedNames = Set(parameters.map(\.0)).union(Self.realtimeOverrideStrippedParameters)
        let preserved = (components.percentEncodedQueryItems ?? []).filter {
            !replacedNames.contains($0.name.removingPercentEncoding ?? $0.name)
        }
        components.percentEncodedQueryItems = preserved + parameters.map {
            URLQueryItem(name: $0.0, value: Self.queryEncode($0.1))
        }
        return components.url
    }

    private func realtimeUnmetPrerequisite() -> DashXClientError? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return realtimeUnmetPrerequisiteLocked()
    }

    /// Call with `stateLock` held. Why no realtime endpoint can be built, or nil while a provider
    /// load is bringing the only thing missing, the token.
    private func realtimeUnmetPrerequisiteLocked() -> DashXClientError? {
        guard let publicKey = ConfigInterceptor.shared.publicKey else {
            return .customError(message: "DashX is not configured; call configure() before opening a conversation")
        }
        let base = realtimeBaseURILocked
        // Checked before the token: a load in flight would otherwise mask a URL that never forms.
        guard realtimeURL(base: base, publicKey: publicKey, token: _account.identityToken ?? "") != nil else {
            return .customError(message: "The realtime base URI \(base) is not an absolute ws:// or wss:// URL; check setRealtimeBaseURI(_:)")
        }
        if _account.identityToken != nil || _tokenLoadInFlight != nil { return nil }
        return .notIdentified
    }

    private static func queryEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    /// `committed` is the account the identity change wrote.
    func notifyIdentityChanged(committed: AccountSnapshot) {
        if let runtime = realtimeRuntime {
            runtime.onIdentityChanged(credentials: committed.credentialVersion)
        } else {
            publishIdle(ifCurrent: committed)
        }
    }

    /// Publishes `.idle` only while the account is still the one `committed` describes and no token
    /// load is pending, checked in the lock hold that writes it: a later identity's state is never
    /// overwritten. The uid matters on its own: provider registration on a signed-out account
    /// changes it without moving the session generation or the token epoch.
    func publishIdle(ifCurrent committed: AccountSnapshot) {
        stateLock.lock()
        let isCurrent = _account.uid == committed.uid
            && _account.sessionGeneration == committed.sessionGeneration
            && _account.tokenEpoch == committed.tokenEpoch
            && _tokenLoadInFlight == nil
        if isCurrent { setConnectionStateLocked(.idle) }
        stateLock.unlock()
    }

    /// Resolves the runtime's status against the credentials in the same lock hold that writes the
    /// state, so it never pairs one identity's runtime facts with another's credentials.
    private func publishConnectionState(from runtime: RealtimeRuntime, _ status: RealtimeStatus) {
        stateLock.lock()
        guard _realtimeRuntime === runtime else {
            stateLock.unlock()
            return
        }
        let endpointAvailable = realtimeEndpointLocked() != nil
        let state = status.resolve(
            endpointAvailable: endpointAvailable,
            awaitingToken: !endpointAvailable && realtimeUnmetPrerequisiteLocked() == nil,
            current: _account.credentialVersion
        )
        if let state { setConnectionStateLocked(state) }
        stateLock.unlock()
    }

    /// For states the client owns itself: no runtime yet, or auth failures.
    func publishDirect(_ state: DashXConnectionState) {
        stateLock.lock()
        setConnectionStateLocked(state)
        stateLock.unlock()
    }

    /// Call with `stateLock` held. Writes `state` and enqueues its notification in the same hold:
    /// the main queue is FIFO, so listeners hear the transitions in the order they were written.
    func setConnectionStateLocked(_ state: DashXConnectionState) {
        guard _connectionState != state else { return }
        _connectionState = state
        notifyConnectionStateListeners(_connectionStateListeners, state)
    }

    /// A failed provider load, published only while the load it belongs to is still the current
    /// one: a token installed meanwhile must not be followed by a stale `authenticationFailed`.
    /// Once a runtime exists it owns the published state, so the failure goes through it.
    func reportCredentialsUnavailable(_ cause: Error?, bound: BoundTokenProvider, requestSnapshot: AccountSnapshot) {
        // Evaluated under `stateLock`.
        let isCurrent = {
            self._boundProvider === bound
                && self._account.sessionGeneration == requestSnapshot.sessionGeneration
                && self._account.tokenEpoch == requestSnapshot.tokenEpoch
        }
        stateLock.lock()
        if let runtime = _realtimeRuntime {
            stateLock.unlock()
            runtime.onCredentialsUnavailable(cause: cause, credentials: requestSnapshot.credentialVersion) {
                self.stateLock.lock()
                defer { self.stateLock.unlock() }
                return isCurrent()
            }
            return
        }
        if isCurrent() { setConnectionStateLocked(.authenticationFailed(cause: cause)) }
        stateLock.unlock()
    }

    private func notifyConnectionStateListeners(_ listeners: [DashXConnectionStateListener], _ state: DashXConnectionState) {
        guard !listeners.isEmpty else { return }
        DispatchQueue.main.async {
            listeners.forEach { $0.onConnectionStateChanged(state) }
        }
    }

    // MARK: - Process lifecycle

    /// Fed by `DashXApplicationLifecycleCallbacks`; the socket is connected only while the app is
    /// on screen.
    func setLifecycleForeground(_ foreground: Bool) {
        stateLock.lock()
        _lifecycleForeground = foreground
        stateLock.unlock()
        pushRuntime.setForeground(foreground)
        if foreground {
            realtimeRuntime?.onForeground()
            ChatCoordinator.shared.onAppForegrounded()
        } else {
            realtimeRuntime?.onBackground()
        }
    }
}
