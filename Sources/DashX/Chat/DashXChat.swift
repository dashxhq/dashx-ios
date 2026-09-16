import Foundation

public extension DashXClient {
    /// Entry point for in-app chat. The chat identity id is issued by the host's server together
    /// with the conversation id.
    func chat(chatIdentityId: String) -> DashXChat {
        DashXChat(chatIdentityId: chatIdentityId)
    }
}

/// Identity-scoped chat surface. Conversations are created server-side; this API consumes the
/// resulting `(conversationId, chatIdentityId)` pair.
public final class DashXChat {
    public let chatIdentityId: String

    init(chatIdentityId: String) {
        self.chatIdentityId = chatIdentityId
    }

    public func openConversation(_ conversationId: String) -> DashXConversationLease {
        ChatCoordinator.shared.open(ChatSessionKey(chatIdentityId: chatIdentityId, conversationId: conversationId))
    }

    public func fetchConversations(
        limit: Int? = nil,
        page: Int? = nil,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil,
        completion: @escaping (Result<[DashXChatConversationSummary], Error>) -> Void
    ) {
        DashXClient.instance.fetchInAppChatConversations(
            identityId: chatIdentityId, limit: limit, page: page, statuses: statuses, properties: properties, completion: completion
        )
    }

    public func fetchConversation(
        _ conversationId: String,
        completion: @escaping (Result<DashXChatConversationSummary, Error>) -> Void
    ) {
        DashXClient.instance.fetchInAppChatConversation(identityId: chatIdentityId, conversationId: conversationId, completion: completion)
    }

    public func summarizeConversations(
        statuses: [String]? = nil,
        properties: [String: Any]? = nil,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        DashXClient.instance.summarizeInAppChatConversations(
            identityId: chatIdentityId, statuses: statuses, properties: properties, completion: completion
        )
    }

    /// On-demand count; the SDK does not push updates to it.
    public func summarizeUnread(completion: @escaping (Result<Int, Error>) -> Void) {
        DashXClient.instance.summarizeInAppChatUnread(identityId: chatIdentityId, completion: completion)
    }

    public func resolveConversation(
        _ conversationId: String,
        completion: @escaping (Result<DashXChatConversationSummary, Error>) -> Void
    ) {
        DashXClient.instance.resolveInAppChatConversation(identityId: chatIdentityId, conversationId: conversationId, completion: completion)
    }

    // MARK: async/await overloads

    public func fetchConversations(
        limit: Int? = nil,
        page: Int? = nil,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil
    ) async throws -> [DashXChatConversationSummary] {
        try await DashXClient.instance.fetchInAppChatConversations(
            identityId: chatIdentityId, limit: limit, page: page, statuses: statuses, properties: properties
        )
    }

    public func fetchConversation(_ conversationId: String) async throws -> DashXChatConversationSummary {
        try await DashXClient.instance.fetchInAppChatConversation(identityId: chatIdentityId, conversationId: conversationId)
    }

    public func summarizeConversations(statuses: [String]? = nil, properties: [String: Any]? = nil) async throws -> Int {
        try await DashXClient.instance.summarizeInAppChatConversations(identityId: chatIdentityId, statuses: statuses, properties: properties)
    }

    public func summarizeUnread() async throws -> Int {
        try await DashXClient.instance.summarizeInAppChatUnread(identityId: chatIdentityId)
    }

    public func resolveConversation(_ conversationId: String) async throws -> DashXChatConversationSummary {
        try await DashXClient.instance.resolveInAppChatConversation(identityId: chatIdentityId, conversationId: conversationId)
    }
}

/// A caller's handle on one conversation. Every `openConversation` returns a new lease; the
/// subscription and history are shared per `(identity, conversation)` and torn down when the last
/// lease closes.
public protocol DashXConversationLease: AnyObject {
    var conversationId: String { get }

    var state: DashXConversationState { get }

    /// Also delivers the current state immediately on the main queue. Listeners are lease-owned:
    /// `close()` drops them.
    func addStateListener(_ listener: DashXConversationStateListener)
    func removeStateListener(_ listener: DashXConversationStateListener)

