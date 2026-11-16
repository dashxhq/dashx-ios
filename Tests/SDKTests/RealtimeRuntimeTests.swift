import XCTest
@testable import DashX

private final class FakeSocket: RealtimeSocket {
    let url: URL
    let sent = Atomic<[String]>([])
    let closedCode = Atomic<Int?>(nil)
    let cancelled = Atomic<Bool>(false)

    init(url: URL) {
        self.url = url
    }

    func send(text: String) { sent.append(text) }
    func close(code: Int, reason: String?) { closedCode.value = code }
    func cancel() { cancelled.value = true }
}

/// Held only by the socket under test; records when it is released.
private final class RetainedListener: RealtimeSocketListener {
    private let released: Atomic<Bool>

    init(released: Atomic<Bool>) {
        self.released = released
    }

    deinit { released.value = true }

    func socketDidOpen(_ socket: RealtimeSocket) {}
    func socket(_ socket: RealtimeSocket, didReceiveText text: String) {}
    func socket(_ socket: RealtimeSocket, didCloseWithCode code: Int, reason: String) {}
    func socket(_ socket: RealtimeSocket, didFailWithError error: Error) {}
}

/// Drives the actor through the socket-factory seam; no network.
private final class Harness {
    let states = Atomic<[DashXConnectionState]>([])
    let authRejections = Atomic<Int>(0)
    /// One entry per connection, recorded in a single write: a test that sees the socket can
    /// index its listener.
    let connections = Atomic<[(socket: FakeSocket, listener: RealtimeSocketListener)]>([])
    let established = Atomic<[Bool]>([])
    let frames = Atomic<Int>(0)
    let subscribeErrors = Atomic<[DashXClientError]>([])
    /// What the 4401 hook reports when no custom hook is installed.
    let authRefreshSucceeds = Atomic<Bool>(false)
    /// Custom hook: receives the completion and decides when (and what) to answer.
    let onAuthRejectedHook = Atomic<((@escaping (AuthRefreshOutcome) -> Void) -> Void)?>(nil)
    let url = Atomic<URL?>(URL(string: "wss://realtime.test/socket"))
    /// What the client reports when there is no URL; nil models a provider load in flight.
    let unmet = Atomic<DashXClientError?>(nil)
    /// The client's identity session; sockets are stamped with it when they connect.
    let identity = Atomic<Int>(0)
    let epoch = Atomic<Int>(0)

    let runtime: RealtimeRuntime

    init(initialForeground: Bool = true, url: URL? = URL(string: "wss://realtime.test/socket"), ackTimeout: TimeInterval = 60) {
        self.url.value = url
        var runtime: RealtimeRuntime!
        let harnessBox = Atomic<Harness?>(nil)
        runtime = RealtimeRuntime(
            endpointProvider: {
                guard let harness = harnessBox.value, let url = harness.url.value else { return nil }
                return RealtimeEndpoint(url: url, credentials: harness.credentials)
            },
            unmetPrerequisite: { harnessBox.value?.unmet.value },
            currentCredentials: { harnessBox.value?.credentials ?? CredentialVersion(sessionGeneration: 0, tokenEpoch: 0) },
            onAnyFrame: { _ in },
            onAuthRejected: { _, completion in
                guard let harness = harnessBox.value else { return completion(.failed) }
                _ = harness.authRejections.increment()
                if let hook = harness.onAuthRejectedHook.value {
                    hook(completion)
                } else {
                    completion(harness.authRefreshSucceeds.value ? .refreshed : .failed)
                }
            },
            publishState: { status in
                // Resolved as the client does, against the harness's credentials.
                guard let harness = harnessBox.value else { return }
                let endpointAvailable = harness.url.value != nil
                if let state = status.resolve(
                    endpointAvailable: endpointAvailable,
                    awaitingToken: !endpointAvailable && harness.unmet.value == nil,
                    current: harness.credentials
                ) {
                    harness.states.append(state)
                }
            },
            initialForeground: initialForeground,
            socketFactory: { url, listener in
                let socket = FakeSocket(url: url)
                harnessBox.value?.connections.append((socket, listener))
                return socket
            },
            ackTimeout: ackTimeout
        )
        self.runtime = runtime
        harnessBox.value = self
    }

    var lastState: DashXConnectionState? { states.value.last }

    var credentials: CredentialVersion {
        CredentialVersion(sessionGeneration: identity.value, tokenEpoch: epoch.value)
    }

