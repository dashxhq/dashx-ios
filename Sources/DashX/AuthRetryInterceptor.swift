// @_implementationOnly — see `DashXClient.swift` for rationale.
@_implementationOnly import Apollo
#if canImport(ApolloAPI)
@_implementationOnly import ApolloAPI
#endif
import Foundation

/// Decides whether a response is a pre-execution identity-token rejection worth one refresh:
/// `data == nil`, a non-empty error list, and every error `UNAUTHORIZED` and refreshable.
/// `data != nil` means something executed, and retrying a mutation then double-sends.
enum AuthRetryPolicy {
    struct ErrorInfo: Equatable {
        let code: String?
        /// Wins over the message text when present.
        let reason: String?
        let message: String

        init(code: String?, reason: String? = nil, message: String) {
            self.code = code
            self.reason = reason
            self.message = message
        }
    }

    static let reasonIdentityTokenExpired = "IDENTITY_TOKEN_EXPIRED"

    static func isPreExecutionUnauthorized(hasData: Bool, errors: [ErrorInfo]) -> Bool {
        if hasData || errors.isEmpty { return false }
        return errors.allSatisfy { isUnauthorized($0) && isRefreshable($0) }
    }

    static func isExpired(errors: [ErrorInfo]) -> Bool {
        !errors.isEmpty && errors.allSatisfy { isUnauthorized($0) && isExpiry($0) }
    }

    private static func isUnauthorized(_ error: ErrorInfo) -> Bool {
        error.code == DashXGraphQLErrors.unauthorized
    }

    private static func isExpiry(_ error: ErrorInfo) -> Bool {
        if let reason = error.reason { return reason == reasonIdentityTokenExpired }
        return error.message.hasPrefix("Incorrect Identity Token") && error.message.contains("Expired")
    }

    /// Expiry is refreshable; a bad signature, malformed token, missing account or key problem is not.
    /// Unknown messages fail open: one wasted provider call beats leaving an expired token in place.
    static func isRefreshable(_ error: ErrorInfo) -> Bool {
        if let reason = error.reason { return reason == reasonIdentityTokenExpired }
        let message = error.message
        if message.contains("Public Key") || message.contains("API Key Pair") { return false }
        if message.hasPrefix("Incorrect Identity Token") && !message.contains("Expired") { return false }
        return true
    }
}

/// Retries a request rejected before execution once, after a token refresh. Sits at the head of the
/// chain and observes the final result through the completion it passes down. Generation-guarded:
/// an identity switch during the request or refresh leaves the rejection with the old session.
/// Dropping an expired token is value-guarded: only the exact rejected token is cleared.
final class AuthRetryInterceptor: ApolloInterceptor {
    typealias RefreshToken = (_ completion: @escaping (Bool) -> Void) -> Void

    let id = "com.dashx.authRetryInterceptor"

    private let refreshToken: RefreshToken
    private let sessionGeneration: () -> Int
    private let currentToken: () -> String?
    /// Clears the rejected token when nothing can refresh it and it is still the one held.
    private let dropExpiredToken: (_ rejected: String?) -> Bool
    private let lock = NSLock()
    private var attempted = false

    init(
        refreshToken: @escaping RefreshToken = { DashXClient.instance.awaitTokenRefresh(completion: $0) },
        sessionGeneration: @escaping () -> Int = { DashXClient.instance.currentSessionGeneration },
        currentToken: @escaping () -> String? = { DashXClient.instance.identityToken },
        dropExpiredToken: @escaping (_ rejected: String?) -> Bool = { DashXClient.instance.dropUnrefreshableIdentityToken(rejected: $0) }
    ) {
        self.refreshToken = refreshToken
        self.sessionGeneration = sessionGeneration
        self.currentToken = currentToken
        self.dropExpiredToken = dropExpiredToken
    }

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        let generationAtStart = sessionGeneration()
        let tokenAtStart = currentToken()

        chain.proceedAsync(request: request, response: response, interceptor: self) { [weak self] result in
            guard let self, case .success(let graphQLResult) = result else {
                completion(result)
                return
            }
            let errors = (graphQLResult.errors ?? []).map(AuthRetryPolicy.ErrorInfo.init)
            guard AuthRetryPolicy.isPreExecutionUnauthorized(hasData: graphQLResult.data != nil, errors: errors),
                  self.claimAttempt()
            else {
                completion(result)
                return
            }
            guard self.sessionGeneration() == generationAtStart else {
                completion(result)
                return
            }
            // Completes only after the new token is installed, so the retry picks it up.
            self.refreshToken { refreshed in
                if !refreshed {
                    // No provider bound or the refresh failed: an expired token would fail every
                    // call, so drop it and retry once on the public key alone.
                    if AuthRetryPolicy.isExpired(errors: errors), self.dropExpiredToken(tokenAtStart) {
                        chain.retry(request: request, completion: completion)
                    } else {
                        completion(result)
                    }
                    return
                }
                guard self.sessionGeneration() == generationAtStart else {
                    completion(result)
                    return
                }
                chain.retry(request: request, completion: completion)
            }
        }
    }

    /// One retry per request chain; the retried pass must pass its own result through.
    private func claimAttempt() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if attempted { return false }
        attempted = true
        return true
    }
}

extension AuthRetryPolicy.ErrorInfo {
    init(_ error: GraphQLError) {
        self.init(
            code: error.extensions?["code"] as? String,
            reason: error.extensions?["reason"] as? String,
            message: error.message ?? ""
        )
    }
}

extension DashXGraphQLErrors {
    /// One code for the whole response, or nil when mixed or absent.
    init(graphQLErrors: [GraphQLError]) {
        let codes = Set(graphQLErrors.compactMap { $0.extensions?["code"] as? String })
        self.init(
            messages: graphQLErrors.map { $0.message ?? "" },
            code: codes.count == 1 ? codes.first : nil
        )
    }
}

extension DashXClientError {
    static func fromGraphQL(_ errors: [GraphQLError]) -> DashXClientError {
        .graphQLErrors(DashXGraphQLErrors(graphQLErrors: errors))
    }
}
