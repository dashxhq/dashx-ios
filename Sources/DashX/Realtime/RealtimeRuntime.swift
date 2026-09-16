import Foundation

protocol DashXRealtimeSubscription {
    func unsubscribe()
}

/// `onEstablished` fires on every acknowledgement; `isResubscribe` is true when the channel was
/// already acknowledged under an earlier connection — the cue to reconcile missed history.
final class SubscriberHandle {
    let channelName: String
    let onFrame: (DashXRealtimeMessage) -> Void
    let onEstablished: (_ isResubscribe: Bool) -> Void
    /// Not acknowledged within the deadline. A rejected SUBSCRIBE is answered with an `ERROR` frame
    /// that names no channel, so the rejection only surfaces here. The handle stays registered; a
    /// later acknowledgement recovers.
    let onSubscribeError: (DashXClientError) -> Void

    init(
        channelName: String,
        onFrame: @escaping (DashXRealtimeMessage) -> Void,
        onEstablished: @escaping (_ isResubscribe: Bool) -> Void,
        onSubscribeError: @escaping (DashXClientError) -> Void = { _ in }
    ) {
        self.channelName = channelName
        self.onFrame = onFrame
        self.onEstablished = onEstablished
        self.onSubscribeError = onSubscribeError
    }
}

protocol RealtimeSocket: AnyObject {
    func send(text: String)
    func close(code: Int, reason: String?)
    func cancel()
}

protocol RealtimeSocketListener: AnyObject {
    func socketDidOpen(_ socket: RealtimeSocket)
    func socket(_ socket: RealtimeSocket, didReceiveText text: String)
    func socket(_ socket: RealtimeSocket, didCloseWithCode code: Int, reason: String)
    func socket(_ socket: RealtimeSocket, didFailWithError error: Error)
}

/// Creates a socket that starts connecting immediately.
typealias RealtimeSocketFactory = (URL, RealtimeSocketListener) -> RealtimeSocket

/// Single-writer actor over `queue`: socket callbacks enqueue generation-stamped commands, so no
/// field needs a lock and events from a departed socket are no-ops.
final class RealtimeRuntime {
    static let ackTimeout: TimeInterval = 10
    private static let pingInterval: TimeInterval = 30
    private static let initialReconnectDelay: TimeInterval = 1
    private static let maxReconnectDelay: TimeInterval = 30
    private static let normalClosure = 1000
    private static let terminalCloseCodeRange = 4400...4499
    /// Mirrors HTTP 401 — the only close a token refresh can fix.
    private static let closeCodeUnauthorized = 4401
    private static let tag = "DashXRealtime"

    static func isTerminalCloseCode(_ code: Int) -> Bool {
        terminalCloseCodeRange.contains(code)
    }

    static func chatChannelName(conversationId: String) -> String {
        "in_app_chat:conversation:\(conversationId)"
    }

    private let queue = DispatchQueue(label: "com.dashx.ios.realtime")
    private let urlProvider: () -> URL?
    private let onAnyFrame: (DashXRealtimeMessage) -> Void
    /// 4401 close: asks for a fresh token once; reports whether one was installed.
    private let onAuthRejected: (_ completion: @escaping (Bool) -> Void) -> Void
    private let publishStateSink: (DashXConnectionState) -> Void
    private let socketFactory: RealtimeSocketFactory
    private let ackTimeout: TimeInterval

    private var ended = false
    private var connectionGeneration = 0
    private var socket: RealtimeSocket?
    private var connectingSocket: RealtimeSocket?
    private var isForeground: Bool
    private var authFailed = false
    /// One refresh per rejection cycle: set when 4401 fires the hook, re-armed only by an ack or an
    /// external (non-refresh) identity change — a refreshed token that 4401s again stays terminal.
    private var authRefreshAttempted = false
    /// Advanced by every identity change; a refresh outcome from before it is stale.
    private var credentialGeneration = 0
    private var reconnectAttempts = 0
    /// Channel → SUBSCRIBE attempt still awaiting its acknowledgement; a deadline fires only while
    /// its own attempt is the pending one.
    private var pendingAcks: [String: Int] = [:]
    private var subscribeAttemptCounter = 0
    private var subscriptions: [String: [SubscriberHandle]] = [:]
    /// Channel → generation of its first acknowledgement. Kept across reconnects: a later-generation
    /// acknowledgement is how a re-subscribe is recognised.
    private var firstAckGeneration: [String: Int] = [:]

