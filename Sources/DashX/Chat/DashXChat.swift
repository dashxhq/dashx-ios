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
    /// as `DashXChatMessage.clientMessageId`. `content` is `{"text": "<1–4096 characters>"}`. After
    /// `close()`, or once the session has ended, nothing is sent and the completion receives
    /// `.sessionEnded`.
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
            var stale: ConversationSession?
            if let existing = sessions[key], existing.identityGeneration == DashXClient.instance.currentSessionGeneration {
                session = existing
            } else {
                // A session from an ended identity may still await its cleanup, which looks it up
                // here: once replaced, it is ended now instead.
                stale = sessions[key]
                session = ConversationSession(key: key)
                sessions[key] = session
            }
            lock.unlock()
            stale?.endSession()
            if let lease = session.newLease() { return lease }
            // Lost a race with the session's teardown; the loop builds a new one.
        }
    }

    func remove(_ key: ChatSessionKey, _ session: ConversationSession) {
        lock.lock()
        defer { lock.unlock() }
        if sessions[key] === session { sessions.removeValue(forKey: key) }
    }

    /// Ends only the sessions opened under `generation`; a later identity's stay open.
    func closeSessions(openedUnder generation: Int) {
        detachSessions(openedUnder: generation)()
    }

    /// Ends the sessions opened under `generation` without telling their leases yet; the returned
    /// closure does. An identity change detaches before it commits and notifies after, so a lease
    /// reopened from a termination callback is opened under the identity that follows.
    func detachSessions(openedUnder generation: Int) -> () -> Void {
        lock.lock()
        let ending = sessions.values.filter { $0.identityGeneration == generation }
        ending.forEach { sessions.removeValue(forKey: $0.key) }
        lock.unlock()
        let notifications = ending.compactMap { $0.detach() }
        return { notifications.forEach { $0() } }
    }

    func onAppForegrounded() {
        lock.lock()
        let open = Array(sessions.values)
        lock.unlock()
        open.forEach { $0.onAppForegrounded() }
    }
}

/// Seam so the synchronizer is testable without a socket or transport.
protocol ChatSessionBackend {
    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription
    /// A new lease reused an existing subscription; a credential failure stranding it is retried.
    func subscriberReturned()
    func summarizeMessages(conversationId: String) async throws -> Int
    func fetchPage(conversationId: String, limit: Int, page: Int) async throws -> [DashXChatMessage]
    func fetchAfter(conversationId: String, limit: Int, afterMessageId: String) async throws -> [DashXChatMessage]
    /// `shouldDispatch` is asked right before the request leaves, which may be after a token load.
    func send(
        identityId: String,
        conversationId: String,
        content: [String: Any],
        clientMessageId: String,
        shouldDispatch: @escaping () -> Bool,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    )
    func markRead(
        identityId: String,
        conversationId: String,
        lastMessageId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
    /// `owner` is the session declaring it; a conversation stays visible while any owner shows it.
    /// Called with the session's lock held, so it must not call back into the session.
    func setConversationVisible(conversationId: String, owner: ObjectIdentifier, visible: Bool)
    func dismissConversationNotifications(conversationId: String)
    /// Read marking requires a foregrounded process, not just a visible lease.
    var isAppForeground: Bool { get }
    /// The identity session current now; a session opened under another one must not send.
    var sessionGeneration: Int { get }
}

extension ChatSessionBackend {
    func subscriberReturned() {}
}

struct DashXChatSessionBackend: ChatSessionBackend {
    private var client: DashXClient { DashXClient.instance }

    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription {
        client.requireRealtimeRuntime().subscribe(handle)
    }

