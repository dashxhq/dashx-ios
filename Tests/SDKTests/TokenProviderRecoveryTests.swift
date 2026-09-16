import XCTest
@testable import DashX

/// Drives the token-provider machinery through the client's public surface — no configure(), no
/// network. No realtime runtime exists, so identity installs publish `.idle` directly.
final class TokenProviderRecoveryTests: XCTestCase {
    private var client: DashXClient { DashXClient.instance }
    private var uid = ""

    override func setUp() {
        super.setUp()
        uid = "user-" + UUID().uuidString
        // Cycle through a real identity so the clear is a genuine T2 (setIdentity(nil, nil) on an
        // already-clean account is a no-op that would leave a previous test's state standing).
        client.setIdentity(uid: "isolation-\(uid)", token: "isolation-token")
        client.setIdentity(uid: nil, token: nil)
        XCTAssertEqual(client.connectionState, .idle)
    }

    override func tearDown() {
        client.setIdentity(uid: nil, token: nil)
        super.tearDown()
    }

    private func isAuthFailed(_ state: DashXConnectionState) -> Bool {
        if case .authenticationFailed = state { return true }
        return false
    }

    private func refresh() -> Bool {
        let outcome = Atomic<Bool?>(nil)
        client.awaitTokenRefresh { outcome.value = $0 }
        awaitUntil(what: "refresh completes") { outcome.value != nil }
        return outcome.value ?? false
    }

    func testProviderReportingUnavailableClearsTheSingleFlightSlot() {
        client.setIdentity(uid: uid, token: "cached-token")
        let calls = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            _ = calls.increment()
            callback.onUnavailable(nil)
        })

        // Both refreshes must terminate: a leaked in-flight slot would hang the second on the
        // first load's never-completed result.
        XCTAssertFalse(refresh())
        XCTAssertFalse(refresh())
        XCTAssertEqual(calls.value, 2, "each refresh must reach the provider")
        awaitUntil(what: "authenticationFailed") { self.isAuthFailed(self.client.connectionState) }
    }

    func testRegisteringProviderAfterAuthFailureForcesARefresh() {
        client.setIdentity(uid: uid, token: "rejected-token")
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onUnavailable(nil)
        })
        XCTAssertFalse(refresh())
        awaitUntil(what: "authenticationFailed") { self.isAuthFailed(self.client.connectionState) }

        // Re-registering under authenticationFailed is the host's retry gesture: it must load
        // immediately, with forceRefresh — the cached token is exactly the rejected one.
        let seenForceRefresh = Atomic<Bool?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            seenForceRefresh.value = forceRefresh
            callback.onToken("fresh-token")
        })

        awaitUntil(what: "fresh token installed") { self.client.account.identityToken == "fresh-token" }
        XCTAssertEqual(seenForceRefresh.value, true)
        awaitUntil(what: "recovered to idle") { self.client.connectionState == .idle }
    }

    func testExplicitTokenSupersedesAnInFlightLoad() {
        client.setIdentity(uid: uid, token: "t0")
        let pending = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            pending.value = callback
        })

        let outcome = Atomic<Bool?>(nil)
        client.awaitTokenRefresh { outcome.value = $0 }
        awaitUntil(what: "provider invoked") { pending.value != nil }

        client.setIdentity(uid: uid, token: "explicit-t9") // T1 while the load is in flight

        // The awaiting retry gets the explicit token, and the late provider result is stale under
        // the bumped token epoch — it must never overwrite t9.
        awaitUntil(what: "refresh resolves") { outcome.value != nil }
        XCTAssertEqual(outcome.value, true)
        pending.value?.onToken("stale-late-token")
        settle(0.3)
        XCTAssertEqual(client.account.identityToken, "explicit-t9")
    }

    func testReplacedProviderInvalidatesThePredecessorsInFlightLoad() {
        let firstPending = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in // T0: load starts
            firstPending.value = callback
        })
        awaitUntil(what: "first provider invoked") { firstPending.value != nil }
        XCTAssertEqual(client.connectionState, .connecting)

        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("second-provider-token")
        })

        awaitUntil(what: "second provider's token") { self.client.account.identityToken == "second-provider-token" }
        firstPending.value?.onToken("first-provider-token")
        settle(0.3)
        XCTAssertEqual(client.account.identityToken, "second-provider-token", "the replaced provider's late result must not install")
        XCTAssertEqual(client.account.uid, uid)
    }

    func testResetEndsTheProviderSessionAndReturnsToIdle() {
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("provider-token")
        })
        awaitUntil(what: "token installed") { self.client.account.identityToken == "provider-token" }

        client.reset()
        XCTAssertNil(client.account.uid)
        XCTAssertFalse(client.hasIdentityToken)
        XCTAssertEqual(client.connectionState, .idle)
        XCTAssertFalse(refresh(), "no provider is bound after reset")
    }
}