    init(
        urlProvider: @escaping () -> URL?,
        onAnyFrame: @escaping (DashXRealtimeMessage) -> Void,
        onAuthRejected: @escaping (_ completion: @escaping (Bool) -> Void) -> Void,
        publishState: @escaping (DashXConnectionState) -> Void,
        initialForeground: Bool,
        socketFactory: RealtimeSocketFactory? = nil,
        ackTimeout: TimeInterval = RealtimeRuntime.ackTimeout
    ) {
        self.urlProvider = urlProvider
        self.onAnyFrame = onAnyFrame
        self.onAuthRejected = onAuthRejected
        self.publishStateSink = publishState
        self.isForeground = initialForeground
        self.socketFactory = socketFactory ?? { url, listener in
            URLSessionRealtimeSocket(url: url, listener: listener, pingInterval: RealtimeRuntime.pingInterval)
        }
        self.ackTimeout = ackTimeout
    }

    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription {
        enqueue { self.handleSubscribe(handle) }
        return Subscription { [weak self] in
            self?.enqueue { self?.handleUnsubscribe(handle) }
        }
    }

    func onForeground() {
        enqueue { self.handleForegrounded() }
    }

    func onBackground() {
        enqueue { self.handleBackgrounded() }
    }

    /// Recycles the socket under the new credentials. `fromAuthRefresh` marks a token minted after a
    /// rejection: it earns one reconnect but does not re-arm the 4401 refresh hook.
    func onIdentityChanged(fromAuthRefresh: Bool = false) {
        enqueue { self.handleIdentityChanged(fromAuthRefresh: fromAuthRefresh) }
    }

    func endSession(completion: (() -> Void)? = nil) {
        queue.async {
            if !self.ended { self.handleEndSession() }
            completion?()
        }
    }

    private func enqueue(_ command: @escaping () -> Void) {
        queue.async {
            guard !self.ended else { return }
            command()
        }
    }

    private struct Subscription: DashXRealtimeSubscription {
        let onUnsubscribe: () -> Void
        func unsubscribe() { onUnsubscribe() }
    }

    private func handleSubscribe(_ handle: SubscriberHandle) {
        var handles = subscriptions[handle.channelName] ?? []
        handles.append(handle)
        subscriptions[handle.channelName] = handles
        let isFirstForChannel = handles.count == 1

        if socket == nil && connectingSocket == nil {
            connect()
        } else if let socket, isFirstForChannel {
            socket.send(text: DashXRealtimeCodec.encodeChannelFrame(
                type: DashXRealtimeCodec.typeSubscribe, channelName: handle.channelName))
            scheduleAckDeadline(channel: handle.channelName, attempt: beginSubscribeAttempt(handle.channelName))
        }
        // connect() refuses to run while auth-failed, so no ack deadline would surface the problem.
        if authFailed {
            handle.onSubscribeError(.subscriptionFailed(
                "Realtime authentication failed; channel \(handle.channelName) cannot subscribe"))
        }
        publishState()
    }

    private func handleUnsubscribe(_ handle: SubscriberHandle) {
        guard var handles = subscriptions[handle.channelName] else { return }
        handles.removeAll { $0 === handle }
        if handles.isEmpty {
            subscriptions.removeValue(forKey: handle.channelName)
            firstAckGeneration.removeValue(forKey: handle.channelName)
            pendingAcks.removeValue(forKey: handle.channelName)
            socket?.send(text: DashXRealtimeCodec.encodeChannelFrame(
                type: DashXRealtimeCodec.typeUnsubscribe, channelName: handle.channelName))
        } else {
            subscriptions[handle.channelName] = handles
        }
        if subscriptions.isEmpty { closeSocket() }
        publishState()
    }

