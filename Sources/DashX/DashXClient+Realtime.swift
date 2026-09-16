import Foundation
import UIKit

extension DashXClient {
    static let defaultRealtimeBaseURI = "wss://realtime.dashx.com"

    /// Overrides the realtime endpoint (e.g. staging).
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
            urlProvider: { self.realtimeURL() },
            onAnyFrame: { ChatCoordinator.shared.onGlobalFrame($0) },
            onAuthRejected: { completion in self.onRealtimeAuthRejected(completion: completion) },
            publishState: { state in self.publishConnectionState(from: created, state) },
            initialForeground: _lifecycleForeground
        )
        _realtimeRuntime = created
        return created
    }

    private func realtimeURL() -> URL? {
        guard let publicKey = ConfigInterceptor.shared.publicKey else { return nil }
        // Without an identity token the socket would connect anonymously and never deliver.
        guard let token = account.identityToken else { return nil }
        stateLock.lock()
        let base = _realtimeBaseURI ?? Self.defaultRealtimeBaseURI
        stateLock.unlock()

        var parameters = [("publicKey", publicKey)]
        if let targetEnvironment = ConfigInterceptor.shared.targetEnvironment {
            parameters.append(("targetEnvironment", targetEnvironment))
        }
        parameters.append(("identityToken", token))
        let query = parameters.map { "\($0.0)=\(Self.queryEncode($0.1))" }.joined(separator: "&")
        return URL(string: base + "?" + query)
    }

    private static func queryEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    func notifyIdentityChanged() {
        if let runtime = realtimeRuntime {
            runtime.onIdentityChanged()
        } else {
            ChatCoordinator.shared.onIdentityAvailable()
            publishDirect(.idle)
        }
    }

    private func publishConnectionState(from runtime: RealtimeRuntime, _ state: DashXConnectionState) {
        stateLock.lock()
        guard _realtimeRuntime === runtime else {
            stateLock.unlock()
            return
        }
        _connectionState = state
        let listeners = _connectionStateListeners
        stateLock.unlock()
        notifyConnectionStateListeners(listeners, state)
    }

    /// For states the client owns itself: no runtime yet, or auth failures.
    func publishDirect(_ state: DashXConnectionState) {
        stateLock.lock()
        if _connectionState == state {
            stateLock.unlock()
            return
        }
        _connectionState = state
        let listeners = _connectionStateListeners
        stateLock.unlock()
        notifyConnectionStateListeners(listeners, state)
    }

    func publishAuthFailed(_ cause: Error?) {
        publishDirect(.authenticationFailed(cause: cause))
    }

    private func notifyConnectionStateListeners(_ listeners: [DashXConnectionStateListener], _ state: DashXConnectionState) {
        guard !listeners.isEmpty else { return }
        DispatchQueue.main.async {
            listeners.forEach { $0.onConnectionStateChanged(state) }
        }
    }

    // MARK: - Process lifecycle

    /// The socket is connected only while the app is on screen.
    func registerLifecycleObserver() {
        let register = {
            guard self.lifecycleObservers.isEmpty else { return }
            self.setLifecycleForeground(UIApplication.shared.applicationState != .background)
            let center = NotificationCenter.default
            let toForeground: (Notification) -> Void = { _ in
                self.setLifecycleForeground(true)
                self.realtimeRuntime?.onForeground()
                ChatCoordinator.shared.onAppForegrounded()
            }
            self.lifecycleObservers = [
                center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: toForeground),
                center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: toForeground),
                center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
                    self.setLifecycleForeground(false)
                    self.realtimeRuntime?.onBackground()
                },
            ]
        }
        if Thread.isMainThread {
            register()
        } else {
            DispatchQueue.main.async(execute: register)
        }
    }

    private func setLifecycleForeground(_ foreground: Bool) {
        stateLock.lock()
        _lifecycleForeground = foreground
        stateLock.unlock()
        pushRuntime.setForeground(foreground)
    }
}