    func subscriberReturned() {
        client.realtimeRuntime?.onSubscriberReturned()
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
        shouldDispatch: @escaping () -> Bool,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    ) {
        client.sendInAppChatMessage(
            conversationId: conversationId,
            identityId: identityId,
            content: content,
            clientMessageId: clientMessageId,
            shouldDispatch: shouldDispatch,
            completion: completion
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

    func setConversationVisible(conversationId: String, owner: ObjectIdentifier, visible: Bool) {
        client.pushRuntime.setConversationVisible(conversationId, owner: owner, visible: visible)
    }

    func dismissConversationNotifications(conversationId: String) {
        DashXPush.dismissConversationNotifications(conversationId: conversationId)
    }

    var isAppForeground: Bool { client.pushRuntime.get().isForeground }

    var sessionGeneration: Int { client.currentSessionGeneration }
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
    /// The identity session this conversation was opened under.
    let identityGeneration: Int
    fileprivate let lane = DispatchQueue(label: "com.dashx.ios.chat.session")
    private let callbackQueue: DispatchQueue

    private let lock = NSLock()
    private var currentState: DashXConversationState = .loading
    private var leases: [Lease] = []
    private var ended = false
    /// Between a detach and its notification: `.sessionEnded` reports held until the leases hear.
    private var heldEndedReports: [() -> Void]?
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
    /// The initial history load gave up and published `.error`; no sync is running. A reused lease
    /// retries it, since a healthy socket sends no new acknowledgement to do so.
    private var initialSyncFailed = false
    private var oldestFetchedPage = Int.max
    /// One older-page fetch at a time: a slow duplicate finishing late would move
    /// `oldestFetchedPage` back to a newer page.
    private var loadingPreviousPage = false
    /// Advanced each time a snapshot replaces the list: an older page fetched against a replaced
    /// snapshot would leave a gap between it and the new pages.
    private var historyGeneration = 0
    /// Newest unconfirmed tail id a resync was already requested for.
    private var resyncRequestedFor: String?
    /// Server-confirmed reconnect cursor, advanced only by fetch results. Frames can arrive out of
    /// order, and a frame-advanced cursor would leap past a lost sibling no walk could return.
    private var lastKnownMessageId: String?

    private var markedMessageId: String?
    private var markInFlight = false
    private var pendingMarkToken = 0

    /// The agent reply being streamed, at most one: a later turn or a retried run replaces it.
    private var replyStream: ReplyStreamAccumulator?
    /// The newest run already settled, by its stored reply or an `END` that stored none; its late
    /// frames, and any older run's, are ignored.
    private var settledStreamRun: ReplyStreamRun?
    /// The newest run any frame has named. Kept apart from `replyStream`, which a reconnect
    /// clears: a superseded run's delayed frames must not come back afterwards.
    private var newestStreamRun: ReplyStreamRun?
    /// Pending idle checks of unfinished runs. A frame of the same turn reschedules or cancels its
    /// turn's check and an `END` cancels its run's; a later turn's frames leave it to finish.
    private var idleChecks: [ReplyStreamRun: DispatchWorkItem] = [:]
    private let streamTimeouts: ReplyStreamTimeouts

    init(
        key: ChatSessionKey,
        backend: ChatSessionBackend = DashXChatSessionBackend(),
        callbackQueue: DispatchQueue = .main,
        streamTimeouts: ReplyStreamTimeouts = ReplyStreamTimeouts()
    ) {
        self.key = key
        self.backend = backend
        self.callbackQueue = callbackQueue
        self.streamTimeouts = streamTimeouts
        self.identityGeneration = backend.sessionGeneration
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

    /// Not ended, and the identity session it was opened under is still the current one.
    fileprivate var canSend: Bool {
        !isEnded && backend.sessionGeneration == identityGeneration
    }

    func newLease() -> DashXConversationLease? {
        lock.lock()
        if ended {
            lock.unlock()
            return nil
        }
        let lease = Lease(session: self)
        leases.append(lease)
        let reused = subscription != nil
        if !reused {
            let handle = SubscriberHandle(
                channelName: RealtimeRuntime.chatChannelName(conversationId: key.conversationId),
                onFrame: { [weak self] frame in self?.onFrame(frame) },
                onEstablished: { [weak self] isResubscribe in self?.onEstablished(isResubscribe) },
                onSubscribeError: { [weak self] error in self?.onSubscribeError(error) }
            )
            subscription = backend.subscribe(handle)
        }
        lock.unlock()
        if reused {
            backend.subscriberReturned()
            lane.async { self.retryFailedInitialSync() }
        }
        return lease
    }

    /// Only after the initial load failed: a session still awaiting its first acknowledgement, or
    /// one whose subscription was not acknowledged, has nothing to fetch yet.
    private func retryFailedInitialSync() {
        guard initialSyncFailed, !isEnded else { return }
        DashXLog.d(tag: Self.tag, "Retrying the failed initial load of \(key.conversationId) for a reopened lease")
        syncAttempts = 0
        startSync()
    }

    private func onFrame(_ frame: DashXRealtimeMessage) {
        switch frame {
        case .inAppChatMessage(let message):
            let chatMessage = DashXChatMessage(frame: message)
            lane.async { self.mergeLive(chatMessage) }
        case .inAppChatStream(let stream):
            lane.async { self.mergeStream(stream) }
        default:
            break
        }
    }

    private func onEstablished(_ isResubscribe: Bool) {
        DashXLog.d(tag: Self.tag, "Channel acknowledged for \(key.conversationId) (isResubscribe=\(isResubscribe))")
        lane.async {
            // Frames sent while disconnected are gone, an `END` that stored nothing among them,
            // so an unfinished reply could otherwise stay on screen. A finished one waits for its
            // stored reply, which the reconcile below fetches if its frame was lost too.
            if isResubscribe, self.replyStream?.isComplete == false {
                self.replyStream = nil
                // Now, not after the reconcile: a failing fetch would otherwise keep it on screen.
                self.publishReadyIfShown()
            }
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
        initialSyncFailed = false
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
            } while await onLane({ () -> Bool in
                // Checked and cleared in one lane hop, or a resync requested in between is orphaned.
                if self.resyncPending { return true }
                self.syncAttempts = 0
                self.syncing = false
                return false
            })
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
                    if !self.snapshotDone { self.initialSyncFailed = true }
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
            var rows = try await backend.fetchPage(conversationId: key.conversationId, limit: Self.pageSize, page: lastPage)
            var oldestPage = lastPage
            // A short tail page can be a single row; the page before it fills the first screen.
            if rows.count < Self.pageSize && lastPage > 1 {
                rows += try await backend.fetchPage(conversationId: key.conversationId, limit: Self.pageSize, page: lastPage - 1)
                oldestPage = lastPage - 1
            }
            // Keyed by id: a deletion between the two fetches shifts a row across the page boundary.
            let candidate = mergeInto([], rows)
            let oldestFetched = oldestPage
            let done: Bool = await onLane {
                let (bufferSnapshot, overflowed) = self.drainBufferAndResumeLive()
                if overflowed { return false }
                self.messages = self.mergeInto(candidate, bufferSnapshot)
                self.snapshotDone = true
                self.historyGeneration += 1
                self.oldestFetchedPage = oldestFetched
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
        settleAnsweredStream()
        let next = DashXConversationState.ready(
            messages: messages,
            hasOlderMessages: oldestFetchedPage > 1,
            streamingReply: replyStream?.reply
        )
        if state == next { return }
        publishState(next)
    }

    /// Frames of one run in order; a later turn or a retried run of the same turn replaces the
    /// current one. Published only while the state is `.ready`.
    private func mergeStream(_ frame: DashXRealtimeChatStream) {
        let run = ReplyStreamRun(turnSeq: frame.turnSeq, run: frame.run)
        // Before the run checks, which drop a run a later turn or a newer run has ended: its
        // `END` still replaces the idle fallback. Nothing was stored, or the stored reply is in
        // history and fetched if its frame does not follow.
        if frame.kind == .end {
            idleChecks.removeValue(forKey: run)?.cancel()
            if frame.persisted == true { fetchStoredReplyIfMissing(run) }
        }
        if let settledStreamRun, run <= settledStreamRun { return }
        if let newestStreamRun, run < newestStreamRun { return }
        newestStreamRun = run
        if replyStream?.run != run { replyStream = ReplyStreamAccumulator(run: run) }

        switch frame.kind {
        case .delta:
            replyStream?.add(seq: frame.seq, responseId: frame.responseId, text: frame.text ?? "")
        case .end:
            if frame.persisted == true {
                replyStream?.complete(deltaCount: frame.seq)
            } else {
                settleStream()
            }
        }
        armStreamTimeout(run)
        publishReadyIfShown()
    }

    /// A conversation showing `.loading` or `.error` keeps it: a stream change alone must not
    /// replace an error with a stale list.
    private func publishReadyIfShown() {
        if case .ready = state { publishReady() }
    }

    /// A lost frame must not leave a preview up forever. An unfinished run that goes quiet is
    /// hidden but kept, since a tool call sends nothing for a while and its answer may still
    /// stream, and history is reconciled in case its `END` was lost. A finished run is left to
    /// `fetchStoredReplyIfMissing`.
    ///
    /// The check outlives the preview: a later turn ends the preview, but the run's reply may be
    /// in history with its `END` and stored frame both lost, as a lagging socket drops frames
    /// without reconnecting. Only hiding depends on the run still being shown.
    private func armStreamTimeout(_ run: ReplyStreamRun) {
        idleChecks.keys.filter { $0.turnSeq == run.turnSeq }
            .forEach { idleChecks.removeValue(forKey: $0)?.cancel() }
        guard replyStream?.run == run, replyStream?.isComplete == false else { return }
        // Only the run is captured: a copy of the accumulator would keep its deltas alive and
        // make every later delta copy them.
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, !self.isEnded else { return }
            self.idleChecks.removeValue(forKey: run)
            guard !self.hasStoredReply(forTurn: run.turnSeq) else { return }
            if self.replyStream?.run == run { self.replyStream?.hide() }
            self.reconcileAfterStreamTimeout()
        }
        idleChecks[run] = timeout
        lane.asyncAfter(deadline: .now() + streamTimeouts.idle, execute: timeout)
    }

    /// A finished run's reply is in history, so its fetch outlives the preview: a later turn or a
    /// newer run ends the preview, not this. Skipped once the stored reply has arrived; otherwise
    /// the preview, if still this run's, is dropped.
    private func fetchStoredReplyIfMissing(_ run: ReplyStreamRun) {
        lane.asyncAfter(deadline: .now() + streamTimeouts.storedReplyGrace) { [weak self] in
            guard let self, !self.isEnded, !self.hasStoredReply(forTurn: run.turnSeq) else { return }
            if self.replyStream?.run == run { self.settleStream() }
            self.reconcileAfterStreamTimeout()
        }
    }

    private func reconcileAfterStreamTimeout() {
        // A first load still in flight may predate the stored reply, so it is followed by a
        // reconcile too. One not yet started fetches everything when it runs.
        if snapshotDone || syncing { requestResync() }
        publishReadyIfShown()
    }

    /// The stored reply replaces the stream, whether it arrived before the stream's frames or after.
    /// A later turn ends it too: the server stores a visible reply only while its turn is current.
    private func settleAnsweredStream() {
        guard let turnSeq = replyStream?.run.turnSeq else { return }
        let overtaken = (messages.last?.turnSeq).map { $0 > turnSeq } ?? false
        if overtaken || hasStoredReply(forTurn: turnSeq) { settleStream() }
    }

    private func settleStream() {
        guard let run = replyStream?.run else { return }
        settledStreamRun = max(settledStreamRun ?? run, run)
        replyStream = nil
    }

    /// `messages` is ordered by turn, so the scan stops at the first earlier turn.
    private func hasStoredReply(forTurn turnSeq: Int) -> Bool {
        for message in messages.reversed() {
            if message.turnSeq < turnSeq { return false }
            if message.turnSeq == turnSeq && !message.isFromVisitor { return true }
        }
        return false
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
            guard self.snapshotDone, page >= 1, !self.loadingPreviousPage else { return }
            self.loadingPreviousPage = true
            let generation = self.historyGeneration
            Task {
                do {
                    let rows = try await self.backend.fetchPage(conversationId: self.key.conversationId, limit: Self.pageSize, page: page)
                    await self.onLane {
                        self.loadingPreviousPage = false
                        // Numbered against the replaced snapshot; the next call pages from the new one.
                        guard self.historyGeneration == generation else { return }
                        self.oldestFetchedPage = page
                        self.applyMerge(rows)
                    }
                } catch {
                    await self.onLane { self.loadingPreviousPage = false }
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
                    if !success {
                        DashXLog.d(tag: Self.tag, "Read position of \(self.key.conversationId) not moved to \(messageId); the next message retries")
                    }
                    // Settled either way, or a declined id would be re-sent on every debounce.
                    self.markedMessageId = messageId
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
        detach()?()
    }

    /// Ends the session without telling its leases; the returned closure publishes
    /// `.sessionEnded` to them. Until it runs, `state` and its replay keep the last state and a
    /// refused send waits, so nothing has the app reopen the conversation before the identity
    /// change commits. Nil when the session had already ended.
    func detach() -> (() -> Void)? {
        lock.lock()
        if ended {
            lock.unlock()
            return nil
        }
        ended = true
        heldEndedReports = []
        let toNotify = leases
        leases.removeAll()
        let departing = subscription
        subscription = nil
        writeVisibilityLocked(false)
        lock.unlock()

        departing?.unsubscribe()
        ChatCoordinator.shared.remove(key, self)
        return {
            let terminal = DashXConversationState.error(.sessionEnded)
            self.lock.lock()
            self.currentState = terminal
            let held = self.heldEndedReports ?? []
            self.heldEndedReports = nil
            self.lock.unlock()
            toNotify.forEach { lease in
                lease.notifyStateListeners(terminal)
                if let callback = lease.terminatedCallback {
                    self.deliver { callback(.sessionEnded) }
                }
            }
            held.forEach(self.deliver)
        }
    }

    /// Delivers a `.sessionEnded` report, after the leases hear of the end when it is still held.
    fileprivate func deliverEndedReport(_ report: @escaping () -> Void) {
        lock.lock()
        if heldEndedReports != nil {
            heldEndedReports?.append(report)
            lock.unlock()
            return
        }
        lock.unlock()
        deliver(report)
    }

    fileprivate func closeLease(_ lease: Lease) {
        lock.lock()
        guard let index = leases.firstIndex(where: { $0 === lease }) else {
            lock.unlock()
            return
        }
        leases.remove(at: index)
        if lease.visibleNow {
            lease.visibleNow = false
            if !leases.contains(where: { $0.visibleNow }) { writeVisibilityLocked(false) }
        }
        let teardown = leases.isEmpty && !ended
        if teardown { ended = true }
        let departing = teardown ? subscription : nil
        if teardown { subscription = nil }
        lock.unlock()

        if teardown {
            departing?.unsubscribe()
            ChatCoordinator.shared.remove(key, self)
        }
    }

    fileprivate func setLeaseVisible(_ lease: Lease, _ visible: Bool) {
        lock.lock()
        // A lease already closed, or a session already ended, no longer owns visibility: writing
        // it back would outlive the close that cleared it.
        guard !ended, leases.contains(where: { $0 === lease }) else {
            lock.unlock()
            return
        }
        lease.visibleNow = visible
        writeVisibilityLocked(leases.contains { $0.visibleNow })
        lock.unlock()
        if visible {
            backend.dismissConversationNotifications(conversationId: key.conversationId)
            lane.async { self.maybeMarkRead() }
        }
    }

    /// Call with `lock` held: visibility is written in the hold that decides it, so a close and a
    /// concurrent visibility change land in the order they were decided.
    private func writeVisibilityLocked(_ visible: Bool) {
        backend.setConversationVisible(conversationId: key.conversationId, owner: ObjectIdentifier(self), visible: visible)
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
            // A retained screen must not post into a conversation its lease or identity has left:
            // the request would carry the next identity's token. Checked again at dispatch, which
            // a first token load can delay past a close.
            guard canSend else {
                session.deliverEndedReport { completion(.failure(DashXClientError.sessionEnded)) }
                return clientMessageId
            }
            session.backend.send(
                identityId: session.key.chatIdentityId,
                conversationId: session.key.conversationId,
                content: content,
                clientMessageId: clientMessageId,
                shouldDispatch: { [weak self] in self?.canSend ?? false }
            ) { result in
                // The frame is missed while the socket reconnects, and a retry of a committed send
                // gets no frame at all; the merge dedupes by id.
                if case .success(let message) = result {
                    session.lane.async { session.mergeLive(message) }
                }
                if case .failure(let error as DashXClientError) = result, case .sessionEnded = error {
                    session.deliverEndedReport { completion(result) }
                } else {
                    completion(result)
                }
            }
            return clientMessageId
        }

        func loadPreviousPage(onError: ((Error) -> Void)?) {
            session.loadPreviousPageInternal(onError: onError)
        }

        private var canSend: Bool {
            lock.lock()
            let isClosed = closed
            lock.unlock()
            return !isClosed && session.canSend
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

/// Identifies one reply run: the turn it answers, then the run number a retry raises.
struct ReplyStreamRun: Comparable, Hashable {
    let turnSeq: Int
    let run: Int

    static func < (lhs: ReplyStreamRun, rhs: ReplyStreamRun) -> Bool {
        (lhs.turnSeq, lhs.run) < (rhs.turnSeq, rhs.run)
    }
}

struct ReplyStreamTimeouts {
    /// Quiet time after which an unfinished run is hidden.
    var idle: TimeInterval = 20
    /// Time a finished run waits for its stored reply before it is dropped.
    var storedReplyGrace: TimeInterval = 5
}

/// The deltas of one reply run. Text is read up to the first missing `seq`, so a lost frame
/// never shows as a hole, and only the run's last model response counts: earlier ones are text
/// produced before a tool call.
struct ReplyStreamAccumulator {
    let run: ReplyStreamRun
    private var deltas: [Int: (responseId: String?, text: String)] = [:]
    private(set) var isComplete = false
    /// Deltas the run sent, from its `END`'s `seq`; fewer received means one was lost.
    private var expectedDeltaCount: Int?
    /// Gone quiet; a new delta or its `END` shows it again.
    private var isHidden = false

    init(run: ReplyStreamRun) {
        self.run = run
    }

    mutating func add(seq: Int, responseId: String?, text: String) {
        guard deltas[seq] == nil else { return }
        deltas[seq] = (responseId, text)
        isHidden = false
    }

    mutating func complete(deltaCount: Int) {
        isComplete = true
        expectedDeltaCount = deltaCount
        isHidden = false
    }

    mutating func hide() {
        isHidden = true
    }

    var reply: DashXStreamingReply? {
        if isHidden { return nil }
        var contiguous: [(responseId: String?, text: String)] = []
        while let delta = deltas[contiguous.count] { contiguous.append(delta) }
        // A finished run missing a delta would present truncated text as the whole reply; it
        // stays hidden until the delta arrives or the stored reply replaces it.
        if let expectedDeltaCount, contiguous.count < expectedDeltaCount { return nil }
        guard let last = contiguous.last else { return nil }
        let text = contiguous.filter { $0.responseId == last.responseId }.map(\.text).joined()
        return text.isEmpty ? nil : DashXStreamingReply(turnSeq: run.turnSeq, text: text, isComplete: isComplete)
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
