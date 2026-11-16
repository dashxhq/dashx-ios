import XCTest
@testable import DashX

/// Drives the token-provider machinery through the client's public surface — no configure(), no
/// network. No realtime runtime exists outside a `RealtimeSeam`, so identity installs publish
/// `.idle` directly.
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

    func testProviderInstallAdvancesTheTokenEpoch() {
        let before = client.account.tokenEpoch
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("provider-token")
        })
        awaitUntil(what: "token installed") { self.client.account.identityToken == "provider-token" }
        XCTAssertGreaterThan(client.account.tokenEpoch, before, "a load begun before the install is stale under the new epoch")
        XCTAssertEqual(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN), "provider-token")
        XCTAssertEqual(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID), uid)
    }

    func testProviderSwitchGivesTheNextUserTheirOwnRealtimeRefreshAndNoStaleFailure() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }

        let forcedLoadsA = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            if forceRefresh {
                _ = forcedLoadsA.increment()
                callback.onUnavailable(nil)
            } else {
                callback.onToken("token-a")
            }
        })
        awaitUntil(what: "A's token") { self.client.account.identityToken == "token-a" }
        let leaseA = client.chat(chatIdentityId: "identity-a").openConversation("conversation-a")
        awaitUntil(what: "A's socket") { realtime.connections.value.count == 1 }
        realtime.open(0)
        realtime.close(0, code: 4401)
        awaitUntil(what: "A's refresh spent and failed") {
            forcedLoadsA.value == 1 && self.isAuthFailed(self.client.connectionState)
        }

        let recorder = StateRecorder()
        client.addConnectionStateListener(recorder)
        defer { client.removeConnectionStateListener(recorder) }

        let forcedLoadsB = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { forceRefresh, callback in
            if forceRefresh {
                _ = forcedLoadsB.increment()
                callback.onToken("token-b2")
            } else {
                callback.onToken("token-b")
            }
        })
        awaitUntil(what: "B's token") { self.client.account.identityToken == "token-b" }
        if case .error(.sessionEnded) = leaseA.state {} else { XCTFail("A's lease ends with A's identity") }

        let leaseB = client.chat(chatIdentityId: "identity-b").openConversation("conversation-b")
        awaitUntil(what: "B's socket") { realtime.connections.value.count == 2 }
        settle(0.2)
        XCTAssertFalse(recorder.states.value.contains(where: isAuthFailed), "A's failure must not be republished for B")

        realtime.open(1)
        realtime.close(1, code: 4401)
        awaitUntil(what: "B's own refresh") { forcedLoadsB.value == 1 }
        awaitUntil(what: "B reconnects under the refreshed token") { realtime.connections.value.count == 3 }
        XCTAssertEqual(client.account.identityToken, "token-b2")
        leaseB.close()
    }

    func testARejectionQueuedBeforeAProviderSwitchNeverReachesTheNextUser() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }

        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            callback.onToken(forceRefresh ? "token-a2" : "token-a")
        })
        awaitUntil(what: "A's token") { self.client.account.identityToken == "token-a" }
        _ = client.chat(chatIdentityId: "identity-a").openConversation("conversation-a")
        awaitUntil(what: "A's socket") { realtime.connections.value.count == 1 }

        // Hold the runtime inside the open's SUBSCRIBE so A's 4401 queues ahead of the switch.
        let release = DispatchSemaphore(value: 0)
        realtime.blockNextSend.value = release
        realtime.open(0)
        awaitUntil(what: "runtime held") { realtime.sendBlocked.value }
        realtime.close(0, code: 4401)

        let recorder = StateRecorder()
        client.addConnectionStateListener(recorder)
        defer { client.removeConnectionStateListener(recorder) }
        let forcedLoadsB = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { forceRefresh, callback in
            if forceRefresh { _ = forcedLoadsB.increment() }
            callback.onToken(forceRefresh ? "token-b2" : "token-b")
        })
        awaitUntil(what: "B's token") { self.client.account.identityToken == "token-b" }

        release.signal()
        settle(0.4)
        XCTAssertEqual(forcedLoadsB.value, 0, "A's rejection must not spend B's refresh")
        XCTAssertEqual(client.account.identityToken, "token-b")
        XCTAssertFalse(recorder.states.value.contains(where: isAuthFailed), "A's rejection must not be published for B")
    }

    func testOpeningAConversationWithoutConfigureReportsTheMissingConfiguration() {
        // No configure(): no public key, and lifecycle observation never started.
        let realtime = RealtimeSeam(client, publicKey: nil, foreground: false)
        defer { realtime.restore() }
        client.setIdentity(uid: uid, token: "token")

        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "missing configuration surfaces") {
            if case .error(.customError(let message)) = lease.state { return message.contains("configure()") }
            return false
        }
        XCTAssertTrue(realtime.connections.value.isEmpty)
        lease.close()
    }

    func testOpeningAConversationDuringTheFirstProviderLoadReportsConnecting() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        let pending = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            pending.value = callback
        })
        awaitUntil(what: "provider invoked") { pending.value != nil }

        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        settle(0.3)
        if case .loading = lease.state {} else { XCTFail("a token on its way is not an error") }
        XCTAssertEqual(client.connectionState, .connecting)
        XCTAssertTrue(realtime.connections.value.isEmpty)

        pending.value?.onToken("provider-token")
        awaitUntil(what: "socket under the loaded token") { realtime.connections.value.count == 1 }
        lease.close()
    }

    func testAnEarlierIdentitysRefreshRequestNeverReachesTheCurrentProvider() {
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            callback.onToken(forceRefresh ? "token-a2" : "token-a")
        })
        awaitUntil(what: "A's token") { self.client.account.identityToken == "token-a" }
        let versionA = client.account.credentialVersion

        let forcedLoadsB = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { forceRefresh, callback in
            if forceRefresh { _ = forcedLoadsB.increment() }
            callback.onToken(forceRefresh ? "token-b2" : "token-b")
        })
        awaitUntil(what: "B's token") { self.client.account.identityToken == "token-b" }

        // A's GraphQL retry and A's socket ask for a refresh only after the switch has landed.
        let retried = Atomic<Bool?>(nil)
        client.awaitTokenRefresh(expected: versionA) { retried.value = $0 }
        let rejected = Atomic<AuthRefreshOutcome?>(nil)
        client.onRealtimeAuthRejected(credentials: versionA) { rejected.value = $0 }
        awaitUntil(what: "both answered") { retried.value != nil && rejected.value != nil }
        XCTAssertEqual(retried.value, false)
        XCTAssertEqual(rejected.value, .superseded)
        settle(0.2)
        XCTAssertEqual(forcedLoadsB.value, 0, "B's provider is never asked on A's behalf")
        XCTAssertFalse(isAuthFailed(client.connectionState))

        let current = Atomic<AuthRefreshOutcome?>(nil)
        client.onRealtimeAuthRejected(credentials: client.account.credentialVersion) { current.value = $0 }
        awaitUntil(what: "B's own refresh") { current.value != nil }
        XCTAssertEqual(current.value, .refreshed)
        XCTAssertEqual(forcedLoadsB.value, 1)
    }

    func testARejectionOfAReplacedTokenNeitherRefreshesNorFailsTheNewOne() {
        let forcedLoads = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            if forceRefresh { _ = forcedLoads.increment() }
            callback.onToken(forceRefresh ? "provider-forced" : "provider-token")
        })
        awaitUntil(what: "provider token") { self.client.account.identityToken == "provider-token" }
        let rejectedVersion = client.account.credentialVersion

        // The host installs a token for the same user; the old token's rejections arrive after.
        client.setIdentity(uid: uid, token: "explicit-token")
        let rejected = Atomic<AuthRefreshOutcome?>(nil)
        client.onRealtimeAuthRejected(credentials: rejectedVersion) { rejected.value = $0 }
        let retried = Atomic<Bool?>(nil)
        client.awaitTokenRefresh(expected: rejectedVersion) { retried.value = $0 }
        awaitUntil(what: "both answered") { rejected.value != nil && retried.value != nil }

        XCTAssertEqual(rejected.value, .superseded, "a newer token is already installed")
        XCTAssertEqual(retried.value, true, "the HTTP retry uses the newer token")
        settle(0.2)
        XCTAssertEqual(forcedLoads.value, 0, "the provider is not asked to replace the explicit token")
        XCTAssertEqual(client.account.identityToken, "explicit-token")
        XCTAssertFalse(isAuthFailed(client.connectionState))
    }

    func testAnEarlierIdentitysRejectionWithoutAProviderPublishesNothing() {
        client.setIdentity(uid: uid, token: "token-a")
        let versionA = client.account.credentialVersion
        client.setIdentity(uid: uid + "-b", token: "token-b")

        let stale = Atomic<AuthRefreshOutcome?>(nil)
        client.onRealtimeAuthRejected(credentials: versionA) { stale.value = $0 }
        awaitUntil(what: "stale answered") { stale.value != nil }
        settle(0.2)
        XCTAssertFalse(isAuthFailed(client.connectionState), "A's rejection is not B's failure")

        let current = Atomic<AuthRefreshOutcome?>(nil)
        client.onRealtimeAuthRejected(credentials: client.account.credentialVersion) { current.value = $0 }
        awaitUntil(what: "B's rejection published") { self.isAuthFailed(self.client.connectionState) }
        XCTAssertEqual(current.value, .failed, "no provider can refresh B")
    }

    func testARuntimeVerdictOfAnEarlierIdentityIsNotPublished() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: uid, token: "token")
        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "socket") { realtime.connections.value.count == 1 }
        guard let runtime = client.realtimeRuntime else { return XCTFail("runtime") }

        let current = client.account.credentialVersion
        runtime.onCredentialsUnavailable(
            cause: nil,
            credentials: CredentialVersion(sessionGeneration: current.sessionGeneration - 1, tokenEpoch: current.tokenEpoch)
        )
        settle(0.3)
        XCTAssertFalse(isAuthFailed(client.connectionState))

        runtime.onCredentialsUnavailable(cause: nil, credentials: client.account.credentialVersion)
        awaitUntil(what: "current verdict published") { self.isAuthFailed(self.client.connectionState) }
        lease.close()
    }

    func testAProviderSwitchWithTheRuntimeBusyKeepsReportingConnecting() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("token-a")
        })
        awaitUntil(what: "A's token") { self.client.account.identityToken == "token-a" }
        _ = client.chat(chatIdentityId: "identity-a").openConversation("conversation-a")
        awaitUntil(what: "A's socket") { realtime.connections.value.count == 1 }

        // A's open, A's unsubscribe and the switch's reset all queue behind the held runtime.
        let release = DispatchSemaphore(value: 0)
        realtime.blockNextSend.value = release
        realtime.open(0)
        awaitUntil(what: "runtime held") { realtime.sendBlocked.value }

        let recorder = StateRecorder()
        client.addConnectionStateListener(recorder)
        defer { client.removeConnectionStateListener(recorder) }
        let pendingB = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { _, callback in
            pendingB.value = callback
        })
        release.signal()
        settle(0.4)

        XCTAssertEqual(client.connectionState, .connecting, "B's token is on its way")
        XCTAssertFalse(recorder.states.value.contains(.idle), "a resolution between commit and load must not read idle")
        XCTAssertFalse(recorder.states.value.contains(.connected), "A's socket opening is not B's connection")
        pendingB.value?.onToken("token-b")
    }

    func testARealtimeBaseURIThatIsNotAnAbsoluteWebSocketURLIsReportedNotAwaitedOrOpened() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: uid, token: "token")

        // Unparseable, relative, the wrong scheme, no host: none may reach the socket factory,
        // where URLSession raises an exception for a non-WebSocket URL.
        for (index, base) in ["wss://[broken", "staging.example.com", "https://realtime.example.com", "wss://"].enumerated() {
            client.setRealtimeBaseURI(base)
            let lease = client.chat(chatIdentityId: "identity").openConversation("conversation-\(index)")
            awaitUntil(what: "\(base) surfaces") {
                if case .error(.customError(let message)) = lease.state { return message.contains("setRealtimeBaseURI") }
                return false
            }
            settle(0.1)
            XCTAssertEqual(client.connectionState, .idle, "nothing will start a socket for \(base)")
            lease.close()
        }
        XCTAssertTrue(realtime.connections.value.isEmpty)

        client.setRealtimeBaseURI("WSS://realtime.example.com")
        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation-valid")
        awaitUntil(what: "a valid override connects, whatever the scheme's case") { realtime.connections.value.count == 1 }
        lease.close()
    }

    func testAnUppercaseSchemeOverrideBuildsAURLTheRealSocketAccepts() {
        let previousPublicKey = ConfigInterceptor.shared.publicKey
        ConfigInterceptor.shared.publicKey = "public-key-test"
        defer {
            ConfigInterceptor.shared.publicKey = previousPublicKey
            client.setRealtimeBaseURI(nil)
        }
        client.setIdentity(uid: uid, token: "token")
        client.setRealtimeBaseURI("WSS://realtime.example.com/socket?publicKey=stale&region=eu&identityToken=old&accountToken=foreign")

        guard let endpoint = client.realtimeEndpoint() else { return XCTFail("a valid override must form an endpoint") }
        XCTAssertEqual(endpoint.url.scheme, "wss")
        XCTAssertEqual(endpoint.url.host, "realtime.example.com")
        XCTAssertEqual(endpoint.url.path, "/socket")
        // SDK-owned items are replaced, not duplicated; unrelated ones survive.
        let items = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.filter { $0.name == "publicKey" }.map(\.value), ["public-key-test"])
        XCTAssertEqual(items.filter { $0.name == "identityToken" }.map(\.value), ["token"])
        XCTAssertEqual(items.filter { $0.name == "region" }.map(\.value), ["eu"])
        XCTAssertFalse(items.contains { $0.name == "accountToken" }, "an override must not outrank the SDK identity")

        // URLSession raises an uncaught exception for a WebSocket URL it rejects; the fake sockets
        // elsewhere never reach it, so this builds the real one.
        let socket = URLSessionRealtimeSocket(url: endpoint.url, listener: SilentListener(), pingInterval: 60)
        socket.cancel()
    }

    func testAResetPublishingLateNeverOverwritesAProviderActivationsConnecting() {
        client.setIdentity(uid: uid, token: "token-a")
        client.reset()
        let committedReset = client.account
        let pending = Atomic<DashXTokenCallback?>(nil)
        // Activation from the signed-out account: the uid changes, the generation and epoch do not.
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            pending.value = callback
        })
        awaitUntil(what: "load started") { pending.value != nil }
        XCTAssertEqual(client.connectionState, .connecting)

        client.publishIdle(ifCurrent: committedReset)
        XCTAssertEqual(client.connectionState, .connecting, "the reset's late idle must not hide the token load")

        pending.value?.onToken("token")
        awaitUntil(what: "the load's own completion publishes idle") { self.client.connectionState == .idle }
    }

    func testALateTokenInstallCommandCannotClearTheNextUsersFailure() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("token-a")
        })
        awaitUntil(what: "A's token") { self.client.account.identityToken == "token-a" }
        let installedA = client.account.credentialVersion
        _ = client.chat(chatIdentityId: "identity-a").openConversation("conversation-a")
        awaitUntil(what: "A's socket") { realtime.connections.value.count == 1 }

        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { _, callback in
            callback.onUnavailable(nil)
        })
        awaitUntil(what: "B's failure") { self.isAuthFailed(self.client.connectionState) }

        // A's install command, paused after A's unlock, reaches the runtime only now.
        guard let runtime = client.realtimeRuntime else { return XCTFail("runtime") }
        runtime.onIdentityChanged(fromAuthRefresh: true, credentials: installedA)
        settle(0.3)
        XCTAssertTrue(isAuthFailed(client.connectionState), "B's failure stands")
    }

    func testConnectionStateListenersHearTransitionsInWriteOrder() {
        let recorder = StateRecorder()
        client.addConnectionStateListener(recorder)
        defer { client.removeConnectionStateListener(recorder) }
        client.publishDirect(.idle)
        settle(0.1)
        recorder.states.value = []

        DispatchQueue.concurrentPerform(iterations: 4000) { index in
            self.client.publishDirect(index % 2 == 0 ? .connecting : .idle)
        }
        settle(0.5)

        let heard = recorder.states.value
        XCTAssertFalse(heard.isEmpty)
        XCTAssertEqual(heard.last, client.connectionState, "the last notification is the current state")
        // Every write changes the state, so in write order no two neighbours are equal.
        XCTAssertFalse(zip(heard, heard.dropFirst()).contains { $0 == $1 }, "a repeat means a transition was delivered out of order")
    }

    func testAnExpiredTokenDropIsBoundToTheRequestsSession() {
        client.setIdentity(uid: uid, token: "same-token")
        let requestGeneration = client.currentSessionGeneration
        // Signed out and back in: the same token string now belongs to a later session.
        client.reset()
        client.setIdentity(uid: uid, token: "same-token")

        XCTAssertFalse(client.dropUnrefreshableIdentityToken(rejected: "same-token", identityGeneration: requestGeneration))
        XCTAssertEqual(client.account.identityToken, "same-token", "an old request must not clear the new session's token")

        XCTAssertTrue(client.dropUnrefreshableIdentityToken(rejected: "same-token", identityGeneration: client.currentSessionGeneration))
        XCTAssertNil(client.account.identityToken)
    }

    func testAnEarlierAccountsIdleNeverOverwritesTheNextIdentitysConnecting() {
        client.setIdentity(uid: uid, token: "token-a")
        let committedA = client.account
        let pendingB = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid + "-b", provider: DashXClosureTokenProvider { _, callback in
            pendingB.value = callback
        })
        awaitUntil(what: "B's load started") { pendingB.value != nil }
        XCTAssertEqual(client.connectionState, .connecting)

        // A's completion publishing late, after B's load began.
        client.publishIdle(ifCurrent: committedA)
        XCTAssertEqual(client.connectionState, .connecting)

        pendingB.value?.onToken("token-b")
        awaitUntil(what: "B's own completion publishes idle") { self.client.connectionState == .idle }
    }

    func testResetEndsTheProviderSessionAndReturnsToIdle() {
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onToken("provider-token")
        })
        awaitUntil(what: "token installed") { self.client.account.identityToken == "provider-token" }

        client.reset()
        XCTAssertNil(client.account.uid)
        XCTAssertFalse(client.hasIdentityToken)
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID), "disk follows memory")
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN))
        XCTAssertEqual(client.connectionState, .idle)
        XCTAssertFalse(refresh(), "no provider is bound after reset")
    }
}