    /// Fires when the session ends underneath this lease (identity switch or reset).
    func setOnTerminated(_ callback: ((DashXSubscriptionEnd) -> Void)?)

    /// Sends a visitor message and merges the committed row into `state`. Returns the client message
    /// id synchronously: the idempotency key a retry must reuse via the raw operation, reported back
    /// as `DashXChatMessage.clientMessageId`. `content` is `{"text": "<1–4096 characters>"}`.
    @discardableResult
    func sendMessage(content: [String: Any], completion: @escaping (Result<DashXChatMessage, Error>) -> Void) -> String

    /// Prepends older history; a failure leaves the current list intact.
    func loadPreviousPage(onError: ((Error) -> Void)?)

    /// Declares whether this conversation is on screen: drives read-marking and push suppression.
    func setVisible(_ visible: Bool)

    func close()
}

public extension DashXConversationLease {
    func loadPreviousPage() {
        loadPreviousPage(onError: nil)
    }
}

final class ChatCoordinator {
    static let shared = ChatCoordinator()

    private let lock = NSLock()
    private var sessions: [ChatSessionKey: ConversationSession] = [:]

    func open(_ key: ChatSessionKey) -> DashXConversationLease {
        while true {
            lock.lock()
            let session: ConversationSession
            if let existing = sessions[key] {
                session = existing
            } else {
                session = ConversationSession(key: key)
                sessions[key] = session
            }
            lock.unlock()
            if let lease = session.newLease() { return lease }
            // Lost a race with the session's teardown; the loop builds a new one.
        }
    }

    func remove(_ key: ChatSessionKey, _ session: ConversationSession) {
        lock.lock()
        defer { lock.unlock() }
        if sessions[key] === session { sessions.removeValue(forKey: key) }
    }

    func closeAllSessions() {
        lock.lock()
        let open = Array(sessions.values)
        sessions.removeAll()
        lock.unlock()
        open.forEach { $0.endSession() }
    }

    func onIdentityAvailable() {
        DashXClient.instance.realtimeRuntime?.onIdentityChanged()
    }

    func onAppForegrounded() {
        lock.lock()
        let open = Array(sessions.values)
        lock.unlock()
        open.forEach { $0.onAppForegrounded() }
    }

    /// Reserved for unread refresh hooks.
    func onGlobalFrame(_ frame: DashXRealtimeMessage) {}
}

/// Seam so the synchronizer is testable without a socket or transport.
protocol ChatSessionBackend {
    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription
    func summarizeMessages(conversationId: String) async throws -> Int
    func fetchPage(conversationId: String, limit: Int, page: Int) async throws -> [DashXChatMessage]
    func fetchAfter(conversationId: String, limit: Int, afterMessageId: String) async throws -> [DashXChatMessage]
    func send(
        identityId: String,
        conversationId: String,
        content: [String: Any],
        clientMessageId: String,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    )
    func markRead(
        identityId: String,
        conversationId: String,
        lastMessageId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
    func setConversationVisible(conversationId: String, visible: Bool)
    func dismissConversationNotifications(conversationId: String)
    /// Read marking requires a foregrounded process, not just a visible lease.
    var isAppForeground: Bool { get }
}

struct DashXChatSessionBackend: ChatSessionBackend {
    private var client: DashXClient { DashXClient.instance }

    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription {
        client.requireRealtimeRuntime().subscribe(handle)
    }

    func summarizeMessages(conversationId: String) async throws -> Int {
        try await client.summarizeInAppChatMessages(conversationId: conversationId)
    }

    func fetchPage(conversationId: String, limit: Int, page: Int) async throws -> [DashXChatMessage] {
        try await client.fetchInAppChatMessages(conversationId: conversationId, limit: limit, page: page, afterMessageId: nil)
    }

