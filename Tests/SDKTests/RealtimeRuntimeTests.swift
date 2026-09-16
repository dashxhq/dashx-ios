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

/// Drives the actor through the socket-factory seam; no network.
private final class Harness {
    let states = Atomic<[DashXConnectionState]>([])
    let authRejections = Atomic<Int>(0)
    let sockets = Atomic<[FakeSocket]>([])
    let listeners = Atomic<[RealtimeSocketListener]>([])
    let established = Atomic<[Bool]>([])
    let subscribeErrors = Atomic<[DashXClientError]>([])
    /// What the 4401 hook reports when no custom hook is installed.
    let authRefreshSucceeds = Atomic<Bool>(false)
    /// Custom hook: receives the completion and decides when (and what) to answer.
    let onAuthRejectedHook = Atomic<((@escaping (Bool) -> Void) -> Void)?>(nil)
    let url = Atomic<URL?>(URL(string: "wss://realtime.test/socket"))

    let runtime: RealtimeRuntime

    init(initialForeground: Bool = true, url: URL? = URL(string: "wss://realtime.test/socket"), ackTimeout: TimeInterval = 60) {
        self.url.value = url
        var runtime: RealtimeRuntime!
        let harnessBox = Atomic<Harness?>(nil)
        runtime = RealtimeRuntime(
            urlProvider: { harnessBox.value?.url.value },
            onAnyFrame: { _ in },
            onAuthRejected: { completion in
                guard let harness = harnessBox.value else { return completion(false) }
                _ = harness.authRejections.increment()
                if let hook = harness.onAuthRejectedHook.value {
                    hook(completion)
                } else {
                    completion(harness.authRefreshSucceeds.value)
                }
            },
            publishState: { state in harnessBox.value?.states.append(state) },
            initialForeground: initialForeground,
            socketFactory: { url, listener in
                let socket = FakeSocket(url: url)
                harnessBox.value?.sockets.append(socket)
                harnessBox.value?.listeners.append(listener)
                return socket
            },
            ackTimeout: ackTimeout
        )
        self.runtime = runtime
        harnessBox.value = self
    }

    var lastState: DashXConnectionState? { states.value.last }

    @discardableResult
    func subscribe(_ conversationId: String = "c1") -> DashXRealtimeSubscription {
        runtime.subscribe(SubscriberHandle(
            channelName: RealtimeRuntime.chatChannelName(conversationId: conversationId),
            onFrame: { _ in },
            onEstablished: { [established] in established.append($0) },
            onSubscribeError: { [subscribeErrors] in subscribeErrors.append($0) }
        ))
    }

    func socket(_ index: Int) -> FakeSocket { sockets.value[index] }
    func listener(_ index: Int) -> RealtimeSocketListener { listeners.value[index] }

    func open(_ index: Int? = nil) {
        let i = index ?? (sockets.value.count - 1)
        listener(i).socketDidOpen(socket(i))
    }

