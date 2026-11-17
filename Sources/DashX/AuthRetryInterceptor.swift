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

/// Whether a retry pass may go out, judged from the same snapshot that supplies its token.
struct AuthRetryAdmission {
    enum Verdict: Equatable {
        case proceed
        /// The identity session changed since the first pass.
        case sessionEnded
        /// The public-key fallback lost the account the drop left, or a chat request has no token
        /// left to carry; the rejection stands.
        case rejectionStands
    }

    /// The session the first pass ran under.
    var firstPassGeneration = 0
    /// Set once the expired token was dropped: the fallback runs only on the credentials the drop
    /// committed and only while they still carry no token. A sign-in that activates on the cleared
    /// account keeps its generation, so the generation alone would let it lend its token to the
    /// previous identity's request.
    var fallbackCredentials: CredentialVersion?

    /// `requiresToken` marks a chat request, which the server refuses without an identity token:
    /// when another request's rejection dropped the token meanwhile, the retry has nothing to carry.
    func verdict(token: String?, version: CredentialVersion, requiresToken: Bool = false) -> Verdict {
        if let fallbackCredentials {
            return token == nil && version == fallbackCredentials ? .proceed : .rejectionStands
        }
        guard version.sessionGeneration == firstPassGeneration else { return .sessionEnded }
        return requiresToken && token == nil ? .rejectionStands : .proceed
    }
}

/// Attaches the identity token and retries a request rejected before execution once, after a token
/// refresh. Token and session generation are read as one snapshot, so the header on the wire and
/// the generation the retry is guarded by always belong to the same account. Sits at the head of
/// the chain and observes the final result through the completion it passes down. Dropping an
/// expired token is value-guarded: only the exact rejected token is cleared.
final class AuthRetryInterceptor: ApolloInterceptor {
    /// Refreshes for the credentials the request carried; another session's provider is never
    /// asked, and a token already replaced is not refreshed again.
    typealias RefreshToken = (_ credentials: CredentialVersion, _ completion: @escaping (Bool) -> Void) -> Void
    typealias Credentials = (token: String?, version: CredentialVersion)

    static let identityTokenHeader = "X-IDENTITY-TOKEN"

    let id = "com.dashx.authRetryInterceptor"

    private let refreshToken: RefreshToken
    private let credentials: () -> Credentials
    /// Clears the rejected token when nothing can refresh it and it is still the one held by the
    /// request's identity session; returns the credentials the drop committed, or nil.
    private let dropExpiredToken: (_ rejected: String?, _ identityGeneration: Int) -> CredentialVersion?
    private let lock = NSLock()
    private var attempted = false
    private var admission = AuthRetryAdmission()
    /// The first pass's rejection, answered when the retry may not go out.
    private var firstRejection: Any?

    init(
        refreshToken: @escaping RefreshToken = { DashXClient.instance.awaitTokenRefresh(expected: $0, completion: $1) },
        credentials: @escaping () -> Credentials = {
            let account = DashXClient.instance.account
            return (account.identityToken, account.credentialVersion)
        },
        dropExpiredToken: @escaping (_ rejected: String?, _ identityGeneration: Int) -> CredentialVersion? = {
            DashXClient.instance.dropUnrefreshableIdentityToken(rejected: $0, identityGeneration: $1)
        }
    ) {
        self.refreshToken = refreshToken
        self.credentials = credentials
        self.dropExpiredToken = dropExpiredToken
    }

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        let (tokenAtStart, versionAtStart) = credentials()
        let generationAtStart = versionAtStart.sessionGeneration
        // A request bound to the session it began in is refused under any other, judged by the same
        // snapshot that supplies its token: it must never carry the next identity's token.
        if Self.isBoundToAnotherSession(request.context, sessionGeneration: generationAtStart) {
            chain.handleErrorAsync(DashXClientError.sessionEnded, request: request, response: response, completion: completion)
            return
        }
        // Set per pass: a retry carries the refreshed token, and a dropped token leaves with it.
        if let tokenAtStart {
            request.addHeader(name: Self.identityTokenHeader, value: tokenAtStart)
        } else {
            request.additionalHeaders.removeValue(forKey: Self.identityTokenHeader)
        }

        lock.lock()
        let isRetryPass = attempted
        if !isRetryPass { admission.firstPassGeneration = generationAtStart }
        let verdict = isRetryPass
            ? admission.verdict(
                token: tokenAtStart, version: versionAtStart,
                requiresToken: request.context is DashXSessionRequestContext)
            : .proceed
        let rejection = firstRejection
        lock.unlock()
        switch verdict {
        case .proceed:
            break
        case .sessionEnded:
            chain.handleErrorAsync(DashXClientError.sessionEnded, request: request, response: response, completion: completion)
            return
        case .rejectionStands:
            if let rejection = rejection as? GraphQLResult<Operation.Data> {
                chain.returnValueAsync(for: request, value: rejection, completion: completion)
            } else {
                chain.handleErrorAsync(DashXClientError.sessionEnded, request: request, response: response, completion: completion)
            }
            return
        }

        chain.proceedAsync(request: request, response: response, interceptor: self) { [weak self] result in
            guard let self, case .success(let graphQLResult) = result else {
                completion(result)
                return
            }
            let errors = (graphQLResult.errors ?? []).map(AuthRetryPolicy.ErrorInfo.init)
            guard AuthRetryPolicy.isPreExecutionUnauthorized(hasData: graphQLResult.data != nil, errors: errors),
                  self.claimAttempt(rejection: graphQLResult)
            else {
                completion(result)
                return
            }
            guard self.credentials().version.sessionGeneration == generationAtStart else {
                completion(result)
                return
            }
            // Completes only after the new token is installed, so the retry picks it up. The
            // refresh answers on the provider's thread or the timeout queue, and a retry pass runs
            // inline on its caller's: a rejection that stands goes back through the chain, which
            // delivers it on the callback queue.
            let returnRejection = {
                chain.returnValueAsync(for: request, value: graphQLResult, completion: completion)
            }
            self.refreshToken(versionAtStart) { refreshed in
                if !refreshed {
                    // With no provider bound an expired token would fail every call, so drop it and
                    // retry once on the public key alone. A bound provider that failed keeps the
                    // token: the next rejection asks it again. A session-bound request is a chat
                    // operation, which the server refuses without an identity token: its token is
                    // dropped all the same, and the rejection stands unsent.
                    if AuthRetryPolicy.isExpired(errors: errors),
                       let dropped = self.dropExpiredToken(tokenAtStart, generationAtStart),
                       !(request.context is DashXSessionRequestContext) {
                        self.armFallback(dropped)
                        chain.retry(request: request, completion: completion)
                    } else {
                        returnRejection()
                    }
                    return
                }
                guard self.credentials().version.sessionGeneration == generationAtStart else {
                    returnRejection()
                    return
                }
                chain.retry(request: request, completion: completion)
            }
        }
    }

    /// Whether `context` binds the request to a session other than `sessionGeneration`.
    static func isBoundToAnotherSession(_ context: Any?, sessionGeneration: Int) -> Bool {
        guard let bound = context as? DashXSessionRequestContext else { return false }
        return bound.sessionGeneration != sessionGeneration
    }

    private func armFallback(_ credentials: CredentialVersion) {
        lock.lock()
        defer { lock.unlock() }
        admission.fallbackCredentials = credentials
    }

    /// One retry per request chain; the retried pass must pass its own result through.
    private func claimAttempt(rejection: Any) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if attempted { return false }
        attempted = true
        firstRejection = rejection
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