    func fetchAfter(conversationId: String, limit: Int, afterMessageId: String) async throws -> [DashXChatMessage] {
        try await client.fetchInAppChatMessages(conversationId: conversationId, limit: limit, page: nil, afterMessageId: afterMessageId)
    }

    func send(
        identityId: String,
        conversationId: String,
        content: [String: Any],
        clientMessageId: String,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    ) {
        client.sendInAppChatMessage(
            conversationId: conversationId, identityId: identityId, content: content, clientMessageId: clientMessageId, completion: completion
        )
    }

    func markRead(
        identityId: String,
        conversationId: String,
        lastMessageId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        client.markInAppChatConversationRead(
            identityId: identityId, conversationId: conversationId, lastMessageId: lastMessageId, completion: completion
        )
    }

    func setConversationVisible(conversationId: String, visible: Bool) {
        client.pushRuntime.setConversationVisible(conversationId, visible: visible)
    }

    func dismissConversationNotifications(conversationId: String) {
        DashXPush.dismissConversationNotifications(conversationId: conversationId)
    }

    var isAppForeground: Bool { client.pushRuntime.get().isForeground }
}

/// Shared state for one `(identity, conversation)`: subscription, reconciliation buffer, message
/// list and read marking. First open loads the newest page; a reconnect fetches forward from the
/// last confirmed message. Every mutation runs on `lane`; a cycle's network awaits release the lane,
/// and frames arriving meanwhile go to the buffer.
final class ConversationSession {
    static let pageSize = 50
    private static let bufferLimit = 500
    private static let markDebounce: TimeInterval = 0.4
    private static let maxInitialSyncRetries = 3
    private static let cursorRetryBase: TimeInterval = 1
    private static let cursorRetryMax: TimeInterval = 30
    private static let tag = "DashXChat"

    let key: ChatSessionKey
    fileprivate let backend: ChatSessionBackend
    fileprivate let lane = DispatchQueue(label: "com.dashx.ios.chat.session")
    private let callbackQueue: DispatchQueue

    private let lock = NSLock()
    private var currentState: DashXConversationState = .loading
    private var leases: [Lease] = []
    private var ended = false
    private var subscription: DashXRealtimeSubscription?

    // Confined to `lane`.
    private var buffer: [DashXChatMessage] = []
    private var buffering = true
    private var bufferOverflowed = false
    private var messages: [DashXChatMessage] = []
    private var snapshotDone = false
    private var syncing = false
    private var resyncPending = false
    private var rebuildUsed = false
    /// Consecutive transient sync failures; a completed cycle or a fresh acknowledgement resets it.
    private var syncAttempts = 0
    private var oldestFetchedPage = Int.max
    /// Newest unconfirmed tail id a resync was already requested for.
    private var resyncRequestedFor: String?
    /// Server-confirmed reconnect cursor, advanced only by fetch results. Frames can arrive out of
    /// order, and a frame-advanced cursor would leap past a lost sibling no walk could return.
    private var lastKnownMessageId: String?

    private var markedMessageId: String?
    private var markInFlight = false
    private var pendingMarkToken = 0

    init(key: ChatSessionKey, backend: ChatSessionBackend = DashXChatSessionBackend(), callbackQueue: DispatchQueue = .main) {
        self.key = key
        self.backend = backend
        self.callbackQueue = callbackQueue
    }

    var state: DashXConversationState {
        lock.lock()
        defer { lock.unlock() }
        return currentState
    }

    private var isEnded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return ended
    }

    func newLease() -> DashXConversationLease? {
        lock.lock()
        defer { lock.unlock() }
        if ended { return nil }
        let lease = Lease(session: self)
        leases.append(lease)
        if subscription == nil {
            let handle = SubscriberHandle(
                channelName: RealtimeRuntime.chatChannelName(conversationId: key.conversationId),
                onFrame: { [weak self] frame in self?.onFrame(frame) },
                onEstablished: { [weak self] isResubscribe in self?.onEstablished(isResubscribe) },
                onSubscribeError: { [weak self] error in self?.onSubscribeError(error) }
            )
            subscription = backend.subscribe(handle)
        }
        return lease
    }

