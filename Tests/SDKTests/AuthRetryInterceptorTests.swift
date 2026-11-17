import Apollo
import ApolloAPI
import XCTest
@testable import DashX

/// A rejection that stands after the refresh attempt reaches the caller on the chain's callback
/// queue, whichever thread the token load answered on.
final class AuthRetryInterceptorTests: XCTestCase {
    private typealias Query = DashXGql.SummarizeInAppChatUnreadQuery

    private static let expiredMessage = "Incorrect Identity Token: Expired."

    /// Answers every pass with a pre-execution `UNAUTHORIZED` expiry.
    private final class RejectingInterceptor: ApolloInterceptor {
        let id = "com.dashx.tests.rejectingInterceptor"
        private(set) var passes = 0

        func interceptAsync<Operation: GraphQLOperation>(
            chain: any RequestChain,
            request: HTTPRequest<Operation>,
            response: HTTPResponse<Operation>?,
            completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
        ) {
            passes += 1
            let error = GraphQLError([
                "message": AuthRetryInterceptorTests.expiredMessage,
                "extensions": ["code": DashXGraphQLErrors.unauthorized] as [String: AnyHashable],
            ])
            let rejection = GraphQLResult<Operation.Data>(
                data: nil, extensions: nil, errors: [error], source: .server, dependentKeys: nil)
            chain.proceedAsync(
                request: request,
                response: HTTPResponse<Operation>(response: HTTPURLResponse(), rawData: Data(), parsedResponse: rejection),
                interceptor: self,
                completion: completion
            )
        }
    }

    private final class Account {
        private let lock = NSLock()
        private var token: String? = "expired"
        private var version = CredentialVersion(sessionGeneration: 1, tokenEpoch: 1)

        var credentials: AuthRetryInterceptor.Credentials {
            lock.lock()
            defer { lock.unlock() }
            return (token, version)
        }

        func set(token: String?, version: CredentialVersion) {
            lock.lock()
            defer { lock.unlock() }
            self.token = token
            self.version = version
        }
    }

    private let providerQueue = DispatchQueue(label: "com.dashx.tests.tokenProvider")

