import XCTest
@testable import DashX

private struct FakeSubscription: DashXRealtimeSubscription {
    let onUnsubscribe: () -> Void
    func unsubscribe() { onUnsubscribe() }
}

private final class FakeBackend: ChatSessionBackend {
    let handles = Atomic<[SubscriberHandle]>([])
    let unsubscribeCount = Atomic<Int>(0)
    let summarizeCalls = Atomic<Int>(0)
    let fetchPageCalls = Atomic<[Int]>([])
    let fetchAfterCursors = Atomic<[String]>([])
    let markReadIds = Atomic<[String]>([])
    let markReadResult = Atomic<Bool>(true)
    let sentClientMessageIds = Atomic<[String]>([])
    /// The committed row the fake server returns for a send, keyed by the client message id.
    let sendResult = Atomic<(String) -> DashXChatMessage>({ clientMessageId in
        chatMessage("sent-\(clientMessageId)", seq: 1_000, externalUid: "in_app_chat:\(clientMessageId)")
    })

    let count = Atomic<Int>(0)
    let pages = Atomic<[Int: [DashXChatMessage]]>([:])
    let after = Atomic<(String) throws -> [DashXChatMessage]>({ _ in [] })
    /// When set, fetchPage suspends until opened — frames arriving meanwhile must buffer.
    let pageGate = Atomic<Gate?>(nil)
    /// When set, fetchAfter suspends until opened — the cursor walk stalls mid-flight.
    let afterGate = Atomic<Gate?>(nil)
    /// Thrown by the next fetchPage calls while positive.
    let pageFailures = Atomic<Int>(0)
    /// Thrown by the next summarizeMessages calls while positive; models a failing initial load.
    let summarizeFailures = Atomic<Int>(0)
    let summarizeFailure = Atomic<Error>(DashXClientError.networkError(underlying: NSError(domain: "boom", code: 1)))
    let foreground = Atomic<Bool>(true)

    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription {
        handles.append(handle)
        return FakeSubscription { [unsubscribeCount] in _ = unsubscribeCount.increment() }
    }

    func summarizeMessages(conversationId: String) async throws -> Int {
        _ = summarizeCalls.increment()
        if summarizeFailures.value > 0 {
            summarizeFailures.mutate { $0 -= 1 }
            throw summarizeFailure.value
        }
        return count.value
    }

    func fetchPage(conversationId: String, limit: Int, page: Int) async throws -> [DashXChatMessage] {
        fetchPageCalls.append(page)
        if let gate = pageGate.value { await gate.wait() }
        if pageFailures.value > 0 {
            pageFailures.mutate { $0 -= 1 }
            throw DashXClientError.networkError(underlying: NSError(domain: "page", code: 1))
        }
        return pages.value[page] ?? []
    }

    func fetchAfter(conversationId: String, limit: Int, afterMessageId: String) async throws -> [DashXChatMessage] {
        fetchAfterCursors.append(afterMessageId)
        if let gate = afterGate.value { await gate.wait() }
        return try after.value(afterMessageId)
    }

    func send(
        identityId: String,
        conversationId: String,
        content: [String: Any],
        clientMessageId: String,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    ) {
        sentClientMessageIds.append(clientMessageId)
        completion(.success(sendResult.value(clientMessageId)))
    }

    func markRead(
        identityId: String,
        conversationId: String,
        lastMessageId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        markReadIds.append(lastMessageId)
        completion(.success(markReadResult.value))
    }

    func setConversationVisible(conversationId: String, visible: Bool) {}
    func dismissConversationNotifications(conversationId: String) {}
    var isAppForeground: Bool { foreground.value }
}

private final class FakeSocket: RealtimeSocket {
    func send(text: String) {}
    func close(code: Int, reason: String?) {}
    func cancel() {}
}

/// Data from a `FakeBackend`, subscriptions through a real `RealtimeRuntime` over fake sockets.
private final class RuntimeBackedBackend: ChatSessionBackend {
    let data = FakeBackend()
    let url = Atomic<URL?>(nil)
    let unmet = Atomic<DashXClientError?>(nil)
    let states = Atomic<[DashXConnectionState]>([])
    let connections = Atomic<[(socket: FakeSocket, listener: RealtimeSocketListener)]>([])
    let credentials = Atomic(CredentialVersion(sessionGeneration: 0, tokenEpoch: 0))
    /// Answers a 4401's refresh request; fails by default.
    let authRejected = Atomic<(@escaping (AuthRefreshOutcome) -> Void) -> Void>({ $0(.failed) })
    private(set) var runtime: RealtimeRuntime!