    func ack(_ channel: String, index: Int? = nil) {
        let i = index ?? (listeners.value.count - 1)
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

    func testSubscribeWithoutIdentityOpensNoSocketStaysIdle() {
        let harness = Harness(url: nil)
        harness.subscribe()
        settle(0.3)
        XCTAssertTrue(harness.sockets.value.isEmpty, "no speculative connect without an identity token")
        XCTAssertEqual(harness.lastState ?? .idle, .idle)
    }

    func testSubscribeConnectsAndSendsChannelSubscribeOnOpen() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }
        awaitUntil(what: "SUBSCRIBE frame") {
            harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") && $0.contains("in_app_chat:conversation:c1") }
        }
    }

    func testReconnectAckReportsResubscribeButFirstAckDoesNot() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)
        harness.ack("in_app_chat:conversation:c1", index: 0)
        awaitUntil(what: "first ack") { harness.established.value.count == 1 }
        XCTAssertFalse(harness.established.value[0], "first acknowledgement is not a resubscribe")

        // Connection failure → backoff → a NEW socket under a new generation.
        harness.fail(0)
        awaitUntil(what: "reconnect socket") { harness.sockets.value.count == 2 }
        harness.open(1)
        harness.ack("in_app_chat:conversation:c1", index: 1)
        awaitUntil(what: "second ack") { harness.established.value.count == 2 }
        XCTAssertTrue(harness.established.value[1], "an ack under a later generation IS a resubscribe")
    }

    func testLastUnsubscribeClosesSocketAndStaleCloseDoesNotReconnect() {
        let harness = Harness()
        let subscription = harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
        harness.open()
        awaitUntil(what: "connected") { harness.lastState == .connected }

        subscription.unsubscribe()
        awaitUntil(what: "deliberate close") { harness.socket(0).closedCode.value == 1000 }
        // The socket's own close arrives late, stamped with the departed generation.
        harness.close(0, code: 1000, reason: "")
        settle(1.6) // longer than the first backoff step
        XCTAssertEqual(harness.sockets.value.count, 1, "a deliberate disconnect must not reconnect")
    }

    func testBackgroundCancelsConnectingSocketAndStaleOpenIsNotInstalled() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "connecting socket") { harness.sockets.value.count == 1 }

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
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)
        awaitUntil(what: "connected") { harness.lastState == .connected }

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        awaitUntil(what: "auth hook") { harness.authRejections.value == 1 }
        settle(1.6)
        XCTAssertEqual(harness.sockets.value.count, 1, "terminal close must not retry")

        // A fresh identity revives even a terminally-closed runtime.
        harness.runtime.onIdentityChanged()
        awaitUntil(what: "revived socket") { harness.sockets.value.count == 2 }
    }

    func testTerminal4401RefreshesOnceAndSecondRejectionStaysTerminal() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "refresh hook") { harness.authRejections.value == 1 }

        // The refresh installs a token; a refresh-driven identity change earns one reconnect but
        // must not re-arm the hook.
        harness.runtime.onIdentityChanged(fromAuthRefresh: true)
        awaitUntil(what: "reconnect socket") { harness.sockets.value.count == 2 }
        harness.open(1)
        harness.close(1, code: 4401, reason: "UNAUTHORIZED")

        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        settle(0.4)
        XCTAssertEqual(harness.authRejections.value, 1, "the second 4401 must not refresh again")
        XCTAssertEqual(harness.sockets.value.count, 2, "no further reconnects")
    }

    func testTerminal4403NeverRefreshesAndFailsWaitingSubscribersImmediately() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)

        // No refresh fixes a permission problem; without this, the conversation stays loading.
        harness.close(0, code: 4403, reason: "FORBIDDEN")
        awaitUntil(what: "authenticationFailed") { isAuthFailed(harness.lastState) }
        awaitUntil(what: "subscribe error") { harness.subscribeErrors.value.count == 1 }
        XCTAssertTrue(isSubscriptionFailed(harness.subscribeErrors.value[0]))
        settle(0.4)
        XCTAssertEqual(harness.authRejections.value, 0, "a permission problem must not burn a token refresh")
        XCTAssertEqual(harness.sockets.value.count, 1)
    }

    func testTerminal4401FailedRefreshFailsWaitingSubscribers() {
        let harness = Harness() // the hook reports no new token
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
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
            harness.runtime.onIdentityChanged(fromAuthRefresh: true)
            completion(true)
        }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "reconnect under the refreshed token") { harness.sockets.value.count == 2 }
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
        let pendingCompletion = Atomic<((Bool) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }
        // Backgrounding recycles the socket, not the credentials; authFailed blocks the reconnect.
        harness.runtime.onBackground()
        harness.runtime.onForeground()
        settle(0.2)
        XCTAssertEqual(harness.sockets.value.count, 1, "no reconnect while auth-failed")

        pendingCompletion.value?(false) // refresh reports no new token
        awaitUntil(what: "subscribe error survives the background cycle") { harness.subscribeErrors.value.count == 1 }
    }

    func testTerminal4401RefreshFailingAfterIdentitySwitchIsStale() {
        let harness = Harness()
        let pendingCompletion = Atomic<((Bool) -> Void)?>(nil)
        harness.onAuthRejectedHook.value = { completion in pendingCompletion.value = completion }
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)

        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "hook entered") { pendingCompletion.value != nil }
        // The old refresh's failure must not fail the new identity's subscribers.
        harness.runtime.onIdentityChanged()
        awaitUntil(what: "socket 2") { harness.sockets.value.count == 2 }
        harness.open(1)
        pendingCompletion.value?(false)
        settle(0.3)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a stale refresh outcome is ignored")
    }

    func testAcknowledgementReArmsTheRefreshHook() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket 1") { harness.sockets.value.count == 1 }
        harness.open(0)
        harness.close(0, code: 4401, reason: "UNAUTHORIZED")
        awaitUntil(what: "first refresh") { harness.authRejections.value == 1 }

        harness.runtime.onIdentityChanged(fromAuthRefresh: true)
        awaitUntil(what: "socket 2") { harness.sockets.value.count == 2 }
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
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
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
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
        harness.open(0)
        awaitUntil(what: "SUBSCRIBE sent") { harness.socket(0).sent.value.contains { $0.contains("SUBSCRIBE") } }

        // The connection drops before the server can acknowledge; the reconnect proves the close was
        // processed, and the deadline left pending must then elapse as a no-op.
        harness.close(0, code: 1006, reason: "network lost")
        awaitUntil(what: "reconnect socket") { harness.sockets.value.count == 2 }
        settle(1.2)
        XCTAssertTrue(harness.subscribeErrors.value.isEmpty, "a socket lost mid-subscribe must not be reported as a rejected channel")
    }

    func testReopenedChannelOnALiveSocketGetsAFreshAckDeadline() {
        let harness = Harness(ackTimeout: 0.15)
        let first = harness.subscribe("c1")
        harness.subscribe("c2") // keeps the socket alive across c1's close
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
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
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
        harness.open()

        let ended = Atomic<Bool>(false)
        harness.runtime.endSession { ended.value = true }
        awaitUntil(what: "endSession completion") { ended.value }
        XCTAssertNotNil(harness.socket(0).closedCode.value)
        XCTAssertEqual(harness.lastState, .idle)

        // Late ingress must be a silent no-op, not a crash or a new socket.
        harness.subscribe("c2")
        settle(0.2)
        XCTAssertEqual(harness.sockets.value.count, 1)
    }

    func testSubscribeAfterTerminalAuthCloseSurfacesSubscriptionErrorImmediately() {
        let harness = Harness()
        harness.subscribe("c1")
        awaitUntil(what: "socket created") { harness.sockets.value.count == 1 }
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
        XCTAssertEqual(harness.sockets.value.count, 1, "no new socket while auth-failed")
    }

    func testChatChannelNameAndTerminalCodeRange() {
        XCTAssertEqual(RealtimeRuntime.chatChannelName(conversationId: "abc"), "in_app_chat:conversation:abc")
        XCTAssertTrue(RealtimeRuntime.isTerminalCloseCode(4400))
        XCTAssertTrue(RealtimeRuntime.isTerminalCloseCode(4499))
        XCTAssertFalse(RealtimeRuntime.isTerminalCloseCode(1006))
        XCTAssertFalse(RealtimeRuntime.isTerminalCloseCode(4500))
    }
}