    private func onFrame(_ frame: DashXRealtimeMessage) {
        guard case .inAppChatMessage(let message) = frame else { return }
        let chatMessage = DashXChatMessage(frame: message)
        lane.async { self.mergeLive(chatMessage) }
    }

    private func onEstablished(_ isResubscribe: Bool) {
        DashXLog.d(tag: Self.tag, "Channel acknowledged for \(key.conversationId) (isResubscribe=\(isResubscribe))")
        lane.async {
            self.syncAttempts = 0
            if self.syncing {
                // The running fetch may predate the gap; re-run once it completes.
                self.resyncPending = true
                return
            }
            self.startSync()
        }
    }

    /// Only a conversation with nothing to show surfaces this; an established snapshot stays on
    /// screen and a late acknowledgement still reconciles.
    private func onSubscribeError(_ error: DashXClientError) {
        lane.async {
            if self.snapshotDone {
                DashXLog.e(tag: Self.tag, "Subscription problem on \(self.key.conversationId) after sync: \(error.localizedDescription)")
                return
            }
            self.publishState(.error(error))
        }
    }

    private func mergeLive(_ message: DashXChatMessage) {
        if buffering {
            if buffer.count >= Self.bufferLimit { bufferOverflowed = true } else { buffer.append(message) }
            return
        }
        applyMerge([message])
        maybeMarkRead()
    }

    /// Starts buffering synchronously: a frame queued on the lane right behind the acknowledgement
    /// must land in the buffer, not in the displayed list.
    private func startSync() {
        syncing = true
        rebuildUsed = false
        resyncPending = false
        startBuffering()
        Task { await self.runSync() }
    }

