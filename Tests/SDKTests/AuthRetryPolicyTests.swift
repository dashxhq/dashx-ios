import XCTest
@testable import DashX

final class AuthRetryPolicyTests: XCTestCase {
    private typealias Info = AuthRetryPolicy.ErrorInfo

    private func unauthorized(_ message: String = "rejected", reason: String? = nil) -> Info {
        Info(code: DashXGraphQLErrors.unauthorized, reason: reason, message: message)
    }

    func testPreExecutionUnauthorizedRequiresNoDataAndOnlyRefreshableUnauthorizedErrors() {
        XCTAssertTrue(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [unauthorized()]))
        XCTAssertTrue(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [unauthorized("Incorrect Identity Token: Expired.")]))
    }

    func testExecutedDataNeverRetries() {
        // data != nil means something executed; retrying a mutation here is a double-send.
        XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: true, errors: [unauthorized()]))
    }

    func testEmptyErrorsNeverRefresh() {
        // `allSatisfy` is vacuously true on an empty list — the guard must not treat that as auth.
        XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: []))
    }

    func testForbiddenAndMixedCodesNeverRefresh() {
        let forbidden = Info(code: DashXGraphQLErrors.forbidden, message: "rejected")
        XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [forbidden]))
        XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [unauthorized(), forbidden]))
        XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [Info(code: nil, message: "boom")]))
    }

    func testRejectionsANewTokenCannotFixNeverRefresh() {
        // Every token problem is UNAUTHORIZED; only the message separates expiry from the rest.
        for message in [
            "Incorrect Identity Token: Invalid signature.",
            "Incorrect Identity Token: Improper format.",
            "Incorrect Identity Token: Missing account.",
            "Incorrect Identity Token: Missing identity 'uid'.",
            "Incorrect Public Key.",
            "Your API Key Pair has expired.",
        ] {
            XCTAssertFalse(AuthRetryPolicy.isRefreshable(unauthorized(message)), message)
            XCTAssertFalse(AuthRetryPolicy.isPreExecutionUnauthorized(hasData: false, errors: [unauthorized(message)]), message)
        }
    }

    func testUnknownMessagesFailOpenAndRefresh() {
        XCTAssertTrue(AuthRetryPolicy.isRefreshable(unauthorized("Something new the SDK has never seen")))
    }

    func testStructuredReasonWinsOverMessageText() {
        XCTAssertTrue(AuthRetryPolicy.isRefreshable(unauthorized("rejected", reason: AuthRetryPolicy.reasonIdentityTokenExpired)))
        XCTAssertFalse(AuthRetryPolicy.isRefreshable(unauthorized("Incorrect Identity Token: Expired.", reason: "IDENTITY_TOKEN_REVOKED")))
        XCTAssertTrue(AuthRetryPolicy.isExpired(errors: [unauthorized("rejected", reason: AuthRetryPolicy.reasonIdentityTokenExpired)]))
        XCTAssertFalse(AuthRetryPolicy.isExpired(errors: [unauthorized("Incorrect Identity Token: Expired.", reason: "IDENTITY_TOKEN_REVOKED")]))
    }

    func testExpiryDetection() {
        XCTAssertTrue(AuthRetryPolicy.isExpired(errors: [unauthorized("Incorrect Identity Token: Expired.")]))
        XCTAssertFalse(AuthRetryPolicy.isExpired(errors: [unauthorized("rejected")]), "a generic UNAUTHORIZED must not drop the token")
        XCTAssertFalse(AuthRetryPolicy.isExpired(errors: []))
        XCTAssertFalse(AuthRetryPolicy.isExpired(errors: [
            unauthorized("Incorrect Identity Token: Expired."),
            Info(code: DashXGraphQLErrors.forbidden, message: "rejected"),
        ]))
    }
}