    /// An identity change for the credentials current now, as the client issues it.
    func identityChanged(fromAuthRefresh: Bool = false) {
        runtime.onIdentityChanged(fromAuthRefresh: fromAuthRefresh, credentials: credentials)
    }

    @discardableResult
    func subscribe(_ conversationId: String = "c1") -> DashXRealtimeSubscription {
        runtime.subscribe(SubscriberHandle(
            channelName: RealtimeRuntime.chatChannelName(conversationId: conversationId),
            onFrame: { [frames] _ in _ = frames.increment() },
            onEstablished: { [established] in established.append($0) },
            onSubscribeError: { [subscribeErrors] in subscribeErrors.append($0) }
        ))
    }

    var sockets: [FakeSocket] { connections.value.map(\.socket) }

    func socket(_ index: Int) -> FakeSocket { connections.value[index].socket }
    func listener(_ index: Int) -> RealtimeSocketListener { connections.value[index].listener }

    func open(_ index: Int? = nil) {
        let i = index ?? (connections.value.count - 1)
        listener(i).socketDidOpen(socket(i))
    }

    func ack(_ channel: String, index: Int? = nil) {
        let i = index ?? (connections.value.count - 1)
        listener(i).socket(socket(i), didReceiveText: #"{"type":"SUBSCRIPTION_SUCCEEDED","data":{"channel":"\#(channel)"}}"#)
    }

    func close(_ index: Int, code: Int, reason: String) {
        listener(index).socket(socket(index), didCloseWithCode: code, reason: reason)
    }

    func fail(_ index: Int) {
        listener(index).socket(socket(index), didFailWithError: NSError(domain: "test", code: 1))
    }
}

private func isAuthFailed(_ state: DashXConnectionState?) -> Bool {
    if case .authenticationFailed? = state { return true }
    return false
}

private func isSubscriptionFailed(_ error: DashXClientError) -> Bool {
    if case .subscriptionFailed = error { return true }
    return false
}

final class RealtimeRuntimeTests: XCTestCase {

    func testSubscribeWhileATokenLoadIsPendingOpensNoSocketAndReportsConnecting() {
        let harness = Harness(url: nil)
        harness.subscribe()
        awaitUntil(what: "connecting") { harness.lastState == .connecting }
        settle(0.2)
        XCTAssertTrue(harness.sockets.isEmpty, "no speculative connect without an identity token")
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a token on its way is not an error")
        XCTAssertEqual(harness.lastState, .connecting)
    }

    func testTerminalCloseFromAPreviousIdentitysSocketIsIgnored() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "connected") { harness.lastState == .connected }