    private func handleForegrounded() {
        isForeground = true
        if socket == nil && connectingSocket == nil { connect() }
        publishState()
    }

    private func handleBackgrounded() {
        isForeground = false
        closeSocket()
        publishState()
    }

    private func handleIdentityChanged(fromAuthRefresh: Bool) {
        // Any socket, connected or still connecting, carries the old token in its URL.
        authFailed = false
        credentialGeneration += 1
        if !fromAuthRefresh { authRefreshAttempted = false }
        reconnectAttempts = 0
        closeSocket()
        connect()
        publishState()
    }

    private func handleSocketOpened(generation: Int, socket opened: RealtimeSocket) {
        guard generation == connectionGeneration else {
            opened.close(code: Self.normalClosure, reason: nil)
            return
        }
        connectingSocket = nil
        socket = opened
        reconnectAttempts = 0
        // Server subscription state is per connection: every channel re-subscribes.
        for channel in subscriptions.keys.sorted() {
            opened.send(text: DashXRealtimeCodec.encodeChannelFrame(type: DashXRealtimeCodec.typeSubscribe, channelName: channel))
            scheduleAckDeadline(channel: channel, attempt: beginSubscribeAttempt(channel))
        }
        publishState()
    }

    private func handleFrameReceived(generation: Int, text: String) {
        guard generation == connectionGeneration, let frame = DashXRealtimeCodec.decode(text) else { return }
        switch frame {
        case .ping:
            socket?.send(text: DashXRealtimeCodec.encodeBareFrame(type: DashXRealtimeCodec.typePong))
        case .subscriptionSucceeded(let channel):
            pendingAcks.removeValue(forKey: channel)
            // The token was accepted for real work: a later 4401 earns a fresh refresh cycle.
            authRefreshAttempted = false
            let first = firstAckGeneration[channel]
            let isResubscribe = first.map { $0 < connectionGeneration } ?? false
            if first == nil { firstAckGeneration[channel] = connectionGeneration }
            subscriptions[channel]?.forEach { $0.onEstablished(isResubscribe) }
        case .inAppChatMessage(let message):
            subscriptions[Self.chatChannelName(conversationId: message.conversationId)]?.forEach { $0.onFrame(frame) }
        default:
            break
        }
        onAnyFrame(frame)
    }

    private func handleSocketClosed(generation: Int, code: Int, reason: String) {
        guard generation == connectionGeneration else { return }
        socket = nil
        connectingSocket = nil
        // Pending deadlines would otherwise fire during the backoff and report a network blip as a
        // rejected subscription; the reconnect re-sends under fresh attempts.
        pendingAcks.removeAll()
        if Self.isTerminalCloseCode(code) {
            authFailed = true
            DashXLog.e(tag: Self.tag, "Realtime closed with terminal code \(code) (\(reason))")
            // Only 4401 can be fixed by a fresh token, and only once per cycle.
            if code == Self.closeCodeUnauthorized && !authRefreshAttempted {
                authRefreshAttempted = true
                let credentials = credentialGeneration
                onAuthRejected { [weak self] refreshed in
                    guard let self, !refreshed else { return }
                    self.enqueue { self.handleAuthRefreshFailed(credentialGeneration: credentials) }
                }
            } else {
                failSubscribers(code: code, reason: reason)
            }
        } else {
            scheduleReconnect()
        }
        publishState()
    }

    private func handleSocketFailed(generation: Int, error: Error) {
        guard generation == connectionGeneration else { return }
        socket = nil
        connectingSocket = nil
        pendingAcks.removeAll()
        DashXLog.e(tag: Self.tag, "Realtime failure: \(error.localizedDescription)")
        scheduleReconnect()
        publishState()
    }