    init(ackTimeout: TimeInterval = RealtimeRuntime.ackTimeout) {
        runtime = RealtimeRuntime(
            endpointProvider: { [url, credentials] in url.value.map { RealtimeEndpoint(url: $0, credentials: credentials.value) } },
            unmetPrerequisite: { [unmet] in unmet.value },
            currentCredentials: { [credentials] in credentials.value },
            onAnyFrame: { _ in },
            onAuthRejected: { [authRejected] _, completion in authRejected.value(completion) },
            publishState: { [states, url, unmet, credentials] status in
                let endpointAvailable = url.value != nil
                if let state = status.resolve(
                    endpointAvailable: endpointAvailable,
                    awaitingToken: !endpointAvailable && unmet.value == nil,
                    current: credentials.value
                ) {
                    states.append(state)
                }
            },
            initialForeground: true,
            socketFactory: { [connections] _, listener in
                let socket = FakeSocket()
                connections.append((socket, listener))
                return socket
            },
            ackTimeout: ackTimeout
        )
    }

    func openAndAck(_ conversationId: String) {
        guard let (socket, listener) = connections.value.last else { return }
        listener.socketDidOpen(socket)
        let channel = RealtimeRuntime.chatChannelName(conversationId: conversationId)
        listener.socket(socket, didReceiveText: #"{"type":"SUBSCRIPTION_SUCCEEDED","data":{"channel":"\#(channel)"}}"#)
    }

    func subscribe(_ handle: SubscriberHandle) -> DashXRealtimeSubscription { runtime.subscribe(handle) }
    func summarizeMessages(conversationId: String) async throws -> Int { try await data.summarizeMessages(conversationId: conversationId) }
    func fetchPage(conversationId: String, limit: Int, page: Int) async throws -> [DashXChatMessage] {
        try await data.fetchPage(conversationId: conversationId, limit: limit, page: page)
    }
    func fetchAfter(conversationId: String, limit: Int, afterMessageId: String) async throws -> [DashXChatMessage] {
        try await data.fetchAfter(conversationId: conversationId, limit: limit, afterMessageId: afterMessageId)
    }
    func send(
        identityId: String,
        conversationId: String,
        content: [String: Any],
        clientMessageId: String,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    ) {
        data.send(identityId: identityId, conversationId: conversationId, content: content, clientMessageId: clientMessageId, completion: completion)
    }
    func markRead(identityId: String, conversationId: String, lastMessageId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        data.markRead(identityId: identityId, conversationId: conversationId, lastMessageId: lastMessageId, completion: completion)
    }
    func setConversationVisible(conversationId: String, visible: Bool) {}
    func dismissConversationNotifications(conversationId: String) {}
    var isAppForeground: Bool { true }
}

private final class RecordingListener: DashXConversationStateListener {
    let seen = Atomic<[DashXConversationState]>([])
    func onConversationStateChanged(_ state: DashXConversationState) { seen.append(state) }

    func readyIdLists() -> [[String]] {
        seen.value.compactMap { state in
            if case .ready(let messages, _) = state { return messages.map(\.id) }
            return nil
        }
    }
}

final class ConversationSessionTests: XCTestCase {
    private let key = ChatSessionKey(chatIdentityId: "identity-1", conversationId: "c1")

    private func readyIds(_ lease: DashXConversationLease) -> [String]? {
        if case .ready(let messages, _) = lease.state { return messages.map(\.id) }
        return nil
    }

    private func hasOlder(_ lease: DashXConversationLease) -> Bool? {
        if case .ready(_, let hasOlderMessages) = lease.state { return hasOlderMessages }
        return nil
    }

    private func isLoading(_ lease: DashXConversationLease) -> Bool {
        if case .loading = lease.state { return true }
        return false
    }

    private func errorOf(_ lease: DashXConversationLease) -> DashXClientError? {
        if case .error(let error) = lease.state { return error }
        return nil
    }

    private func openReady(_ backend: FakeBackend, history: [DashXChatMessage]) -> (ConversationSession, DashXConversationLease) {
        backend.count.value = history.count
        var pages = [max(1, (history.count + 49) / 50): Array(history.suffix(50))]
        if history.count > 50 { pages[1] = Array(history.prefix(50)) }
        backend.pages.value = pages
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        let newestIds = history.suffix(50).map(\.id)
        awaitUntil(what: "initial ready") { self.readyIds(lease) == newestIds || self.readyIds(lease) == history.map(\.id) }
        return (session, lease)
    }

    func testInitialLoadTransientFailureRetriesAndBecomesReady() {
        let backend = FakeBackend()
        backend.count.value = 1
        backend.pages.value = [1: [chatMessage("m1", seq: 1)]]
        backend.summarizeFailures.value = 1

        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)

        awaitUntil(what: "first attempt failed") { backend.summarizeCalls.value == 1 }
        settle(0.1)
        XCTAssertTrue(isLoading(lease), "stays loading while the retry is pending")
        awaitUntil(what: "ready after retry") { self.readyIds(lease) == ["m1"] }
        XCTAssertEqual(backend.summarizeCalls.value, 2)
        session.endSession()
    }

    func testInitialLoadTerminalFailureReportsErrorWithoutRetry() {
        let backend = FakeBackend()
        backend.summarizeFailures.value = 1
        backend.summarizeFailure.value = graphQLFailure("gone", code: DashXGraphQLErrors.notFound)

        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)

