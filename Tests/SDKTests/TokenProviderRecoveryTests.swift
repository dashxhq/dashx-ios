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

    private func awaitIdentityToken() -> Atomic<Result<String, DashXClientError>?> {
        let outcome = Atomic<Result<String, DashXClientError>?>(nil)
        client.awaitIdentityToken { outcome.value = $0 }
        return outcome
    }

    func testAChatCallDuringTheFirstProviderLoadWaitsForItsToken() {
        let pending = Atomic<DashXTokenCallback?>(nil)
        let calls = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            _ = calls.increment()
            pending.value = callback
        })
        awaitUntil(what: "provider invoked") { pending.value != nil }

        let outcome = awaitIdentityToken()
        settle(0.2)
        XCTAssertNil(outcome.value, "a token on its way is not notIdentified")

        pending.value?.onToken("first-token")
        awaitUntil(what: "chat call resumes") { outcome.value != nil }
        XCTAssertEqual(try? outcome.value?.get(), "first-token")
        XCTAssertEqual(calls.value, 1, "the call joins the registration's load")
    }

    func testAChatCallAfterAFailedLoadAsksTheProviderAgain() {
        let calls = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            if calls.increment() == 1 {
                callback.onUnavailable(nil)
            } else {
                callback.onToken("retried-token")
            }
        })
        awaitUntil(what: "first load failed") { self.isAuthFailed(self.client.connectionState) }
        XCTAssertNil(client.account.identityToken)

        let outcome = awaitIdentityToken()
        awaitUntil(what: "chat call resolves") { outcome.value != nil }
        XCTAssertEqual(try? outcome.value?.get(), "retried-token")
        XCTAssertEqual(calls.value, 2)
        awaitUntil(what: "recovered to idle") { self.client.connectionState == .idle }
    }

    func testAChatCallWhoseLoadFailsReportsTheProviderNotNotIdentified() {
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callback.onUnavailable(nil)
        })
        awaitUntil(what: "first load failed") { self.isAuthFailed(self.client.connectionState) }

        let outcome = awaitIdentityToken()
        awaitUntil(what: "chat call resolves") { outcome.value != nil }
        guard case .failure(let error)? = outcome.value else { return XCTFail("expected a failure") }
        if case .notIdentified = error { XCTFail("a bound provider is not notIdentified") }
    }

    func testAFailedLoadSettlesItsOwnWaitersWithoutJoiningALaterLoad() {
        let callbacks = Atomic<[DashXTokenCallback]>([])
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callbacks.append(callback)
        })
        awaitUntil(what: "first load started") { callbacks.value.count == 1 }

        // The first waiter starts another call the moment the load fails, so a second load is in
        // flight when the next waiter of the failed load runs.
        let laterCall = Atomic<Result<String, DashXClientError>?>(nil)
        client.awaitIdentityToken { _ in
            self.client.awaitIdentityToken { laterCall.value = $0 }
        }
        let original = awaitIdentityToken()

        callbacks.value[0].onUnavailable(nil)
        awaitUntil(timeout: 1, what: "the original call settles with its own load") { original.value != nil }
        guard case .failure(let error)? = original.value else { return XCTFail("expected the load's failure") }
        if case .notIdentified = error { XCTFail("a bound provider is not notIdentified") }
        awaitUntil(what: "the later call reaches the provider on its own") { callbacks.value.count == 2 }

        callbacks.value[1].onToken("later-token")
        awaitUntil(what: "later call resolves") { laterCall.value != nil }
        XCTAssertEqual(try? laterCall.value?.get(), "later-token")
    }

    func testASendWhoseCallerLeftDuringTheWaitReportsSessionEndedWhateverTheProviderAnswers() {
        let callbacks = Atomic<[DashXTokenCallback]>([])
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            callbacks.append(callback)
        })
        awaitUntil(what: "load started") { callbacks.value.count == 1 }

        let stillOpen = Atomic<Bool>(true)
        let outcome = Atomic<Result<DashXChatMessage, Error>?>(nil)
        client.sendInAppChatMessage(
            conversationId: UUID().uuidString,
            identityId: UUID().uuidString,
            content: ["text": "hi"],
            clientMessageId: "client-1",
            shouldDispatch: { stillOpen.value },
            completion: { outcome.value = $0 }
        )
        stillOpen.value = false
        callbacks.value[0].onUnavailable(nil)

        awaitUntil(what: "send completes") { outcome.value != nil }
        guard case .failure(DashXClientError.sessionEnded)? = outcome.value else {
            return XCTFail("expected sessionEnded, got \(String(describing: outcome.value))")
        }
    }

    func testAChatCallWithNeitherATokenNorAProviderIsNotIdentified() {
        let outcome = awaitIdentityToken()
        awaitUntil(what: "chat call resolves") { outcome.value != nil }
        guard case .failure(.notIdentified)? = outcome.value else { return XCTFail("expected notIdentified, got \(String(describing: outcome.value))") }
    }

    func testAChatCallWaitingAcrossAnIdentitySwitchEndsTheSession() {
        let pending = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            pending.value = callback
        })
        awaitUntil(what: "provider invoked") { pending.value != nil }

        // As the raw operations deliver: gated on the session the call began under.
        let outcome = Atomic<Result<String, Error>?>(nil)
        let completion: (Result<String, Error>) -> Void = client.sessionBound { outcome.value = $0 }
        client.awaitIdentityToken { result in
            DispatchQueue.main.async { completion(result.mapError { $0 }) }
        }

        client.setIdentity(uid: "other-\(uid)", token: "other-token")
        awaitUntil(what: "chat call resolves") { outcome.value != nil }
        guard case .failure(DashXClientError.sessionEnded)? = outcome.value else {
            return XCTFail("expected sessionEnded, got \(String(describing: outcome.value))")
        }
        pending.value?.onToken("late-token")
        settle(0.2)
        XCTAssertEqual(client.account.identityToken, "other-token")
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

    func testRegisteringProviderAfterARealtimeRejectionForcesARefreshWhateverTheStateSays() {
        client.setIdentity(uid: uid, token: "rejected-token")
        client.onRealtimeAuthRejected(credentials: client.account.credentialVersion) { _ in }
        // The runtime reports `.connecting` while a 4401's refresh is pending and until its
        // failure is published; a registration landing then sees no failure in the state.
        client.publishDirect(.connecting)

        let seenForceRefresh = Atomic<Bool?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            seenForceRefresh.value = forceRefresh
            callback.onToken("fresh-token")
        })

        awaitUntil(what: "fresh token installed") { self.client.account.identityToken == "fresh-token" }
        XCTAssertEqual(seenForceRefresh.value, true, "the held token is the rejected one")
    }

    func testARealtimeRejectionOfAReplacedTokenDoesNotForceALaterRegistration() {
        client.setIdentity(uid: uid, token: "rejected-token")
        client.onRealtimeAuthRejected(credentials: client.account.credentialVersion) { _ in }
        client.setIdentity(uid: uid, token: "next-token")

        let calls = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            _ = calls.increment()
            callback.onToken("unwanted-token")
        })

        settle(0.3)
        XCTAssertEqual(calls.value, 0, "the rejection belonged to the token that was replaced")
        XCTAssertEqual(client.account.identityToken, "next-token")
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

    func testReRegisteringMidRefreshHandsTheWaitingRetryToTheNewProvider() {
        client.setIdentity(uid: uid, token: "rejected-token")
        let first = Atomic<DashXTokenCallback?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            first.value = callback
        })
        let outcome = Atomic<Bool?>(nil)
        client.awaitTokenRefresh { outcome.value = $0 }
        awaitUntil(what: "first provider invoked") { first.value != nil }

        let second = Atomic<DashXTokenCallback?>(nil)
        let secondForceRefresh = Atomic<Bool?>(nil)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            secondForceRefresh.value = forceRefresh
            second.value = callback
        })
        awaitUntil(what: "second provider invoked") { second.value != nil }
        XCTAssertEqual(secondForceRefresh.value, true, "the taken-over load still refreshes past the rejected token")

        first.value?.onUnavailable(nil)
        settle(0.2)
        XCTAssertNil(outcome.value, "the replaced provider's failure no longer decides the retry")

        second.value?.onToken("second-token")
        awaitUntil(what: "retry resolves") { outcome.value != nil }
        XCTAssertEqual(outcome.value, true)
        XCTAssertEqual(client.account.identityToken, "second-token")
    }

    func testAForwardedLoadIgnoresItsOwnProvidersAnswerAndTakesTheSuccessors() {
        let superseded = TokenLoad(forceRefresh: true)
        let received = Atomic<[String?]>([])
        superseded.await { received.append($0) }

        XCTAssertTrue(superseded.beginForwarding())
        // The replaced provider answers between the locked swap and the hand-off.
        superseded.complete(nil)
        XCTAssertTrue(received.value.isEmpty)

        let successor = TokenLoad(forceRefresh: true)
        superseded.finishForwarding(to: successor)
        successor.complete("successor-token")
        XCTAssertEqual(received.value, ["successor-token"])
        XCTAssertFalse(superseded.beginForwarding(), "a finished load cannot be forwarded again")
    }

    func testAChatRequestIsRefusedUnderAnotherSessionThanItBeganIn() {
        let context = DashXSessionRequestContext(sessionGeneration: 4)
        XCTAssertFalse(AuthRetryInterceptor.isBoundToAnotherSession(context, sessionGeneration: 4))
        XCTAssertTrue(AuthRetryInterceptor.isBoundToAnotherSession(context, sessionGeneration: 5))
        XCTAssertFalse(AuthRetryInterceptor.isBoundToAnotherSession(nil, sessionGeneration: 5), "unbound requests are unaffected")
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

    func testOpeningAConversationAfterAFailedFirstLoadAsksTheProviderAgain() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        let requests = Atomic<[Bool]>([])
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            requests.append(forceRefresh)
            if requests.value.count == 1 {
                callback.onUnavailable(nil)
            } else {
                callback.onToken("recovered-token")
            }
        })
        awaitUntil(what: "first load failed") { self.isAuthFailed(self.client.connectionState) }

        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "socket under the recovered token") { realtime.connections.value.count == 1 }
        XCTAssertEqual(requests.value, [false, false], "no token was held, so none was rejected")
        XCTAssertEqual(client.account.identityToken, "recovered-token")
        if case .error = lease.state { XCTFail("a recovered load must not fail the conversation") }
        lease.close()
    }

    func testForegroundAfterAnUnrecoveredRejectionForcesAProviderRefresh() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        let requests = Atomic<[Bool]>([])
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { forceRefresh, callback in
            requests.append(forceRefresh)
            switch requests.value.count {
            case 1: callback.onToken("token-1")
            case 2: callback.onUnavailable(nil)
            default: callback.onToken("token-2")
            }
        })
        awaitUntil(what: "first token") { self.client.account.identityToken == "token-1" }

        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "socket 1") { realtime.connections.value.count == 1 }
        realtime.open(0)
        realtime.close(0, code: 4401)
        // The failed refresh fails the subscriber only after its load released the slot.
        awaitUntil(what: "refresh failed") {
            if case .error(.subscriptionFailed) = lease.state { return true }
            return false
        }
        XCTAssertEqual(realtime.connections.value.count, 1)

        client.realtimeRuntime?.onBackground()
        client.realtimeRuntime?.onForeground()
        awaitUntil(what: "reconnected under a forced token") { realtime.connections.value.count == 2 }
        XCTAssertEqual(requests.value, [false, true, true], "the rejected token is never handed back")
        XCTAssertEqual(client.account.identityToken, "token-2")
        lease.close()
    }

    func testATokenOnlyFirstActivationConnectsAWaitingConversation() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "waiting for an identity") {
            if case .error(.notIdentified) = lease.state { return true }
            return false
        }

        client.setIdentity(uid: nil, token: "token-only")
        awaitUntil(what: "socket under the token") { realtime.connections.value.count == 1 }
        if case .error(.sessionEnded) = lease.state { XCTFail("a first activation must not end the session") }

        // No uid ties a second token to the first one's user.
        client.setIdentity(uid: nil, token: "another-token")
        awaitUntil(what: "session ended") {
            if case .error(.sessionEnded) = lease.state { return true }
            return false
        }
        lease.close()
    }

    func testAnExpiredTokenOnlyIdentityEndsItsSessionBeforeTheNextActivation() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let generation = client.currentSessionGeneration
        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        awaitUntil(what: "socket") { realtime.connections.value.count == 1 }

        let dropped = client.dropUnrefreshableIdentityToken(rejected: "token-only", identityGeneration: generation)
        XCTAssertEqual(dropped?.sessionGeneration, generation + 1, "the public-key retry belongs to the session that follows")
        awaitUntil(what: "session ended") {
            if case .error(.sessionEnded) = lease.state { return true }
            return false
        }

        client.setIdentity(uid: nil, token: "next-user-token")
        let next = client.chat(chatIdentityId: "identity").openConversation("conversation")
        XCTAssertFalse(next === lease)
        settle(0.2)
        if case .error(.sessionEnded) = next.state { XCTFail("the next user's conversation starts fresh") }
        lease.close()
        next.close()
    }

    func testASignInBeforeTheFallbackRetryKeepsItsTokenFromThePreviousRequest() {
        client.setIdentity(uid: nil, token: "token-only")
        let generation = client.currentSessionGeneration
        guard let dropped = client.dropUnrefreshableIdentityToken(rejected: "token-only", identityGeneration: generation) else {
            return XCTFail("the expired token is dropped")
        }
        let admission = AuthRetryAdmission(firstPassGeneration: generation, fallbackCredentials: dropped)
        XCTAssertEqual(admission.verdict(token: client.account.identityToken, version: client.account.credentialVersion), .proceed)

        // Activates on the cleared account: same generation, but now with the next user's token.
        client.setIdentity(uid: "next-\(uid)", token: "next-user-token")
        XCTAssertEqual(client.currentSessionGeneration, dropped.sessionGeneration)
        XCTAssertEqual(admission.verdict(token: client.account.identityToken, version: client.account.credentialVersion), .rejectionStands)
    }

    func testTokenOnlyExpiryTeardownLeavesALaterSessionsConversationsOpen() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let expired = client.currentSessionGeneration
        let chat = client.chat(chatIdentityId: "identity")
        let departing = chat.openConversation("departing")

        // Stands in for a sign-in that opened chat after the cleared account became visible.
        client.updateAccount { $0.sessionGeneration += 1 }
        let arriving = chat.openConversation("arriving")

        ChatCoordinator.shared.closeSessions(openedUnder: expired)
        awaitUntil(what: "the expired session's conversation ended") {
            if case .error(.sessionEnded) = departing.state { return true }
            return false
        }
        settle(0.2)
        if case .error(.sessionEnded) = arriving.state { XCTFail("a later session's conversation stays open") }
        departing.close()
        arriving.close()
    }

    func testANextProvidersFailureAfterATokenOnlyExpiryStaysRecoverable() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let generation = client.currentSessionGeneration
        let departingStates = Atomic<[DashXConversationState]>([])
        let observer = DashXConversationStateObserver { departingStates.append($0) }
        let departing = client.chat(chatIdentityId: "identity").openConversation("departing")
        departing.addStateListener(observer)
        awaitUntil(what: "socket") { realtime.connections.value.count == 1 }

        XCTAssertNotNil(client.dropUnrefreshableIdentityToken(rejected: "token-only", identityGeneration: generation))
        let requests = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            if requests.increment() == 1 {
                callback.onUnavailable(nil)
            } else {
                callback.onToken("next-user-token")
            }
        })
        awaitUntil(what: "the next provider's failure is published") { self.isAuthFailed(self.client.connectionState) }
        settle(0.2)
        XCTAssertTrue(isAuthFailed(client.connectionState), "the expiry reset must not clear the next identity's failure")
        XCTAssertFalse(departingStates.value.contains {
            if case .error(.notIdentified) = $0 { return true }
            return false
        }, "the departing conversation ends without first failing for a missing identity")

        let arriving = client.chat(chatIdentityId: "identity").openConversation("arriving")
        awaitUntil(what: "recovered socket") { realtime.connections.value.count == 2 }
        XCTAssertEqual(requests.value, 2)
        departing.close()
        arriving.close()
    }

    func testADetachedSessionsLeasesHearOfItsEndOnlyWhenNotified() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let generation = client.currentSessionGeneration
        let lease = client.chat(chatIdentityId: "identity").openConversation("conversation")
        let terminations = Atomic<Int>(0)
        lease.setOnTerminated { _ in terminations.mutate { $0 += 1 } }

        let notifyEnded = ChatCoordinator.shared.detachSessions(openedUnder: generation)
        let replayed = Atomic<[DashXConversationState]>([])
        lease.addStateListener(DashXConversationStateObserver { replayed.append($0) })
        let sendRefusals = Atomic<Int>(0)
        lease.sendMessage(content: ["text": "hello"]) { _ in sendRefusals.mutate { $0 += 1 } }
        settle(0.2)
        XCTAssertEqual(terminations.value, 0, "an identity change commits before its leases hear of the end")
        XCTAssertEqual(sendRefusals.value, 0, "a refused send waits for the end to be published")
        if case .error(.sessionEnded) = lease.state { XCTFail("the terminal state is published with the notification") }
        XCTAssertFalse(replayed.value.contains(.error(.sessionEnded)), "a reattached listener's replay is not terminal yet")

        notifyEnded()
        awaitUntil(what: "termination delivered") { terminations.value == 1 && sendRefusals.value == 1 }
        awaitUntil(what: "terminal state replayed") { replayed.value.last == .error(.sessionEnded) }
        if case .error(.sessionEnded) = lease.state {} else { XCTFail("the terminal state is published") }
        lease.close()
    }

    func testAConversationReopenedWhenAnExpiryEndsItBelongsToTheNextSession() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let generation = client.currentSessionGeneration
        let chat = client.chat(chatIdentityId: "identity")
        let departing = chat.openConversation("conversation")
        let reopened = Atomic<DashXConversationLease?>(nil)
        departing.setOnTerminated { _ in reopened.value = chat.openConversation("conversation") }

        XCTAssertNotNil(client.dropUnrefreshableIdentityToken(rejected: "token-only", identityGeneration: generation))
        awaitUntil(what: "reopened from the termination callback") { reopened.value != nil }
        settle(0.2)
        guard let lease = reopened.value else { return XCTFail("the conversation is reopened") }
        if case .error(.sessionEnded) = lease.state { XCTFail("the reopened lease belongs to the session that follows") }
        departing.close()
        lease.close()
    }

    func testReopeningAConversationBeforeAnExpiryCleanupGetsAFreshSession() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        client.setIdentity(uid: nil, token: "token-only")
        let expired = client.currentSessionGeneration
        let chat = client.chat(chatIdentityId: "identity")
        let departing = chat.openConversation("conversation")

        // The expiry committed the next generation; its cleanup has not run yet.
        client.updateAccount { $0.sessionGeneration += 1 }
        let reopened = chat.openConversation("conversation")
        awaitUntil(what: "the expired session ended on replacement") {
            if case .error(.sessionEnded) = departing.state { return true }
            return false
        }

        ChatCoordinator.shared.closeSessions(openedUnder: expired)
        settle(0.2)
        if case .error(.sessionEnded) = reopened.state { XCTFail("the reopened lease belongs to the current session") }
        departing.close()
        reopened.close()
    }

    func testReopeningAConversationWhoseRecoveryFailedAsksTheProviderAgain() {
        let realtime = RealtimeSeam(client)
        defer { realtime.restore() }
        let requests = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            if requests.increment() < 3 {
                callback.onUnavailable(nil)
            } else {
                callback.onToken("third-token")
            }
        })
        awaitUntil(what: "first load failed") { self.isAuthFailed(self.client.connectionState) }

        let chat = client.chat(chatIdentityId: "identity")
        let first = chat.openConversation("conversation")
        awaitUntil(what: "recovery failed") {
            if case .error(.subscriptionFailed) = first.state { return true }
            return false
        }
        XCTAssertEqual(requests.value, 2)

        // The retained lease keeps the session and its subscription: no new SUBSCRIBE is sent.
        let second = chat.openConversation("conversation")
        awaitUntil(what: "socket under the third token") { realtime.connections.value.count == 1 }
        XCTAssertEqual(requests.value, 3)
        first.close()
        second.close()
    }

    func testAQueuedLoadThatTimedOutNeverReachesTheProvider() {
        client.stateLock.lock()
        client._tokenLoadTimeout = 0.2
        client.stateLock.unlock()
        let release = DispatchSemaphore(value: 0)
        defer {
            release.signal()
            client.stateLock.lock()
            client._tokenLoadTimeout = DashXClient.defaultTokenLoadTimeout
            client.stateLock.unlock()
        }
        let calls = Atomic<Int>(0)
        client.setIdentityTokenProvider(uid: uid, provider: DashXClosureTokenProvider { _, callback in
            if calls.increment() == 1 { release.wait() }
            callback.onToken("late-token")
        })
        awaitUntil(what: "first load timed out while its provider blocks") { self.isAuthFailed(self.client.connectionState) }

        let outcome = awaitIdentityToken()
        awaitUntil(what: "queued load timed out") { outcome.value != nil }
        if case .success? = outcome.value { XCTFail("a timed-out load supplies no token") }

        release.signal()
        settle(0.3)
        XCTAssertEqual(calls.value, 1, "the timed-out queued load never reaches the provider")
        XCTAssertNil(client.account.identityToken, "the blocked provider's late answer is discarded")
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

        XCTAssertNil(client.dropUnrefreshableIdentityToken(rejected: "same-token", identityGeneration: requestGeneration))
        XCTAssertEqual(client.account.identityToken, "same-token", "an old request must not clear the new session's token")

        let generation = client.currentSessionGeneration
        XCTAssertEqual(client.dropUnrefreshableIdentityToken(rejected: "same-token", identityGeneration: generation)?.sessionGeneration,
                       generation, "a uid keeps its session when only the token goes")
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