    private func handleAuthRefreshFailed(credentialGeneration: Int) {
        // Only while the rejection that asked for the refresh still stands.
        guard credentialGeneration == self.credentialGeneration, authFailed else { return }
        failSubscribers(code: Self.closeCodeUnauthorized, reason: "token refresh did not recover")
    }

    private func handleRetryConnect(generation: Int) {
        guard generation == connectionGeneration else { return }
        if socket == nil && connectingSocket == nil { connect() }
    }

    private func handleAckDeadline(generation: Int, channel: String, attempt: Int) {
        guard generation == connectionGeneration else { return }
        guard pendingAcks[channel] == attempt else { return }
        let timeoutMs = Int(ackTimeout * 1000)
        subscriptions[channel]?.forEach {
            $0.onSubscribeError(.subscriptionFailed("Channel \(channel) was not acknowledged within \(timeoutMs)ms"))
        }
    }

    private func handleEndSession() {
        ended = true
        closeSocket()
        subscriptions.removeAll()
        firstAckGeneration.removeAll()
        pendingAcks.removeAll()
        publishStateSink(.idle)
    }

    /// With the socket gone no ack or deadline is coming, so waiting subscribers are told now.
    private func failSubscribers(code: Int, reason: String) {
        let error = DashXClientError.subscriptionFailed("Realtime connection closed with code \(code) (\(reason))")
        subscriptions.values.forEach { handles in handles.forEach { $0.onSubscribeError(error) } }
    }

    /// Bumps the generation, so callbacks from the departing socket become stamped no-ops.
    private func closeSocket() {
        connectionGeneration += 1
        connectingSocket?.cancel()
        connectingSocket = nil
        socket?.close(code: Self.normalClosure, reason: nil)
        socket = nil
    }

    private func connect() {
        if authFailed || !isForeground || subscriptions.isEmpty { return }
        guard let url = urlProvider() else { return }

        connectionGeneration += 1
        let listener = ConnectionListener(runtime: self, generation: connectionGeneration)
        connectingSocket = socketFactory(url, listener)
        publishState()
    }

    private func beginSubscribeAttempt(_ channel: String) -> Int {
        subscribeAttemptCounter += 1
        pendingAcks[channel] = subscribeAttemptCounter
        return subscribeAttemptCounter
    }

    private func scheduleAckDeadline(channel: String, attempt: Int) {
        let generation = connectionGeneration
        queue.asyncAfter(deadline: .now() + ackTimeout) { [weak self] in
            guard let self, !self.ended else { return }
            self.handleAckDeadline(generation: generation, channel: channel, attempt: attempt)
        }
    }

    private func scheduleReconnect() {
        if authFailed || !isForeground || subscriptions.isEmpty { return }
        reconnectAttempts += 1
        let exponent = min(reconnectAttempts - 1, 5)
        let base = min(Self.initialReconnectDelay * pow(2, Double(exponent)), Self.maxReconnectDelay)
        let delay = base / 2 + Double.random(in: 0...(base / 2))
        let generation = connectionGeneration
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, !self.ended else { return }
            self.handleRetryConnect(generation: generation)
        }
    }

    private func publishState() {
        let state: DashXConnectionState
        if authFailed {
            state = .authenticationFailed(cause: nil)
        } else if socket != nil {
            state = .connected
        } else if connectingSocket != nil {
            state = .connecting
        } else if !isForeground && !subscriptions.isEmpty {
            state = .suspended
        } else if !subscriptions.isEmpty && isForeground && urlProvider() != nil {
            state = .connecting
        } else {
            state = .idle
        }
        publishStateSink(state)
    }

    private final class ConnectionListener: RealtimeSocketListener {
        private weak var runtime: RealtimeRuntime?
        private let generation: Int

        init(runtime: RealtimeRuntime, generation: Int) {
            self.runtime = runtime
            self.generation = generation
        }

        func socketDidOpen(_ socket: RealtimeSocket) {
            runtime?.enqueue { [generation] in self.runtime?.handleSocketOpened(generation: generation, socket: socket) }
        }

        func socket(_ socket: RealtimeSocket, didReceiveText text: String) {
            runtime?.enqueue { [generation] in self.runtime?.handleFrameReceived(generation: generation, text: text) }
        }

        func socket(_ socket: RealtimeSocket, didCloseWithCode code: Int, reason: String) {
            runtime?.enqueue { [generation] in self.runtime?.handleSocketClosed(generation: generation, code: code, reason: reason) }
        }

        func socket(_ socket: RealtimeSocket, didFailWithError error: Error) {
            runtime?.enqueue { [generation] in self.runtime?.handleSocketFailed(generation: generation, error: error) }
        }
    }
}