private final class StateRecorder: DashXConnectionStateListener {
    let states = Atomic<[DashXConnectionState]>([])
    func onConnectionStateChanged(_ state: DashXConnectionState) { states.append(state) }
}

private final class FakeRealtimeSocket: RealtimeSocket {
    private let onSend: () -> Void

    init(onSend: @escaping () -> Void) {
        self.onSend = onSend
    }

    func send(text: String) { onSend() }
    func close(code: Int, reason: String?) {}
    func cancel() {}
}

/// Gives the client's realtime runtime fake sockets, a public key and a foreground, and discards
/// the runtime afterwards so later tests start without one.
private final class RealtimeSeam {
    let connections = Atomic<[(socket: FakeRealtimeSocket, listener: RealtimeSocketListener)]>([])
    /// When set, the next frame the runtime sends blocks its queue until signalled, so events can be
    /// lined up behind it.
    let blockNextSend = Atomic<DispatchSemaphore?>(nil)
    let sendBlocked = Atomic<Bool>(false)
    private let client: DashXClient
    private let previousPublicKey: String?
    private let previousForeground: Bool

    init(_ client: DashXClient, publicKey: String? = "public-key-test", foreground: Bool = true) {
        self.client = client
        previousPublicKey = ConfigInterceptor.shared.publicKey
        client.stateLock.lock()
        previousForeground = client._lifecycleForeground
        client.stateLock.unlock()
        discardRuntime()
        ConfigInterceptor.shared.publicKey = publicKey
        let connections = self.connections
        let blockNextSend = self.blockNextSend
        let sendBlocked = self.sendBlocked
        client.stateLock.lock()
        client._realtimeSocketFactory = { _, listener in
            let socket = FakeRealtimeSocket {
                var gate: DispatchSemaphore?
                blockNextSend.mutate { gate = $0; $0 = nil }
                guard let gate else { return }
                sendBlocked.value = true
                gate.wait()
            }
            connections.append((socket, listener))
            return socket
        }
        client._lifecycleForeground = foreground
        client.stateLock.unlock()
    }

    func open(_ index: Int) {
        let connection = connections.value[index]
        connection.listener.socketDidOpen(connection.socket)
    }

    func close(_ index: Int, code: Int) {
        let connection = connections.value[index]
        connection.listener.socket(connection.socket, didCloseWithCode: code, reason: "test")
    }

    func restore() {
        discardRuntime()
        client.stateLock.lock()
        client._realtimeSocketFactory = nil
        client._lifecycleForeground = previousForeground
        client._realtimeBaseURI = nil
        client.stateLock.unlock()
        ConfigInterceptor.shared.publicKey = previousPublicKey
    }

    private func discardRuntime() {
        client.stateLock.lock()
        let runtime = client._realtimeRuntime
        client._realtimeRuntime = nil
        client.stateLock.unlock()
        runtime?.endSession()
    }
}

private final class SilentListener: RealtimeSocketListener {
    func socketDidOpen(_ socket: RealtimeSocket) {}
    func socket(_ socket: RealtimeSocket, didReceiveText text: String) {}
    func socket(_ socket: RealtimeSocket, didCloseWithCode code: Int, reason: String) {}
    func socket(_ socket: RealtimeSocket, didFailWithError error: Error) {}
}