        // The identity moved on before the runtime processed the old socket's rejection.
        harness.identity.value = 1
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "close processed") { harness.lastState != .connected }
        settle(0.2)
        XCTAssertEqual(harness.authRejections.value, 0, "the new identity's refresh must not be spent")
        XCTAssertFalse(harness.states.value.contains(where: isAuthFailed))
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty)
    }

    func testUnmetPrerequisiteFailsWaitingAndNewSubscribersAndCredentialsRecover() {
        let harness = Harness(url: nil)
        harness.unmet.value = .notIdentified
        harness.subscribe("c1")
        awaitUntil(what: "waiting subscriber failed") { harness.subscribeErrors.value.count == 1 }
        harness.subscribe("c2")
        awaitUntil(what: "new subscriber failed at once") { harness.subscribeErrors.value.count == 2 }
        XCTAssertTrue(harness.subscribeErrors.value.allSatisfy {
            if case .notIdentified = $0 { return true }
            return false
        })
        XCTAssertTrue(harness.sockets.isEmpty)
        XCTAssertEqual(harness.lastState, .idle)

        harness.url.value = URL(string: "wss://realtime.test/socket")
        harness.unmet.value = nil
        harness.identityChanged()
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open()
        harness.ack("in_app_chat:conversation:c1")
        awaitUntil(what: "recovered") { harness.established.value == [false] }
        XCTAssertEqual(harness.subscribeErrors.value.count, 2)
    }

    func testUnmetPrerequisiteIsReportedWithoutWaitingForTheForeground() {
        let harness = Harness(initialForeground: false, url: nil)
        harness.unmet.value = .notIdentified
        harness.subscribe("c1")
        awaitUntil(what: "reported while backgrounded") { harness.subscribeErrors.value.count == 1 }

        harness.runtime.onForeground()
        settle(0.2)
        XCTAssertEqual(harness.subscribeErrors.value.count, 1, "foregrounding changes nothing a host must fix")
    }

    func testIdentityEndedClearsAuthVerdictsWithoutReconnecting() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "spent refresh") { harness.authRejections.value == 1 }
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }

        harness.runtime.onIdentityEnded()
        settle(0.2)
        XCTAssertEqual(harness.sockets.count, 1, "reconnecting is left to the identity change that follows")
        harness.subscribe("c2")
        awaitUntil(what: "no stale failure") { harness.lastState == .connecting }
        XCTAssertEqual(harness.sockets.count, 2, "the next subscription connects under the new identity")

        // The next identity's first token arrives as a refresh-driven install; its 4401 must still
        // earn a refresh of its own.
        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "socket 3") { harness.sockets.count == 3 }
        harness.open(2)
        harness.close(2, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "fresh refresh") { harness.authRejections.value == 2 }
    }

    func testSubscribeConnectsAndSendsChannelSubscribeOnOpen() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }
        awaitUntil(what: "SUBSCRIBE frame") {
            harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") && $0.contains("in_app_chat:conversation:c1") }
        }
    }

    func testReconnectAckReportsResubscribeButFirstAckDoesNot() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.ack("in_app_chat:conversation:c1", index: 0)
        awaitUntil(what: "first ack") { harness.established.value.count == 1 }
        XCTAssertFalse(harness.established.value[0], "first acknowledgement is not a resubscribe")

        // Connection failure → backoff → a NEW socket under a new generation.
        harness.fail(0)
        awaitUntil(what: "reconnect socket") { harness.sockets.count == 2 }
        harness.open(1)
        harness.ack("in_app_chat:conversation:c1", index: 1)
        awaitUntil(what: "second ack") { harness.established.value.count == 2 }
        XCTAssertTrue(harness.established.value[1], "an ack under a later generation IS a resubscribe")
    }

    func testLastUnsubscribeClosesSocketAndStaleCloseDoesNotReconnect() {
        let harness = Harness()
        let subscription = harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }

        subscription.unsubscribe()
        awaitUntil(what: "deliberate close") { harness.socket(0).closedCode.value == 1000 }
        // The socket's own close arrives late, stamped with the departed generation.
        harness.close(0, code: 1000, reason: "")
        settle(1.6) // longer than the first backoff step
        XCTAssertEqual(harness.sockets.count, 1, "a deliberate disconnect must not reconnect")
    }

    func testBackgroundCancelsConnectingSocketAndStaleOpenIsNotInstalled() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "connecting socket") { harness.sockets.count == 1 }

        harness.runtime.onBackground()
        awaitUntil(what: "connecting socket cancelled") { harness.socket(0).cancelled.value }

        // The connection completes anyway — after the generation moved on.
        harness.open(0)
        awaitUntil(what: "stale socket closed") { harness.socket(0).closedCode.value != nil }
        XCTAssertNotEqual(harness.lastState, .connected)
        awaitUntil(what: "suspended") { harness.lastState == .suspended }
    }

    func testTerminalClosePublishesAuthFailedFiresHookNoRetryAndIdentityChangeRevives() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "connected") { harness.lastState == .connected }

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        awaitUntil(what: "auth hook") { harness.authRejections.value == 1 }
        settle(1.6)
        XCTAssertEqual(harness.sockets.count, 1, "terminal close must not retry")

        // A fresh identity revives even a terminally-closed runtime.
        harness.identityChanged()
        awaitUntil(what: "revived socket") { harness.sockets.count == 2 }
    }

    func testTerminal4401RefreshesOnceAndSecondRejectionStaysTerminal() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "refresh hook") { harness.authRejections.value == 1 }

        // The refresh installs a token; a refresh-driven identity change earns one reconnect but
        // must not re-arm the hook.
        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "reconnect socket") { harness.sockets.count == 2 }
        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")

        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        settle(0.4)
        XCTAssertEqual(harness.authRejections.value, 1, "the second 4401 must not refresh again")
        XCTAssertEqual(harness.sockets.count, 2, "no further reconnects")
    }

    func testTerminal4403NeverRefreshesAndFailsWaitingSubscribersImmediately() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        // No refresh fixes a permission problem; without this, the conversation stays loading.
        harness.close(0, code: 4403, reason: "FORBIDDEN")
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        awaitUntil(what: "subscribe error") { harness.subscribeErrors.value.count == 1 }
        XCTAssertTrue(isSubscriptionFailed(harness.subscribeErrors.value[0]))
        settle(0.4)
        XCTAssertEqual(harness.authRejections.value, 0, "a permission problem must not burn a token refresh")
        XCTAssertEqual(harness.sockets.count, 1)
    }

    func testTerminal4401FailedRefreshFailsWaitingSubscribers() {
        let harness = Harness() // the hook reports no new token
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "subscribe error") { harness.subscribeErrors.value.count == 1 }
        XCTAssertEqual(harness.authRejections.value, 1, "the refresh was attempted first")
        XCTAssertTrue(isSubscriptionFailed(harness.subscribeErrors.value[0]))
    }

    func testTerminal4401SuccessfulRefreshDoesNotFailSubscribersUntilRejectedAgain() {
        let harness = Harness()
        // The client installs the token and recycles the socket before the hook answers.
        harness.onAuthRejectedHook.value = { completion in
            harness.identityChanged(fromAuthRefresh: true)
            completion(.refreshed)
        }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "reconnect under the refreshed token") { harness.sockets.count == 2 }
        settle(0.3)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a refresh that installs a token is not a failure")

        // The refreshed token is rejected too; the hook is spent.
        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "subscribe error") { harness.subscribeErrors.value.count == 1 }
        XCTAssertEqual(harness.authRejections.value, 1, "no second refresh")
    }

    func testTerminal4401RefreshFailingAfterBackgroundingStillFailsWaitingSubscribers() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }
        // Backgrounding recycles the socket, not the credentials; authFailed blocks the reconnect.
        harness.runtime.onBackground()
        harness.runtime.onForeground()
        settle(0.2)
        XCTAssertEqual(harness.sockets.count, 1, "no reconnect while auth-failed")

        pendingCompletion.value?(.failed) // refresh reports no new token
        awaitUntil(what: "subscribe error survives the background cycle") { harness.subscribeErrors.value.count == 1 }
    }

    func testTerminal4401RefreshFailingAfterIdentitySwitchIsStale() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }
        // The old refresh's failure must not fail the new identity's subscribers.
        harness.identityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        pendingCompletion.value?(.failed)
        settle(0.3)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a stale refresh outcome is ignored")
    }

    func testAcknowledgementReArmsTheRefreshHook() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "first refresh") { harness.authRejections.value == 1 }

        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        // The server accepts the refreshed token for real work…
        harness.ack("in_app_chat:conversation:c1", index: 1)
        awaitUntil(what: "ack processed") { harness.established.value.count == 1 }

        // …so a LATER 4401 (ordinary expiry) earns a fresh refresh cycle.
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "second refresh") { harness.authRejections.value == 2 }
    }

    func testUnacknowledgedSubscriptionTimesOutAndAnAckPreventsIt() {
        let harness = Harness(ackTimeout: 1)
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "subscribe error") { harness.subscribeErrors.value.count == 1 }
        XCTAssertTrue(isSubscriptionFailed(harness.subscribeErrors.value[0]))

        // A second conversation whose ack arrives in time never errors.
        harness.subscribe("c2")
        awaitUntil(what: "SUBSCRIBE for c2") {
            harness.socket(0).sent.value.contains { $0.contains("in_app_chat:conversation:c2") }
        }
        harness.ack("in_app_chat:conversation:c2", index: 0)
        awaitUntil(what: "ack processed") { harness.established.value.count == 1 }
        settle(1.5) // past the acked channel's deadline
        XCTAssertEqual(harness.subscribeErrors.value.count, 1, "an acked channel must not time out")
    }

    func testSocketLostBeforeAckIsAReconnectNotASubscribeError() {
        let harness = Harness(ackTimeout: 1)
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "SUBSCRIBE sent") { harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") } }

        // The connection drops before the server can acknowledge; the reconnect proves the close was
        // processed, and the deadline left pending must then elapse as a no-op.
        harness.close(0, code: 1006, reason: "network lost")
        awaitUntil(what: "reconnect socket") { harness.sockets.count == 2 }
        settle(1.2)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a socket lost mid-subscribe must not be reported as a rejected channel")
    }

    func testReopenedChannelOnALiveSocketGetsAFreshAckDeadline() {
        let harness = Harness(ackTimeout: 0.15)
        let first = harness.subscribe("c1")
        harness.subscribe("c2") // keeps the socket alive across c1's close
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open(0)
        harness.ack("in_app_chat:conversation:c1", index: 0)
        harness.ack("in_app_chat:conversation:c2", index: 0)
        awaitUntil(what: "both acked") { harness.established.value.count == 2 }
        settle(0.3)
        XCTAssertEqual(harness.subscribeErrors.value.count, 0, "acked channels never time out")

        first.unsubscribe()
        awaitUntil(what: "UNSUBSCRIBE sent") {
            harness.socket(0).sent.value.contains { $0.contains("UNSUBSCRIBE") && $0.contains("conversation:c1") }
        }
        XCTAssertNil(harness.socket(0).closedCode.value, "socket stays alive for c2")

        // Reopen c1 on the SAME connection; the server never acks this new attempt. The earlier
        // acknowledgement must not satisfy the new subscription's deadline.
        harness.subscribe("c1")
        awaitUntil(timeout: 2, what: "fresh deadline fires") { harness.subscribeErrors.value.count == 1 }
        XCTAssertTrue(isSubscriptionFailed(harness.subscribeErrors.value[0]))
        settle(0.3)
        XCTAssertEqual(harness.subscribeErrors.value.count, 1, "exactly one deadline for the new attempt")
    }

    func testEndSessionCompletesAndClosesEverything() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open()

        let ended = Atomic<Bool>(false)
        harness.runtime.endSession { ended.value = true }
        awaitUntil(what: "endSession completion") { ended.value }
        XCTAssertNotNil(harness.socket(0).closedCode.value)
        XCTAssertEqual(harness.lastState, .idle)

        // Late ingress must be a silent no-op, not a crash or a new socket.
        harness.subscribe("c2")
        settle(0.2)
        XCTAssertEqual(harness.sockets.count, 1)
    }

    func testSubscribeAfterTerminalAuthCloseSurfacesSubscriptionErrorImmediately() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.count == 1 }
        harness.open()
        harness.close(0, code: 4403, reason: "forbidden")
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }

        // With connect() refusing to run, no SUBSCRIBE frame ever goes out for c2 — the error must
        // surface now instead of leaving the conversation loading forever.
        harness.subscribe("c2")
        awaitUntil(what: "c2 surfaces a subscription error") {
            harness.subscribeErrors.value.contains {
                if case .subscriptionFailed(let message) = $0 { return message.contains("in_app_chat:conversation:c2") }
                return false
            }
        }
        XCTAssertEqual(harness.sockets.count, 1, "no new socket while auth-failed")
    }

    func testLateSubscriberOnAnAcknowledgedChannelIsEstablishedWithoutASecondSubscribe() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open()
        harness.ack("in_app_chat:conversation:c1")
        awaitUntil(what: "first ack") { harness.established.value == [false] }

        harness.subscribe("c1")
        awaitUntil(what: "newcomer established") { harness.established.value == [false, false] }
        let subscribeFrames = harness.socket(0).sent.value.filter { $0.contains("SUBSCRIBE") && !$0.contains("UNSUBSCRIBE") }
        XCTAssertEqual(subscribeFrames.count, 1, "the channel is subscribed once per connection")
    }

    func testCredentialsUnavailableStaysPublishedAcrossRuntimeEventsUntilIdentityChanges() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }

        let cause = NSError(domain: "provider", code: 7)
        harness.runtime.onCredentialsUnavailable(cause: cause, credentials: harness.credentials)
        awaitUntil(what: "authenticationFailed") { harness.lastState == .authenticationFailed(cause: cause) }

        harness.subscribe("c2")
        settle(0.3)
        XCTAssertEqual(harness.lastState, .authenticationFailed(cause: cause), "a runtime publish must not mask the credential failure")
        XCTAssertEqual(harness.sockets.count, 1, "the held token may still work: the socket is left alone")

        harness.identityChanged()
        awaitUntil(what: "recovered") { harness.lastState == .connecting }
    }

    func testCredentialsUnavailableThatIsNoLongerCurrentIsIgnored() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }

        harness.runtime.onCredentialsUnavailable(cause: nil, credentials: harness.credentials, isCurrent: { false })
        settle(0.3)
        XCTAssertEqual(harness.lastState, .connected, "a failure superseded by a newer token must not be published")
    }

    func testCredentialsUnavailableWithoutASocketFailsWaitingAndNewSubscribersUntilIdentityChanges() {
        let harness = Harness(url: nil)
        harness.subscribe("c1")
        settle(0.2)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "waiting for a token is not an error")

        harness.runtime.onCredentialsUnavailable(cause: nil, credentials: harness.credentials)
        // The error is delivered before the state is published; a poll can land between them.
        awaitUntil(what: "waiting subscriber failed and state published") {
            harness.subscribeErrors.value.count == 1 && isAuthFailed(harness.lastState)
        }

        harness.subscribe("c2")
        awaitUntil(what: "new subscriber failed at once") { harness.subscribeErrors.value.count == 2 }
        XCTAssertTrue(harness.subscribeErrors.value.allSatisfy(isSubscriptionFailed))

        harness.url.value = URL(string: "wss://realtime.test/socket")
        harness.identityChanged()
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open()
        harness.ack("in_app_chat:conversation:c1")
        awaitUntil(what: "recovered") { harness.established.value == [false] }
    }

    /// `connect()` hands the socket the only reference to its listener; a socket that does not
    /// retain it drops every open, frame and close callback on a real connection.
    func testURLSessionSocketRetainsItsListener() {
        let released = Atomic<Bool>(false)
        // One pool per block, as the runtime queue has: the autoreleased session must not pin the socket.
        autoreleasepool {
            let socket: URLSessionRealtimeSocket = {
                let listener = RetainedListener(released: released)
                return URLSessionRealtimeSocket(url: URL(string: "ws://127.0.0.1:1")!, listener: listener, pingInterval: 60)
            }()
            XCTAssertFalse(released.value, "the listener must outlive connect()")
            socket.cancel()
        }
        awaitUntil(what: "listener released with the socket") { released.value }
    }

    func testStatusResolutionDropsVerdictsAndSocketsOfReplacedCredentials() {
        let current = CredentialVersion(sessionGeneration: 2, tokenEpoch: 5)
        let olderToken = CredentialVersion(sessionGeneration: 2, tokenEpoch: 4)
        let olderIdentity = CredentialVersion(sessionGeneration: 1, tokenEpoch: 5)
        for replaced in [olderToken, olderIdentity] {
            XCTAssertNil(RealtimeStatus.authenticationFailed(cause: nil, credentials: replaced).resolve(endpointAvailable: true, awaitingToken: false, current: current))
            XCTAssertNil(RealtimeStatus.connected(credentials: replaced).resolve(endpointAvailable: true, awaitingToken: false, current: current))
            XCTAssertNil(RealtimeStatus.connecting(credentials: replaced).resolve(endpointAvailable: true, awaitingToken: false, current: current))
        }
        XCTAssertEqual(RealtimeStatus.authenticationFailed(cause: nil, credentials: current).resolve(endpointAvailable: true, awaitingToken: false, current: current), .authenticationFailed(cause: nil))
        XCTAssertEqual(RealtimeStatus.connected(credentials: current).resolve(endpointAvailable: true, awaitingToken: false, current: current), .connected)

        let waiting = RealtimeStatus.disconnected(hasSubscriptions: true)
        XCTAssertEqual(waiting.resolve(endpointAvailable: true, awaitingToken: false, current: current), .connecting)
        XCTAssertEqual(waiting.resolve(endpointAvailable: false, awaitingToken: true, current: current), .connecting)
        XCTAssertEqual(waiting.resolve(endpointAvailable: false, awaitingToken: false, current: current), .idle)
        XCTAssertEqual(
            RealtimeStatus.disconnected(hasSubscriptions: false).resolve(endpointAvailable: true, awaitingToken: false, current: current),
            .idle
        )
    }

    func testAnIdentityChangeForSupersededCredentialsIsDropped() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        let installed = harness.credentials

        // A later change moves the credentials on and its verdict lands first.
        harness.epoch.value = 1
        harness.runtime.onCredentialsUnavailable(cause: nil, credentials: harness.credentials)
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }

        harness.runtime.onIdentityChanged(fromAuthRefresh: true, credentials: installed)
        settle(0.2)
        XCTAssertTrue(isAuthFailed(harness.lastState), "a superseded install must not clear the later verdict")
        XCTAssertEqual(harness.sockets.count, 1)

        harness.identityChanged()
        awaitUntil(what: "the current change still recovers") { harness.sockets.count == 2 }
    }

    func testASupersededExplicitChangeStillReArmsTheRefreshWithoutReconnecting() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "refresh spent") { harness.authRejections.value == 1 }

        // The host sets a fresh token for the same user, then a provider refresh triggered over HTTP
        // installs another before the runtime gets to the host's command.
        harness.epoch.value = 1
        let explicit = harness.credentials
        harness.epoch.value = 2
        harness.identityChanged(fromAuthRefresh: true)
        harness.runtime.onIdentityChanged(credentials: explicit)
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        settle(0.2)
        XCTAssertEqual(harness.sockets.count, 2, "the superseded token earns no reconnect")

        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "the host's change re-armed the refresh") { harness.authRejections.value == 2 }
    }

    func testTerminalCloseFromAnOlderTokenOfTheSameIdentityIsIgnored() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "connected") { harness.lastState == .connected }

        // The same user's newer token was installed before the runtime processed this rejection.
        harness.epoch.value = 1
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "close processed") { harness.lastState != .connected }
        settle(0.2)
        XCTAssertEqual(harness.authRejections.value, 0, "a replaced token is not refreshed")
        XCTAssertFalse(harness.states.value.contains(where: isAuthFailed))
    }

    func testARefreshSkippedForReplacedCredentialsLeavesTheAttemptToTheReplacement() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }

        // An HTTP refresh installed a token between the runtime's check and the client's: the
        // client skips the provider and the install's change reconnects.
        harness.epoch.value = 1
        pendingCompletion.value?(.superseded)
        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "replacement socket") { harness.sockets.count == 2 }

        harness.onAuthRejectedHook.value = nil
        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "the replacement's own refresh") { harness.authRejections.value == 2 }
    }

    func testALateSkipNeverReturnsAnAttemptTheReplacementSpent() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in
            if pendingCompletion.value == nil { pendingCompletion.value = completion } else { completion(.failed) }
        }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }

        // The replacement's change runs first, re-arms, and its own 4401 spends the attempt.
        harness.epoch.value = 1
        harness.identityChanged()
        awaitUntil(what: "replacement socket") { harness.sockets.count == 2 }
        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "replacement spent its attempt") { harness.authRejections.value == 2 }

        // The obsolete socket's answer arrives late; it must not hand out a third attempt.
        pendingCompletion.value?(.superseded)
        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "socket 3") { harness.sockets.count == 3 }
        harness.open(2)
        harness.close(2, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "terminal") { isAuthFailed(harness.lastState) }
        settle(0.3)
        XCTAssertEqual(harness.authRejections.value, 2, "a refresh-installed token that 4401s again stays terminal")
    }

    func testARejectionSupersededAfterTheRuntimesCheckIsNeverPublished() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        // The token changes between the runtime's credential check and the client's: the client
        // sees the replacement and answers `.superseded`.
        harness.onAuthRejectedHook.value = { completion in
            harness.epoch.value = 1
            pendingCompletion.value = completion
        }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "connected") { harness.lastState == .connected }

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }
        pendingCompletion.value?(.superseded)
        settle(0.3)
        XCTAssertFalse(harness.states.value.contains(where: isAuthFailed), "the old token's failure is not the replacement's")

        harness.identityChanged(fromAuthRefresh: true)
        awaitUntil(what: "replacement socket") { harness.sockets.count == 2 }
        awaitUntil(what: "replacement connecting") { harness.lastState == .connecting }
    }

    func testARefreshFailureObsoletedByANewTokenFailsNoSubscriber() {
        let harness = Harness()
        let pendingCompletion = Atomic<((AuthRefreshOutcome) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }

        // The refresh failed, but a new token was installed before the runtime handled that.
        harness.epoch.value = 1
        pendingCompletion.value?(.failed)
        settle(0.3)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty)

        // The same failure while the rejected token is still current does reach subscribers.
        harness.identityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        pendingCompletion.value = nil
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered again") { pendingCompletion.value != nil }
        pendingCompletion.value?(.failed)
        awaitUntil(what: "current failure reported") { harness.subscribeErrors.value.count == 1 }
    }

    func testANewSubscriberNeverHearsAReplacedTokensStoredVerdict() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        harness.close(0, code: 4403, reason: "FORBIDDEN")
        awaitUntil(what: "c1 failed") { harness.subscribeErrors.value.count == 1 }

        // A new token is installed; a subscription runs before its reconnect command.
        harness.epoch.value = 1
        harness.subscribe("c2")
        settle(0.3)
        XCTAssertEqual(harness.subscribeErrors.value.count, 1, "the replaced token's rejection is not c2's")

        harness.identityChanged()
        awaitUntil(what: "socket under the new token") { harness.sockets.count == 2 }
    }

    func testANewSubscriberNeverHearsAReplacedTokensCredentialFailure() {
        let harness = Harness(url: nil)
        harness.subscribe("c1")
        harness.runtime.onCredentialsUnavailable(cause: nil, credentials: harness.credentials)
        awaitUntil(what: "c1 failed") { harness.subscribeErrors.value.count == 1 }

        harness.epoch.value = 1
        harness.subscribe("c2")
        settle(0.3)
        XCTAssertEqual(harness.subscribeErrors.value.count, 1, "the failed load belonged to the replaced credentials")

        // While the verdict is current, a newcomer does hear it.
        harness.runtime.onCredentialsUnavailable(cause: nil, credentials: harness.credentials)
        harness.subscribe("c3")
        awaitUntil(what: "c1, c2 and c3 failed under the current credentials") { harness.subscribeErrors.value.count == 4 }
    }

    func testAnAcknowledgementDeadlineOfAReplacedTokensSocketReportsNothing() {
        let harness = Harness(ackTimeout: 0.4)
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "SUBSCRIBE sent") { harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") } }

        // A new token is installed; its reconnect has not run when the old deadline elapses.
        harness.epoch.value = 1
        settle(0.8)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "the old socket's timeout is not the replacement's")

        // The replacement socket gets its own deadline, which does report.
        harness.identityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        awaitUntil(what: "the replacement's own deadline") { harness.subscribeErrors.value.count == 1 }
    }

    func testASocketThatOpensAfterItsTokenWasReplacedIsClosedWithoutSubscribing() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "connecting socket") { harness.sockets.count == 1 }

        harness.epoch.value = 1
        harness.open(0)
        awaitUntil(what: "stale socket dropped") { harness.socket(0).cancelled.value }
        XCTAssertFalse(harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") }, "the old token is not spent on a subscription")
        XCTAssertNotEqual(harness.lastState, .connected)

        harness.identityChanged()
        awaitUntil(what: "socket under the new token") { harness.sockets.count == 2 }
        harness.open(1)
        awaitUntil(what: "connected") { harness.lastState == .connected }
    }

    func testALateSubscriberNeverUsesAReplacedTokensSocket() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        harness.ack("in_app_chat:conversation:c1", index: 0)
        awaitUntil(what: "first ack") { harness.established.value == [false] }

        // A new token is installed; subscriptions run before its reconnect.
        harness.epoch.value = 1
        harness.subscribe("c1")
        harness.subscribe("c2")
        settle(0.3)
        XCTAssertEqual(harness.established.value, [false], "the old socket's acknowledgement is not reused")
        XCTAssertFalse(harness.socket(0).sent.value.contains { $0.contains("conversation:c2") }, "no SUBSCRIBE over the old token")
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty)

        // Both newcomers stay registered: the replacement subscribes and acknowledges them.
        harness.identityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        awaitUntil(what: "both channels subscribed on the replacement") {
            let sent = harness.socket(1).sent.value
            return sent.contains { $0.contains("conversation:c1") } && sent.contains { $0.contains("conversation:c2") }
        }
        harness.ack("in_app_chat:conversation:c1", index: 1)
        harness.ack("in_app_chat:conversation:c2", index: 1)
        awaitUntil(what: "every handle established on the replacement") { harness.established.value.count == 4 }
    }

    func testFramesFromAReplacedTokensSocketAreNotDispatched() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket") { harness.sockets.count == 1 }
        harness.open(0)
        awaitUntil(what: "SUBSCRIBE sent") { harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") } }

        // A new token is installed; the old socket keeps talking before the reconnect runs.
        harness.epoch.value = 1
        harness.ack("in_app_chat:conversation:c1", index: 0)
        harness.listener(0).socket(harness.socket(0), didReceiveText:
            #"{"type":"IN_APP_CHAT_MESSAGE","data":{"id":"m1","externalUid":"e1","conversationId":"c1"}}"#)
        settle(0.3)
        XCTAssertTrue(harness.established.value.isEmpty, "the old socket's acknowledgement is not the replacement's")
        XCTAssertEqual(harness.frames.value, 0)

        harness.identityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.count == 2 }
        harness.open(1)
        harness.ack("in_app_chat:conversation:c1", index: 1)
        awaitUntil(what: "the replacement's acknowledgement") { harness.established.value == [false] }
        harness.listener(1).socket(harness.socket(1), didReceiveText:
            #"{"type":"IN_APP_CHAT_MESSAGE","data":{"id":"m1","externalUid":"e1","conversationId":"c1"}}"#)
        awaitUntil(what: "the replacement's frame") { harness.frames.value == 1 }
    }

    func testChatChannelNameAndTerminalCodeRange() {
        XCTAssertEqual(RealtimeRuntime.chatChannelName(conversationId: "abc"), "in_app_chat:conversation:abc")
        XCTAssertTrue(RealtimeRuntime.isTerminalCloseCode(4400))
        XCTAssertTrue(RealtimeRuntime.isTerminalCloseCode(4499))
        XCTAssertFalse(RealtimeRuntime.isTerminalCloseCode(1006))
        XCTAssertFalse(RealtimeRuntime.isTerminalCloseCode(4500))
    }
}
