import XCTest
@testable import DashX

final class DashXClientErrorTests: XCTestCase {

    func testNoArgsInIdentify() {
        let error = DashXClientError.noArgsInIdentify
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testAssetIsNotReady() {
        let error = DashXClientError.assetIsNotReady
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testAssetIsNotUploaded() {
        let error = DashXClientError.assetIsNotUploaded
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testNotIdentified() {
        let error = DashXClientError.notIdentified
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("setIdentity"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testGraphQLErrors() {
        let error = DashXClientError.graphQLErrors(["Query failed", "Invalid input"])
        if case .graphQLErrors(let messages) = error {
            XCTAssertEqual(messages.count, 2)
            XCTAssertEqual(messages[0], "Query failed")
            XCTAssertEqual(messages[1], "Invalid input")
        } else {
            XCTFail("Expected graphQLErrors case")
        }
        XCTAssertTrue(error.errorDescription!.contains("Query failed"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testNetworkError() {
        let underlying = NSError(domain: "test", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        let error = DashXClientError.networkError(underlying: underlying)
        if case .networkError(let inner) = error {
            XCTAssertEqual((inner as NSError).code, -1009)
        } else {
            XCTFail("Expected networkError case")
        }
        XCTAssertTrue(error.errorDescription!.contains("No internet"))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testCustomError() {
        let error = DashXClientError.customError(message: "Something went wrong")
        if case .customError(let message) = error {
            XCTAssertEqual(message, "Something went wrong")
        } else {
            XCTFail("Expected customError case")
        }
        XCTAssertEqual(error.errorDescription, "Something went wrong")
        XCTAssertNil(error.recoverySuggestion)
    }

    func testErrorConformsToLocalizedError() {
        let error: LocalizedError = DashXClientError.notIdentified
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - isRetryable

    func testIsRetryable_networkError() {
        let error = DashXClientError.networkError(underlying: NSError(domain: "test", code: -1, userInfo: nil))
        XCTAssertTrue(error.isRetryable)
    }

    func testIsRetryable_assetNotReady() {
        XCTAssertTrue(DashXClientError.assetIsNotReady.isRetryable)
    }

    func testIsRetryable_nonRetryable() {
        XCTAssertFalse(DashXClientError.notIdentified.isRetryable)
        XCTAssertFalse(DashXClientError.noArgsInIdentify.isRetryable)
        XCTAssertFalse(DashXClientError.assetIsNotUploaded.isRetryable)
        XCTAssertFalse(DashXClientError.graphQLErrors(["err"]).isRetryable)
        XCTAssertFalse(DashXClientError.customError(message: "err").isRetryable)
    }

    // MARK: - localizedDescription via Error protocol

    func testLocalizedDescriptionViaErrorProtocol() {
        let error: Error = DashXClientError.notIdentified
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
}
