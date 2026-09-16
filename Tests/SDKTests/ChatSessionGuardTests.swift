import XCTest
@testable import DashX

/// `sessionBound` — raw chat operations are not cancelled by an identity switch, so their
/// completions must be gated on the session generation they began under.
final class ChatSessionGuardTests: XCTestCase {
    private var client: DashXClient { DashXClient.instance }

    override func tearDown() {
        client.setIdentity(uid: nil, token: nil)
        super.tearDown()
    }

    private func isSessionEnded(_ result: Result<String, Error>) -> Bool {
        if case .failure(let error) = result, case DashXClientError.sessionEnded = error { return true }
        return false
    }

    func testCompletionAfterAnIdentitySwitchDeliversSessionEndedNotTheOldIdentitysData() {
        client.setIdentity(uid: "guard-user-a", token: "token-a")
        var delivered: [Result<String, Error>] = []
        let bound = client.sessionBound { (result: Result<String, Error>) in delivered.append(result) }

        client.setIdentity(uid: "guard-user-b", token: "token-b") // T2: new session generation

        bound(.success("user-a-conversations"))
        XCTAssertEqual(delivered.count, 1)
        XCTAssertTrue(isSessionEnded(delivered[0]), "a stale completion must deliver sessionEnded, never the old identity's data")
    }

    func testErrorAfterAResetDeliversSessionEnded() {
        client.setIdentity(uid: "guard-user-a", token: "token-a")
        var delivered: [Result<String, Error>] = []
        let bound = client.sessionBound { (result: Result<String, Error>) in delivered.append(result) }

        client.setIdentity(uid: nil, token: nil) // logout bumps the generation like reset()

        bound(.failure(DashXClientError.networkError(underlying: NSError(domain: "test", code: -1001))))
        XCTAssertEqual(delivered.count, 1)
        XCTAssertTrue(isSessionEnded(delivered[0]))
    }

    func testSameIdentityTokenRefreshLeavesTheOperationValid() {
        client.setIdentity(uid: "guard-user-a", token: "token-a")
        var delivered: [Result<String, Error>] = []
        let bound = client.sessionBound { (result: Result<String, Error>) in delivered.append(result) }

        client.setIdentity(uid: "guard-user-a", token: "token-a2") // T1: generation unchanged

        bound(.success("still-user-a"))
        XCTAssertEqual(delivered.count, 1)
        guard case .success(let value) = delivered[0] else { return XCTFail("expected the operation's own result") }
        XCTAssertEqual(value, "still-user-a")
    }

    func testSetIdentityWithNilTokenForTheCurrentUidKeepsTheHeldToken() {
        client.setIdentity(uid: "guard-user-a", token: "token-a")
        client.setIdentity(uid: "guard-user-a", token: nil)
        XCTAssertEqual(client.account.identityToken, "token-a")
        XCTAssertTrue(client.hasIdentityToken)

        client.setIdentity(uid: nil, token: nil)
        XCTAssertFalse(client.hasIdentityToken)
    }
}