/// Delivers exactly one terminal event. A server close observed through the receive loop is
/// reported with its close code, never as a generic failure, so 44xx rejections stay terminal.
final class URLSessionRealtimeSocket: NSObject, RealtimeSocket, URLSessionWebSocketDelegate {
    private var session: URLSession!
    private var task: URLSessionWebSocketTask!
    private weak var listener: RealtimeSocketListener?
    private let lock = NSLock()
    private var terminated = false
    private var pingTimer: DispatchSourceTimer?
    private let pingInterval: TimeInterval
    private let pingQueue = DispatchQueue(label: "com.dashx.ios.realtime.ping")

    init(url: URL, listener: RealtimeSocketListener, pingInterval: TimeInterval) {
        self.listener = listener
        self.pingInterval = pingInterval
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session.webSocketTask(with: url)
        task.resume()
        receiveNext()
    }

    func send(text: String) {
        task.send(.string(text)) { [weak self] error in
            if let error { self?.terminate(.failed(error)) }
        }
    }

    func close(code: Int, reason: String?) {
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code) ?? .normalClosure
        task.cancel(with: closeCode, reason: reason?.data(using: .utf8))
        session.finishTasksAndInvalidate()
    }

    func cancel() {
        task.cancel()
        _ = markTerminated()
        session.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        listener?.socketDidOpen(self)
        startPinging()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        terminate(.closed(code: closeCode.rawValue, reason: reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        reportReceiveFailure(error)
    }

    private enum Terminal {
        case closed(code: Int, reason: String)
        case failed(Error)
    }

    private func receiveNext() {
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(.string(let text)):
                self.listener?.socket(self, didReceiveText: text)
                self.receiveNext()
            case .success(.data(let bytes)):
                if let text = String(data: bytes, encoding: .utf8) {
                    self.listener?.socket(self, didReceiveText: text)
                }
                self.receiveNext()
            case .success:
                self.receiveNext()
            case .failure(let error):
                self.reportReceiveFailure(error)
            }
        }
    }

    /// The close frame, when one arrived, outranks the transport error the receive loop surfaces.
    private func reportReceiveFailure(_ error: Error) {
        let code = task.closeCode.rawValue
        if code != 0 {
            let reason = task.closeReason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            terminate(.closed(code: code, reason: reason))
        } else {
            terminate(.failed(error))
        }
    }

    private func markTerminated() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if terminated { return false }
        terminated = true
        pingTimer?.cancel()
        pingTimer = nil
        return true
    }

    private func terminate(_ terminal: Terminal) {
        guard markTerminated() else { return }
        switch terminal {
        case .closed(let code, let reason):
            listener?.socket(self, didCloseWithCode: code, reason: reason)
        case .failed(let error):
            listener?.socket(self, didFailWithError: error)
        }
        session.invalidateAndCancel()
    }

    /// Protocol-level keepalive, independent of the app-level PING/PONG.
    private func startPinging() {
        lock.lock()
        defer { lock.unlock() }
        guard !terminated, pingTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: pingQueue)
        timer.schedule(deadline: .now() + pingInterval, repeating: pingInterval)
        timer.setEventHandler { [weak self] in
            self?.task.sendPing { error in
                if let error { self?.terminate(.failed(error)) }
            }
        }
        timer.resume()
        pingTimer = timer
    }
}