    /// Runs one request through `[AuthRetryInterceptor, RejectingInterceptor]` and reports how
    /// many passes went out and whether the completion ran on the main thread.
    private func runRejectedRequest(
        account: Account,
        context: (any RequestContext)? = nil,
        refresh: @escaping (_ account: Account) -> Bool,
        dropExpiredToken: @escaping (_ account: Account) -> CredentialVersion? = { _ in nil }
    ) -> (passes: Int, onMain: Bool, messages: [String]) {
        let providerQueue = self.providerQueue
        let interceptor = AuthRetryInterceptor(
            refreshToken: { _, completion in providerQueue.async { completion(refresh(account)) } },
            credentials: { account.credentials },
            dropExpiredToken: { _, _ in dropExpiredToken(account) }
        )
        let rejecting = RejectingInterceptor()
        let chain = InterceptorRequestChain(interceptors: [interceptor, rejecting], callbackQueue: .main)
        let request = JSONRequest(
            operation: Query(identityId: "identity"),
            graphQLEndpoint: URL(string: "https://example.invalid/graphql")!,
            clientName: "tests",
            clientVersion: "0",
            context: context
        )

        let completed = expectation(description: "completion")
        var onMain = false
        var messages: [String] = []
        chain.kickoff(request: request) { result in
            onMain = Thread.isMainThread
            if case .success(let graphQLResult) = result {
                messages = (graphQLResult.errors ?? []).map { $0.message ?? "" }
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
        return (rejecting.passes, onMain, messages)
    }

    func testFailedRefreshDeliversTheRejectionOnTheCallbackQueue() {
        let outcome = runRejectedRequest(account: Account(), refresh: { _ in false })

        XCTAssertEqual(outcome.passes, 1, "nothing to retry with")
        XCTAssertEqual(outcome.messages, [Self.expiredMessage])
        XCTAssertTrue(outcome.onMain, "the provider's thread must not reach the caller")
    }

    func testIdentityChangeDuringRefreshDeliversTheRejectionOnTheCallbackQueue() {
        let outcome = runRejectedRequest(account: Account(), refresh: { account in
            account.set(token: "next", version: CredentialVersion(sessionGeneration: 2, tokenEpoch: 2))
            return true
        })

        XCTAssertEqual(outcome.passes, 1, "the next identity's token never carries this request")
        XCTAssertEqual(outcome.messages, [Self.expiredMessage])
        XCTAssertTrue(outcome.onMain)
    }

    func testFallbackThatLostItsAccountDeliversTheRejectionOnTheCallbackQueue() {
        let dropped = CredentialVersion(sessionGeneration: 1, tokenEpoch: 2)
        let outcome = runRejectedRequest(
            account: Account(),
            refresh: { _ in false },
            dropExpiredToken: { account in
                // A sign-in lands on the cleared account before the fallback pass reads it.
                account.set(token: "next", version: CredentialVersion(sessionGeneration: 1, tokenEpoch: 3))
                return dropped
            }
        )

        XCTAssertEqual(outcome.passes, 1, "the fallback pass is refused before it is sent")
        XCTAssertEqual(outcome.messages, [Self.expiredMessage])
        XCTAssertTrue(outcome.onMain, "the retry pass runs inline on the provider's thread")
    }

    /// Drops the expired token as the client does: the account keeps its session and loses the token.
    private func dropToken(_ drops: Atomic<Int>) -> (Account) -> CredentialVersion? {
        return { account in
            _ = drops.increment()
            let dropped = CredentialVersion(sessionGeneration: 1, tokenEpoch: 2)
            account.set(token: nil, version: dropped)
            return dropped
        }
    }

    func testExpiredTokenIsDroppedAndTheRequestRetriedOnThePublicKey() {
        let drops = Atomic<Int>(0)
        let outcome = runRejectedRequest(account: Account(), refresh: { _ in false }, dropExpiredToken: dropToken(drops))

        XCTAssertEqual(drops.value, 1)
        XCTAssertEqual(outcome.passes, 2, "the fallback pass goes out without the token")
        XCTAssertTrue(outcome.onMain)
    }

    func testChatRequestDropsTheExpiredTokenWithoutAPublicKeyRetry() {
        let drops = Atomic<Int>(0)
        let outcome = runRejectedRequest(
            account: Account(),
            context: DashXSessionRequestContext(sessionGeneration: 1),
            refresh: { _ in false },
            dropExpiredToken: dropToken(drops)
        )

        XCTAssertEqual(drops.value, 1, "the expired token is still dropped")
        XCTAssertEqual(outcome.passes, 1, "a chat operation without a token is refused; it is not sent")
        XCTAssertEqual(outcome.messages, [Self.expiredMessage])
        XCTAssertTrue(outcome.onMain)
    }

    /// Another request's rejection dropped the token first: the refresh reports the credentials
    /// replaced, as the client does once the token epoch has moved.
    private func tokenAlreadyDropped(_ account: Account) -> Bool {
        account.set(token: nil, version: CredentialVersion(sessionGeneration: 1, tokenEpoch: 2))
        return true
    }

    func testChatRequestRejectedAfterAnotherRequestDroppedTheTokenIsNotRetried() {
        let drops = Atomic<Int>(0)
        let outcome = runRejectedRequest(
            account: Account(),
            context: DashXSessionRequestContext(sessionGeneration: 1),
            refresh: tokenAlreadyDropped,
            dropExpiredToken: dropToken(drops)
        )

        XCTAssertEqual(drops.value, 0, "the first rejection already dropped it")
        XCTAssertEqual(outcome.passes, 1, "a chat operation with no token left to carry is not sent again")
        XCTAssertEqual(outcome.messages, [Self.expiredMessage], "the caller hears the expiry")
        XCTAssertTrue(outcome.onMain, "the retry pass runs inline on the provider's thread")
    }

    func testOtherRequestRejectedAfterAnotherRequestDroppedTheTokenRetriesOnThePublicKey() {
        let outcome = runRejectedRequest(account: Account(), refresh: tokenAlreadyDropped)

        XCTAssertEqual(outcome.passes, 2, "the public key alone still carries it")
        XCTAssertTrue(outcome.onMain)
    }
}