    private func runSync() async {
        do {
            var bufferingStarted = true
            repeat {
                let useSnapshot: Bool = await onLane {
                    self.resyncPending = false
                    return !self.snapshotDone || self.lastKnownMessageId == nil
                }
                if useSnapshot {
                    try await snapshotAndReplace(bufferingStarted: bufferingStarted)
                } else {
                    try await cursorReconcile(bufferingStarted: bufferingStarted)
                }
                bufferingStarted = false
            } while await onLane({ self.resyncPending })
            await onLane {
                self.syncAttempts = 0
                self.syncing = false
            }
        } catch {
            let failure = DashXClientError.wrap(error)
            await onLane {
                self.syncing = false
                if self.keepsSnapshot(failure) && (self.snapshotDone || self.syncAttempts < Self.maxInitialSyncRetries) {
                    // The socket may stay connected, so no reconnect would re-run this.
                    self.syncAttempts += 1
                    let attempt = self.syncAttempts
                    let delay = self.cursorRetryDelay(attempt)
                    DashXLog.e(tag: Self.tag, "Sync failed for \(self.key.conversationId) (attempt \(attempt), retrying in \(Int(delay * 1000))ms): \(failure.localizedDescription)")
                    self.lane.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self, !self.syncing, self.syncAttempts == attempt, !self.isEnded else { return }
                        self.startSync()
                    }
                } else {
                    self.publishState(.error(failure))
                }
                // Buffering stays on: a partial live list must not follow the error.
            }
        }
    }

    /// Failures that leave a loaded conversation on screen instead of replacing it with `.error`.
    private func keepsSnapshot(_ error: DashXClientError) -> Bool {
        switch error {
        case .networkError:
            return true
        case .graphQLErrors(let errors):
            switch errors.code {
            case nil, DashXGraphQLErrors.unauthorized, DashXGraphQLErrors.internalServerError:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    private func snapshotAndReplace(bufferingStarted: Bool = false) async throws {
        var bufferingStarted = bufferingStarted
        while true {
            if !bufferingStarted { await onLane { self.startBuffering() } }
            bufferingStarted = false
            let count = try await backend.summarizeMessages(conversationId: key.conversationId)
            let lastPage = max(1, (count + Self.pageSize - 1) / Self.pageSize)
            let candidate = try await backend.fetchPage(conversationId: key.conversationId, limit: Self.pageSize, page: lastPage)
                .sorted(by: DashXChatMessage.order)
            let done: Bool = await onLane {
                let (bufferSnapshot, overflowed) = self.drainBufferAndResumeLive()
                if overflowed { return false }
                self.messages = self.mergeInto(candidate, bufferSnapshot)
                self.snapshotDone = true
                self.oldestFetchedPage = lastPage
                // From the fetched candidate only: a buffered frame is not server-confirmed.
                self.lastKnownMessageId = candidate.last?.id
                self.publishReady()
                self.maybeMarkRead()
                return true
            }
            if done { return }
        }
    }

    private func cursorReconcile(bufferingStarted: Bool = false) async throws {
        var bufferingStarted = bufferingStarted
        while true {
            let skipBuffering = bufferingStarted
            bufferingStarted = false
            let startCursor: String? = await onLane {
                if !skipBuffering { self.startBuffering() }
                return self.lastKnownMessageId
            }
            guard var cursor = startCursor else {
                try await snapshotAndReplace()
                return
            }
            var fetched: [DashXChatMessage] = []
            do {
                while true {
                    let rows = try await backend.fetchAfter(conversationId: key.conversationId, limit: Self.pageSize, afterMessageId: cursor)
                    if rows.isEmpty { break }
                    fetched += rows
                    cursor = rows[rows.count - 1].id
                    if rows.count < Self.pageSize { break }
                }
            } catch {
                // UNPROCESSABLE_ENTITY means the cursor itself was rejected: rebuild once rather than
                // merge, or the deleted id survives as the cursor. The incomplete walk is discarded
                // whole either way, or the cursor would advance past the unfetched gap.
                let cursorRejected = DashXClientError.wrap(error).graphQLCode == DashXGraphQLErrors.unprocessableEntity
                let rebuild: Bool = await onLane {
                    if !cursorRejected || self.rebuildUsed { return false }
                    self.rebuildUsed = true
                    return true
                }
                if !rebuild { throw error }
                try await snapshotAndReplace()
                return
            }
            let done: Bool = await onLane {
                let (bufferSnapshot, overflowed) = self.drainBufferAndResumeLive()
                if overflowed { return false }
                self.applyMerge(fetched + bufferSnapshot)
                // Only the walk's last fetched row is server-confirmed.
                if let last = fetched.last { self.lastKnownMessageId = last.id }
                self.maybeMarkRead()
                return true
            }
            if done { return }
        }
    }

    private func onLane<T>(_ body: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            lane.async { continuation.resume(returning: body()) }
        }
    }

    private func cursorRetryDelay(_ attempt: Int) -> TimeInterval {
        min(Self.cursorRetryBase * pow(2, Double(min(attempt - 1, 5))), Self.cursorRetryMax)
    }

    private func startBuffering() {
        buffering = true
        buffer.removeAll()
        bufferOverflowed = false
    }

    private func drainBufferAndResumeLive() -> ([DashXChatMessage], Bool) {
        let copy = buffer
        let overflowed = bufferOverflowed
        buffer.removeAll()
        bufferOverflowed = false
        if !overflowed { buffering = false }
        return (copy, overflowed)
    }

    /// Display-only: never touches `lastKnownMessageId`.
    private func applyMerge(_ additions: [DashXChatMessage]) {
        if !additions.isEmpty { messages = mergeInto(messages, additions) }
        publishReady()
    }

    private func mergeInto(_ base: [DashXChatMessage], _ additions: [DashXChatMessage]) -> [DashXChatMessage] {
        if additions.isEmpty { return base }
        var byId: [String: DashXChatMessage] = [:]
        byId.reserveCapacity(base.count + additions.count)
        base.forEach { byId[$0.id] = $0 }
        additions.forEach { byId[$0.id] = $0 }
        return byId.values.sorted(by: DashXChatMessage.order)
    }

    private func publishReady() {
        let next = DashXConversationState.ready(messages: messages, hasOlderMessages: oldestFetchedPage > 1)
        if state == next { return }
        publishState(next)
    }

    private func publishState(_ newState: DashXConversationState) {
        lock.lock()
        if ended {
            lock.unlock()
            return
        }
        currentState = newState
        let recipients = leases
        lock.unlock()
        recipients.forEach { $0.notifyStateListeners(newState) }
    }

    fileprivate func loadPreviousPageInternal(onError: ((Error) -> Void)?) {
        lane.async {
            let page = self.oldestFetchedPage - 1
            guard self.snapshotDone, page >= 1 else { return }
            Task {
                do {
                    let rows = try await self.backend.fetchPage(conversationId: self.key.conversationId, limit: Self.pageSize, page: page)
                    await self.onLane {
                        self.oldestFetchedPage = page
                        self.applyMerge(rows)
                    }
                } catch {
                    guard let onError else { return }
                    let failure = DashXClientError.wrap(error)
                    self.callbackQueue.async { onError(failure) }
                }
            }
        }
    }

    private func anyLeaseVisible() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return leases.contains { $0.visibleNow }
    }

    private func canMarkRead() -> Bool {
        anyLeaseVisible() && backend.isAppForeground
    }

    private func maybeMarkRead() {
        guard canMarkRead(), let newest = messages.last?.id, newest != markedMessageId else { return }
        // Marking a live frame that overtook a lost sibling would mark the unseen sibling read, so
        // an unconfirmed tail reconciles first. One resync per tail id, or a row the server never
        // returns would spin the lane.
        if newest != lastKnownMessageId {
            if resyncRequestedFor != newest {
                resyncRequestedFor = newest
                requestResync()
            }
            return
        }
        pendingMarkToken += 1
        let token = pendingMarkToken
        lane.asyncAfter(deadline: .now() + Self.markDebounce) { [weak self] in
            guard let self, self.pendingMarkToken == token, self.canMarkRead() else { return }
            self.markNow(newest)
        }
    }

    private func requestResync() {
        if syncing {
            resyncPending = true
            return
        }
        startSync()
    }

    private func markNow(_ messageId: String) {
        guard messageId != markedMessageId, !markInFlight else { return }
        markInFlight = true
        backend.markRead(identityId: key.chatIdentityId, conversationId: key.conversationId, lastMessageId: messageId) { [weak self] result in
            guard let self else { return }
            self.lane.async {
                self.markInFlight = false
                switch result {
                case .success(let success):
                    if success { self.markedMessageId = messageId }
                    self.maybeMarkRead()
                case .failure(let error):
                    // Left unmarked: the next message retries.
                    DashXLog.e(tag: Self.tag, "Failed to mark \(self.key.conversationId) read: \(error.localizedDescription)")
                }
            }
        }
    }

    func onAppForegrounded() {
        lane.async { self.maybeMarkRead() }
    }

    func endSession() {
        lock.lock()
        if ended {
            lock.unlock()
            return
        }
        ended = true
        let toNotify = leases
        leases.removeAll()
        let departing = subscription
        subscription = nil
        let terminal = DashXConversationState.error(.sessionEnded)
        currentState = terminal
        lock.unlock()

        departing?.unsubscribe()
        backend.setConversationVisible(conversationId: key.conversationId, visible: false)
        toNotify.forEach { lease in
            lease.notifyStateListeners(terminal)
            if let callback = lease.terminatedCallback {
                callbackQueue.async { callback(.sessionEnded) }
            }
        }
        ChatCoordinator.shared.remove(key, self)
    }

    fileprivate func closeLease(_ lease: Lease) {
        lock.lock()
        guard let index = leases.firstIndex(where: { $0 === lease }) else {
            lock.unlock()
            return
        }
        leases.remove(at: index)
        var clearVisibility = false
        if lease.visibleNow {
            lease.visibleNow = false
            clearVisibility = !leases.contains { $0.visibleNow }
        }
        let teardown = leases.isEmpty && !ended
        if teardown { ended = true }
        let departing = teardown ? subscription : nil
        if teardown { subscription = nil }
        lock.unlock()

        if clearVisibility { backend.setConversationVisible(conversationId: key.conversationId, visible: false) }
        if teardown {
            departing?.unsubscribe()
            ChatCoordinator.shared.remove(key, self)
        }
    }

    fileprivate func setLeaseVisible(_ lease: Lease, _ visible: Bool) {
        lock.lock()
        lease.visibleNow = visible
        let anyVisible = leases.contains { $0.visibleNow }
        lock.unlock()
        backend.setConversationVisible(conversationId: key.conversationId, visible: anyVisible)
        if visible {
            backend.dismissConversationNotifications(conversationId: key.conversationId)
            lane.async { self.maybeMarkRead() }
        }
    }

    fileprivate func deliver(_ block: @escaping () -> Void) {
        callbackQueue.async(execute: block)
    }

    fileprivate final class Lease: DashXConversationLease {
        private let session: ConversationSession
        /// Guarded by the session's lock.
        var visibleNow = false
        private let lock = NSLock()
        private var closed = false
        private var stateListeners: [DashXConversationStateListener] = []
        private var _terminatedCallback: ((DashXSubscriptionEnd) -> Void)?

        init(session: ConversationSession) {
            self.session = session
        }

        var terminatedCallback: ((DashXSubscriptionEnd) -> Void)? {
            lock.lock()
            defer { lock.unlock() }
            return _terminatedCallback
        }

        var conversationId: String { session.key.conversationId }

        var state: DashXConversationState { session.state }

        func notifyStateListeners(_ state: DashXConversationState) {
            lock.lock()
            let listeners = stateListeners
            lock.unlock()
            listeners.forEach { listener in
                session.deliver { listener.onConversationStateChanged(state) }
            }
        }

        func addStateListener(_ listener: DashXConversationStateListener) {
            lock.lock()
            stateListeners.append(listener)
            lock.unlock()
            // Replay so a lease opened into a loaded conversation renders now; the state is read at
            // delivery time.
            let session = self.session
            session.deliver { listener.onConversationStateChanged(session.state) }
        }

        func removeStateListener(_ listener: DashXConversationStateListener) {
            lock.lock()
            defer { lock.unlock() }
            stateListeners.removeAll { $0 === listener }
        }

        func setOnTerminated(_ callback: ((DashXSubscriptionEnd) -> Void)?) {
            lock.lock()
            defer { lock.unlock() }
            _terminatedCallback = callback
        }

        @discardableResult
        func sendMessage(content: [String: Any], completion: @escaping (Result<DashXChatMessage, Error>) -> Void) -> String {
            let clientMessageId = UUID().uuidString.lowercased()
            let session = self.session
            session.backend.send(
                identityId: session.key.chatIdentityId,
                conversationId: session.key.conversationId,
                content: content,
                clientMessageId: clientMessageId
            ) { result in
                // The frame is missed while the socket reconnects, and a retry of a committed send
                // gets no frame at all; the merge dedupes by id.
                if case .success(let message) = result {
                    session.lane.async { session.mergeLive(message) }
                }
                completion(result)
            }
            return clientMessageId
        }

        func loadPreviousPage(onError: ((Error) -> Void)?) {
            session.loadPreviousPageInternal(onError: onError)
        }

        func setVisible(_ visible: Bool) {
            lock.lock()
            let isClosed = closed
            lock.unlock()
            if isClosed { return }
            session.setLeaseVisible(self, visible)
        }

        func close() {
            lock.lock()
            if closed {
                lock.unlock()
                return
            }
            closed = true
            stateListeners.removeAll()
            lock.unlock()
            session.closeLease(self)
        }
    }
}

extension DashXClientError {
    static func wrap(_ error: Error) -> DashXClientError {
        (error as? DashXClientError) ?? .networkError(underlying: error)
    }

    var graphQLCode: String? {
        if case .graphQLErrors(let errors) = self { return errors.code }
        return nil
    }
}