        awaitUntil(what: "error") { self.errorOf(lease) != nil }
        settle(1.2)
        XCTAssertEqual(backend.summarizeCalls.value, 1, "no retry for a terminal failure")
        session.endSession()
    }

    func testMarkReadRequiresForegroundAndVisibilityAtMarkTime() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        backend.foreground.value = false
        lease.setVisible(true)
        settle(0.7)
        XCTAssertTrue(backend.markReadIds.value.isEmpty, "backgrounded: nothing marked")

        backend.foreground.value = true
        session.onAppForegrounded()
        awaitUntil(what: "marked once foregrounded") { backend.markReadIds.value == ["m1"] }

        // Hidden during the debounce: the pending mark must not fire.
        backend.handles.value[0].onFrame(chatFrame("m2", seq: 2))
        awaitUntil(what: "m2 displayed") { self.readyIds(lease) == ["m1", "m2"] }
        lease.setVisible(false)
        settle(0.7)
        XCTAssertEqual(backend.markReadIds.value, ["m1"])
        session.endSession()
    }

    func testDeclinedMarkReadIsSettledAndTheNextMessageRetries() {
        let backend = FakeBackend()
        backend.markReadResult.value = false
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        lease.setVisible(true)
        awaitUntil(what: "first mark") { backend.markReadIds.value == ["m1"] }
        settle(1.2) // several debounce periods: a declined mark must not be re-sent
        XCTAssertEqual(backend.markReadIds.value, ["m1"])

        backend.after.value = { cursor in cursor == "m1" ? [chatMessage("m2", seq: 2)] : [] }
        backend.handles.value[0].onFrame(chatFrame("m2", seq: 2))
        awaitUntil(what: "the newer message is marked") { backend.markReadIds.value == ["m1", "m2"] }
        session.endSession()
    }

    func testFramesArrivingDuringSnapshotBufferAndAppearExactlyOnce() {
        let backend = FakeBackend()
        backend.count.value = 2
        backend.pages.value = [1: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)]]
        let gate = Gate()
        backend.pageGate.value = gate

        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "fetch started") { backend.fetchPageCalls.value.count == 1 }

        // Arrives mid-fetch: must be buffered, then merged into the SAME emission as the history.
        backend.handles.value[0].onFrame(chatFrame("m3", seq: 3))
        settle(0.1)
        XCTAssertTrue(isLoading(lease), "no partial emission while the snapshot runs")

        gate.open()
        awaitUntil(what: "merged ready") { self.readyIds(lease) == ["m1", "m2", "m3"] }
        session.endSession()
    }

    func testConcurrentFramesNoneLostOrMisordered() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [])

        let perThread = 50
        let group = DispatchGroup()
        for thread in 0..<4 {
            group.enter()
            DispatchQueue.global().async {
                for i in 0..<perThread {
                    let n = thread * perThread + i
                    backend.handles.value[0].onFrame(chatFrame(String(format: "f%03d", n), seq: n))
                }
                group.leave()
            }
        }
        group.wait()

        awaitUntil(what: "all 200 frames merged") { self.readyIds(lease)?.count == 200 }
        XCTAssertEqual(readyIds(lease), (0..<200).map { String(format: "f%03d", $0) }, "no frame lost or duplicated")
        session.endSession()
    }

    func testReconnectFetchesForwardFromTheMarkPreservingHistory() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        backend.after.value = { cursor in cursor == "m2" ? [chatMessage("m3", seq: 3), chatMessage("m4", seq: 4)] : [] }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "forward merge") { self.readyIds(lease) == ["m1", "m2", "m3", "m4"] }
        XCTAssertEqual(backend.summarizeCalls.value, 1, "reconnect must not re-summarize")
        XCTAssertEqual(backend.fetchPageCalls.value.count, 1, "reconnect must not refetch pages")
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m2"])
        session.endSession()
    }

    func testReconnectGapLargerThanOnePageLoopsUntilShortPage() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        let fullPage = (1...50).map { chatMessage(String(format: "g%03d", $0), seq: 100 + $0) }
        let shortPage = (51...60).map { chatMessage(String(format: "g%03d", $0), seq: 100 + $0) }
        backend.after.value = { cursor in
            switch cursor {
            case "m2": return fullPage
            case "g050": return shortPage
            default: return []
            }
        }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "both pages merged") { self.readyIds(lease)?.count == 62 }
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m2", "g050"])
        XCTAssertEqual(Set(readyIds(lease)!).count, 62, "nothing duplicated")
        session.endSession()
    }

    func testReconnectWithNoGapCausesNoStateChurn() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])
        let listener = RecordingListener()
        lease.addStateListener(listener)
        awaitUntil(what: "replay") { listener.seen.value.count == 1 }

        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "cursor fetch ran") { backend.fetchAfterCursors.value.count == 1 }
        settle(0.15)
        XCTAssertEqual(listener.seen.value.count, 1, "an empty page must not emit a new state")
        XCTAssertEqual(readyIds(lease), ["m1"])
        session.endSession()
    }

    func testRejectedCursorRebuildsOnceAndTheNextReconnectUsesAValidCursor() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        // The retained cursor (m2) was deleted server-side: the fetch is rejected, and the rebuilt
        // snapshot no longer contains it.
        backend.after.value = { _ in
            throw graphQLFailure("`after_message_id` is not a visible message of this conversation.", code: DashXGraphQLErrors.unprocessableEntity)
        }
        backend.count.value = 1
        backend.pages.value = [1: [chatMessage("m1", seq: 1)]]
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "rebuilt ready") { self.readyIds(lease) == ["m1"] }
        XCTAssertEqual(backend.summarizeCalls.value, 2, "initial + rebuild")

        // The mark was recomputed from the replacement: the next reconnect submits m1, not m2.
        backend.after.value = { _ in [] }
        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "second reconnect fetch") { backend.fetchAfterCursors.value.count == 2 }
        XCTAssertEqual(backend.fetchAfterCursors.value[1], "m1")
        session.endSession()
    }

    func testReconnectRejectedByATokenProblemKeepsTheSnapshotAndDoesNotRebuild() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        // UNAUTHORIZED is not a cursor problem: rebuilding would fail the same way, and the auth
        // retry / provider refresh is what recovers it. The loaded list must stay on screen.
        backend.after.value = { _ in throw graphQLFailure("Incorrect Identity Token: Expired.", code: DashXGraphQLErrors.unauthorized) }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "cursor fetch attempted") { backend.fetchAfterCursors.value.count == 1 }
        settle(0.2)
        XCTAssertEqual(readyIds(lease), ["m1", "m2"])
        XCTAssertEqual(backend.summarizeCalls.value, 1, "no rebuild for a non-cursor failure")
        session.endSession()
    }

    func testReconnectRejectedByPermissionLossSurfacesErrorWithoutRebuilding() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        backend.after.value = { _ in throw graphQLFailure("You don't have access to this chat conversation.", code: DashXGraphQLErrors.forbidden) }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "error state") { self.errorOf(lease) != nil }
        XCTAssertEqual(errorOf(lease)?.graphQLCode, DashXGraphQLErrors.forbidden)
        XCTAssertEqual(backend.summarizeCalls.value, 1, "no rebuild for a non-cursor failure")
        session.endSession()
    }

    func testSendMessageMergesTheCommittedRowWithoutWaitingForAFrameAndReportsTheClientId() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])
        backend.sendResult.value = { clientId in chatMessage("m2", seq: 2, externalUid: "in_app_chat:\(clientId)") }

        let delivered = Atomic<DashXChatMessage?>(nil)
        let clientMessageId = lease.sendMessage(content: ["text": "hi"]) { result in
            switch result {
            case .success(let message): delivered.value = message
            case .failure(let error): XCTFail("send failed: \(error)")
            }
        }

        awaitUntil(what: "committed row merged") { self.readyIds(lease) == ["m1", "m2"] }
        XCTAssertEqual(backend.sentClientMessageIds.value, [clientMessageId])
        XCTAssertEqual(delivered.value?.clientMessageId, clientMessageId, "the server prefix is stripped")
        XCTAssertEqual(delivered.value?.externalUid, "in_app_chat:\(clientMessageId)")

        // Display-only: the merged send must not move the reconnect cursor past m1.
        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "reconnect fetch") { backend.fetchAfterCursors.value.count == 1 }
        XCTAssertEqual(backend.fetchAfterCursors.value[0], "m1")
        session.endSession()
    }

    func testClientMessageIdIsNilForRowsTheVisitorDidNotSend() {
        XCTAssertNil(chatMessage("a", seq: 1, externalUid: "in_app_chat_reply:abc").clientMessageId)
        XCTAssertNil(chatMessage("a", seq: 1, externalUid: nil).clientMessageId)
        XCTAssertEqual(chatMessage("a", seq: 1, externalUid: "in_app_chat:k-1").clientMessageId, "k-1")
    }

    func testPartialCursorWalkFailureKeepsTheStableCursorAndRetriesTheWholeWalk() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        // First walk: one full page succeeds, the next request fails, and a newer frame is
        // buffered meanwhile. Nothing may merge — merging would advance the high-water mark past
        // the unfetched gap and skip those messages forever.
        let fullPage = (1...50).map { chatMessage(String(format: "g%03d", $0), seq: 100 + $0) }
        let tail = (51...60).map { chatMessage(String(format: "g%03d", $0), seq: 100 + $0) } + [chatMessage("z999", seq: 999)]
        let failures = Atomic<Int>(0)
        backend.after.value = { cursor in
            switch cursor {
            case "m2": return fullPage
            case "g050":
                if failures.increment() == 1 { throw DashXClientError.networkError(underlying: NSError(domain: "blip", code: 1)) }
                return tail
            default: return []
            }
        }
        backend.handles.value[0].onEstablished(true)
        backend.handles.value[0].onFrame(chatFrame("z999", seq: 999)) // buffered while the walk runs

        awaitUntil(what: "first walk failed") { failures.value == 1 }
        settle(0.1)
        XCTAssertEqual(readyIds(lease), ["m1", "m2"], "nothing merged from the incomplete walk")

        awaitUntil(what: "retried walk completes") { self.readyIds(lease)?.count == 63 }
        XCTAssertEqual(Set(readyIds(lease)!).count, 63, "no message skipped or duplicated")
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m2", "g050", "m2", "g050"],
                       "the retry restarts from the STABLE cursor, not the partial walk's tail")
        session.endSession()
    }

    func testTransientGraphQLReconcileFailureRetriesAndLiveFramesResume() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1), chatMessage("m2", seq: 2)])

        // A transport failure surfaces as a code-less GraphQL failure; the socket stays healthy, so
        // no reconnect re-runs the walk — the session must, or buffered frames never appear.
        let failures = Atomic<Int>(0)
        backend.after.value = { cursor in
            guard cursor == "m2" else { return [] }
            if failures.increment() == 1 { throw graphQLFailure("connection reset", code: nil) }
            return [chatMessage("m3", seq: 3), chatMessage("m4", seq: 4)]
        }
        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "first walk failed") { failures.value == 1 }
        settle(0.1)
        XCTAssertEqual(readyIds(lease), ["m1", "m2"], "the snapshot stays on screen")

        awaitUntil(what: "retried walk from the unchanged cursor") { self.readyIds(lease) == ["m1", "m2", "m3", "m4"] }
        backend.handles.value[0].onFrame(chatFrame("m5", seq: 5))
        awaitUntil(what: "live frames flow again") { self.readyIds(lease) == ["m1", "m2", "m3", "m4", "m5"] }
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m2", "m2"])
        session.endSession()
    }

    func testSubscribeErrorBeforeAnySnapshotSurfacesErrorAndLateAckRecovers() {
        let backend = FakeBackend()
        backend.count.value = 1
        backend.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!

        backend.handles.value[0].onSubscribeError(.subscriptionFailed("nope"))
        awaitUntil(what: "error state") {
            if case .subscriptionFailed? = self.errorOf(lease) { return true }
            return false
        }

        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "late ack recovers") { self.readyIds(lease) == ["m1"] }
        session.endSession()
    }

    func testSubscribeErrorAfterReadyKeepsTheSnapshot() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        backend.handles.value[0].onSubscribeError(.subscriptionFailed("nope"))
        settle(0.15)
        XCTAssertEqual(readyIds(lease), ["m1"])
        session.endSession()
    }

    func testReadyReportsOlderHistoryUntilTheFirstPageIsFetched() {
        let backend = FakeBackend()
        backend.count.value = 100
        backend.pages.value = [
            2: (51...100).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
            1: (1...50).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
        ]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "last page ready") { self.readyIds(lease)?.count == 50 }
        XCTAssertEqual(hasOlder(lease), true, "a full page on screen, fifty behind it")
        XCTAssertEqual(backend.fetchPageCalls.value, [2])

        lease.loadPreviousPage()
        awaitUntil(what: "first page prepended") { self.readyIds(lease)?.count == 100 }
        XCTAssertEqual(hasOlder(lease), false)

        // Nothing left to page: another request is a no-op, not a fetch.
        lease.loadPreviousPage()
        settle(0.2)
        XCTAssertEqual(backend.fetchPageCalls.value, [2, 1])
        session.endSession()
    }

    func testLoadPreviousPageRunsOneFetchAtATimeAndAFailureReleasesTheGuard() {
        let backend = FakeBackend()
        backend.count.value = 150
        backend.pages.value = [
            3: (101...150).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
            2: (51...100).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
            1: (1...50).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
        ]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "last page ready") { self.readyIds(lease)?.count == 50 }

        let gate = Gate()
        backend.pageGate.value = gate
        lease.loadPreviousPage()
        lease.loadPreviousPage()
        lease.loadPreviousPage()
        awaitUntil(what: "older fetch started") { backend.fetchPageCalls.value == [3, 2] }
        settle(0.2)
        XCTAssertEqual(backend.fetchPageCalls.value, [3, 2], "duplicates while a fetch is in flight are dropped")
        backend.pageGate.value = nil
        gate.open()
        awaitUntil(what: "page 2 prepended") { self.readyIds(lease)?.count == 100 }

        backend.pageFailures.value = 1
        let failed = Atomic<Bool>(false)
        lease.loadPreviousPage(onError: { _ in failed.value = true })
        awaitUntil(what: "page 1 failed") { failed.value }
        XCTAssertEqual(hasOlder(lease), true, "a failure leaves the paging position alone")

        lease.loadPreviousPage()
        awaitUntil(what: "page 1 prepended after the failure") { self.readyIds(lease)?.count == 150 }
        XCTAssertEqual(backend.fetchPageCalls.value, [3, 2, 1, 1])
        XCTAssertEqual(hasOlder(lease), false)
        session.endSession()
    }

    func testLeaseWithoutCredentialsReportsNotIdentifiedAndRecoversWhenATokenArrives() {
        let backend = RuntimeBackedBackend()
        backend.unmet.value = .notIdentified
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!

        awaitUntil(what: "missing token surfaces") {
            if case .notIdentified? = self.errorOf(lease) { return true }
            return false
        }
        XCTAssertTrue(backend.connections.value.isEmpty)

        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.unmet.value = nil
        backend.runtime.onIdentityChanged(credentials: CredentialVersion(sessionGeneration: 0, tokenEpoch: 0))
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }
        backend.openAndAck("c1")
        awaitUntil(what: "recovered to ready") { self.readyIds(lease) == ["m1"] }
        session.endSession()
    }

    func testAnObsoleteRefreshFailureNeverReachesALeaseAwaitingItsFirstSnapshot() {
        let backend = RuntimeBackedBackend()
        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1)]]
        // The refresh fails, and a new token is installed before the runtime handles the failure.
        backend.authRejected.value = { completion in
            backend.credentials.value = CredentialVersion(sessionGeneration: 0, tokenEpoch: 1)
            completion(.failed)
        }
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }
        let (socket, listener) = backend.connections.value[0]
        listener.socketDidOpen(socket)
        listener.socket(socket, didCloseWithCode: 4401, reason: "UNAUTHORIZED")
        settle(0.3)
        XCTAssertTrue(isLoading(lease), "the old token's failure is not the new token's")

        backend.runtime.onIdentityChanged(fromAuthRefresh: true, credentials: backend.credentials.value)
        awaitUntil(what: "socket under the new token") { backend.connections.value.count == 2 }
        backend.openAndAck("c1")
        awaitUntil(what: "ready") { self.readyIds(lease) == ["m1"] }
        session.endSession()
    }

    func testANewLeaseNeverReceivesTheReplacedTokensAuthFailure() {
        let backend = RuntimeBackedBackend()
        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1, conversationId: "c2")]]
        let first = ConversationSession(key: key, backend: backend)
        let firstLease = first.newLease()!
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }
        let (socket, listener) = backend.connections.value[0]
        listener.socketDidOpen(socket)
        listener.socket(socket, didCloseWithCode: 4403, reason: "FORBIDDEN")
        awaitUntil(what: "first lease failed") {
            if case .subscriptionFailed? = self.errorOf(firstLease) { return true }
            return false
        }

        // A new token is installed; a lease opens before the runtime runs the reconnect.
        backend.credentials.value = CredentialVersion(sessionGeneration: 0, tokenEpoch: 1)
        let second = ConversationSession(key: ChatSessionKey(chatIdentityId: "identity-1", conversationId: "c2"), backend: backend)
        let secondLease = second.newLease()!
        settle(0.3)
        XCTAssertTrue(isLoading(secondLease), "the replaced token's failure is not this lease's")

        backend.runtime.onIdentityChanged(credentials: backend.credentials.value)
        awaitUntil(what: "socket under the new token") { backend.connections.value.count == 2 }
        backend.openAndAck("c2")
        awaitUntil(what: "ready") { self.readyIds(secondLease) == ["m1"] }
        first.endSession()
        second.endSession()
    }

    func testAReplacedTokensAcknowledgementTimeoutNeverReachesALease() {
        let backend = RuntimeBackedBackend(ackTimeout: 0.4)
        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }
        let (socket, listener) = backend.connections.value[0]
        listener.socketDidOpen(socket)

        // A new token is installed; the old socket's deadline elapses before the reconnect runs.
        backend.credentials.value = CredentialVersion(sessionGeneration: 0, tokenEpoch: 1)
        settle(0.8)
        XCTAssertTrue(isLoading(lease), "the old socket's timeout is not this lease's")

        backend.runtime.onIdentityChanged(credentials: backend.credentials.value)
        awaitUntil(what: "socket under the new token") { backend.connections.value.count == 2 }
        backend.openAndAck("c1")
        awaitUntil(what: "ready") { self.readyIds(lease) == ["m1"] }
        session.endSession()
    }

    func testAReplacedTokensAcknowledgementStartsNoSync() {
        let backend = RuntimeBackedBackend()
        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }

        // A new token is installed; the old socket acknowledges before the reconnect runs.
        backend.credentials.value = CredentialVersion(sessionGeneration: 0, tokenEpoch: 1)
        backend.openAndAck("c1")
        settle(0.3)
        XCTAssertEqual(backend.data.summarizeCalls.value, 0, "no history sync on the old socket's acknowledgement")
        XCTAssertTrue(isLoading(lease))

        backend.runtime.onIdentityChanged(credentials: backend.credentials.value)
        awaitUntil(what: "socket under the new token") { backend.connections.value.count == 2 }
        backend.openAndAck("c1")
        awaitUntil(what: "ready") { self.readyIds(lease) == ["m1"] }
        XCTAssertEqual(backend.data.summarizeCalls.value, 1)
        session.endSession()
    }

    func testALateLeaseNeverReusesAReplacedTokensAcknowledgement() {
        let backend = RuntimeBackedBackend()
        backend.url.value = URL(string: "wss://realtime.test/socket")
        backend.data.count.value = 1
        backend.data.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let first = ConversationSession(key: key, backend: backend)
        let firstLease = first.newLease()!
        awaitUntil(what: "socket") { backend.connections.value.count == 1 }
        backend.openAndAck("c1")
        awaitUntil(what: "first ready") { self.readyIds(firstLease) == ["m1"] }
        XCTAssertEqual(backend.data.summarizeCalls.value, 1)

        // A new token is installed; another identity's lease on the same channel opens before the
        // reconnect runs.
        backend.credentials.value = CredentialVersion(sessionGeneration: 0, tokenEpoch: 1)
        let second = ConversationSession(key: ChatSessionKey(chatIdentityId: "identity-2", conversationId: "c1"), backend: backend)
        let secondLease = second.newLease()!
        settle(0.3)
        XCTAssertEqual(backend.data.summarizeCalls.value, 1, "no history sync on the old socket's acknowledgement")
        XCTAssertTrue(isLoading(secondLease))

        backend.runtime.onIdentityChanged(credentials: backend.credentials.value)
        awaitUntil(what: "socket under the new token") { backend.connections.value.count == 2 }
        backend.openAndAck("c1")
        awaitUntil(what: "second ready") { self.readyIds(secondLease) == ["m1"] }
        first.endSession()
        second.endSession()
    }

    func testLeaseAwaitingAProviderLoadStaysLoading() {
        let backend = RuntimeBackedBackend()
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        settle(0.3)
        XCTAssertTrue(isLoading(lease), "a token on its way is not an error")
        XCTAssertEqual(backend.states.value.last, .connecting)
        session.endSession()
    }

    func testShortTailPageIsToppedUpWithThePageBeforeIt() {
        let backend = FakeBackend()
        backend.count.value = 51
        backend.pages.value = [
            2: [chatMessage("m051", seq: 51)],
            1: (1...50).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
        ]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "full first screen") { self.readyIds(lease)?.count == 51 }
        XCTAssertEqual(readyIds(lease)?.first, "m001")
        XCTAssertEqual(hasOlder(lease), false, "the top-up reached page 1")
        XCTAssertEqual(backend.fetchPageCalls.value, [2, 1])

        lease.loadPreviousPage()
        settle(0.2)
        XCTAssertEqual(backend.fetchPageCalls.value, [2, 1], "nothing older to fetch")
        session.endSession()
    }

    func testReadySinglePageConversationHasNoOlderHistory() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])
        XCTAssertEqual(hasOlder(lease), false)
        session.endSession()
    }

    func testTopUpPagesThatOverlapAfterADeletionYieldEachRowOnce() {
        let backend = FakeBackend()
        backend.count.value = 51
        // m001 was deleted between the two fetches: page 1 now ends with the row page 2 returned.
        backend.pages.value = [
            2: [chatMessage("m051", seq: 51)],
            1: (2...51).map { chatMessage(String(format: "m%03d", $0), seq: $0) },
        ]
        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "ready") { self.readyIds(lease) != nil }
        XCTAssertEqual(readyIds(lease), (2...51).map { String(format: "m%03d", $0) })
        session.endSession()
    }

    func testLoadPreviousPageNeverMovesTheReconnectCursorBackward() {
        let backend = FakeBackend()
        let newest = (51...60).map { chatMessage(String(format: "m%03d", $0), seq: $0) }
        let oldest = (1...50).map { chatMessage(String(format: "m%03d", $0), seq: $0) }
        backend.count.value = 60
        backend.pages.value = [2: newest, 1: oldest]

        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "topped-up first screen") { self.readyIds(lease)?.count == 60 }

        backend.after.value = { _ in [] }
        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "cursor fetch") { backend.fetchAfterCursors.value.count == 1 }
        XCTAssertEqual(backend.fetchAfterCursors.value[0], "m060", "the mark is the newest message, not the last-fetched page's tail")
        session.endSession()
    }

    func testOutOfOrderFrameDoesNotAdvanceTheCursorAndReconnectRecoversTheLostSibling() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        // m2 and m3 commit server-side, but m3's frame overtakes m2's and m2's is lost with the
        // connection. m3 is displayed, yet the server has only confirmed history through m1.
        backend.handles.value[0].onFrame(chatFrame("m3", seq: 3))
        awaitUntil(what: "m3 displayed") { self.readyIds(lease) == ["m1", "m3"] }

        backend.after.value = { cursor in cursor == "m1" ? [chatMessage("m2", seq: 2), chatMessage("m3", seq: 3)] : [] }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "lost sibling recovered") { self.readyIds(lease) == ["m1", "m2", "m3"] }
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m1"],
                       "the reconnect walk must start at the server-confirmed cursor, not the frame — afterMessageId=m3 could never return m2")

        // The walk's last fetched row is now server-confirmed and becomes the cursor.
        backend.handles.value[0].onEstablished(true)
        awaitUntil(what: "second cursor fetch") { backend.fetchAfterCursors.value.count == 2 }
        XCTAssertEqual(backend.fetchAfterCursors.value[1], "m3")
        session.endSession()
    }

    func testBufferedFrameDuringSnapshotDoesNotAdvanceTheCursor() {
        let backend = FakeBackend()
        backend.count.value = 1
        backend.pages.value = [1: [chatMessage("m1", seq: 1)]]
        let gate = Gate()
        backend.pageGate.value = gate

        let session = ConversationSession(key: key, backend: backend)
        let lease = session.newLease()!
        backend.handles.value[0].onEstablished(false)
        awaitUntil(what: "fetch started") { backend.fetchPageCalls.value.count == 1 }

        // Same overtake, one layer deeper: the frame lands while the snapshot is still fetching, so
        // it merges from the buffer — the cursor must still come from the fetched page only.
        backend.handles.value[0].onFrame(chatFrame("m3", seq: 3))
        gate.open()
        awaitUntil(what: "snapshot + buffered frame ready") { self.readyIds(lease) == ["m1", "m3"] }

        backend.after.value = { cursor in cursor == "m1" ? [chatMessage("m2", seq: 2), chatMessage("m3", seq: 3)] : [] }
        backend.handles.value[0].onEstablished(true)

        awaitUntil(what: "gap healed") { self.readyIds(lease) == ["m1", "m2", "m3"] }
        XCTAssertEqual(backend.fetchAfterCursors.value, ["m1"])
        session.endSession()
    }

    func testStateListenerReplaysCurrentStateOnAddAndDiesWithItsLease() {
        let backend = FakeBackend()
        let (session, lease1) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        // A second screen opens the already-loaded conversation: its listener must render NOW.
        let lease2 = session.newLease()!
        let listener2 = RecordingListener()
        lease2.addStateListener(listener2)
        awaitUntil(what: "replayed current state") { listener2.readyIdLists().contains(["m1"]) }

        let listener1 = RecordingListener()
        lease1.addStateListener(listener1)
        lease2.close()

        backend.handles.value[0].onFrame(chatFrame("m2", seq: 2))
        awaitUntil(what: "open lease notified") { listener1.readyIdLists().contains(["m1", "m2"]) }
        XCTAssertFalse(listener2.readyIdLists().contains { $0.count == 2 }, "a closed lease's listener must not keep receiving states")
        session.endSession()
    }

    func testReadMarkNeverAdvancesToAnUnconfirmedFrameAndReconcilesFirst() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])

        lease.setVisible(true)
        awaitUntil(what: "confirmed newest marked") { backend.markReadIds.value == ["m1"] }

        // m3's frame overtakes lost m2. m3 is displayed but unconfirmed: it must trigger a reconcile
        // (stalled at the gate), and must NOT be marked read — marking it would mark the unseen m2
        // read server-side and kill its push.
        let gate = Gate()
        backend.afterGate.value = gate
        backend.after.value = { cursor in cursor == "m1" ? [chatMessage("m2", seq: 2), chatMessage("m3", seq: 3)] : [] }
        backend.handles.value[0].onFrame(chatFrame("m3", seq: 3))

        awaitUntil(what: "reconcile started from the confirmed cursor") { backend.fetchAfterCursors.value == ["m1"] }
        awaitUntil(what: "m3 displayed") { self.readyIds(lease) == ["m1", "m3"] }
        settle(0.6) // > mark debounce: any premature mark of m3 would have fired by now
        XCTAssertEqual(backend.markReadIds.value, ["m1"])

        gate.open()
        awaitUntil(what: "gap healed") { self.readyIds(lease) == ["m1", "m2", "m3"] }
        awaitUntil(what: "confirmed tail marked") { backend.markReadIds.value == ["m1", "m3"] }
        session.endSession()
    }

    func testEndSessionDeliversSessionEndedToLeasesAndTerminationCallbacks() {
        let backend = FakeBackend()
        let (session, lease) = openReady(backend, history: [chatMessage("m1", seq: 1)])
        let listener = RecordingListener()
        lease.addStateListener(listener)
        let terminated = Atomic<DashXSubscriptionEnd?>(nil)
        lease.setOnTerminated { terminated.value = $0 }

        session.endSession()

        awaitUntil(what: "terminated callback") { terminated.value == .sessionEnded }
        awaitUntil(what: "terminal state delivered") {
            listener.seen.value.contains { state in
                if case .error(.sessionEnded) = state { return true }
                return false
            }
        }
        if case .error(.sessionEnded) = lease.state {} else { XCTFail("lease must hold the terminal state") }
        XCTAssertEqual(backend.unsubscribeCount.value, 1)
        XCTAssertNil(session.newLease(), "an ended session accepts no new leases")
    }

    func testLastLeaseCloseTearsDownTheSubscriptionAndAnEarlierCloseDoesNot() {
        let backend = FakeBackend()
        let (session, lease1) = openReady(backend, history: [chatMessage("m1", seq: 1)])
        let lease2 = session.newLease()!

        lease1.close()
        lease1.close() // idempotent
        XCTAssertEqual(backend.unsubscribeCount.value, 0, "a sibling lease keeps the subscription alive")

        lease2.close()
        XCTAssertEqual(backend.unsubscribeCount.value, 1)
        XCTAssertNil(session.newLease(), "the torn-down session is not reusable")
    }
}
