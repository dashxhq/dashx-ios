import Apollo
#if canImport(ApolloAPI)
import ApolloAPI
#endif
import Foundation

class Network {
    static let shared = Network()
    private var baseUri: String = "https://api.dashx.com/graphql"

    private let apolloLock = NSLock()
    private var _apollo: ApolloClient?

    var apollo: ApolloClient {
        apolloLock.lock()
        defer { apolloLock.unlock() }
        if let existing = _apollo { return existing }
        let client = makeApolloClient()
        _apollo = client
        return client
    }

    func setBaseURI(to uri: String) {
        apolloLock.lock()
        defer { apolloLock.unlock() }
        guard self.baseUri != uri else {
            return
        }
        self.baseUri = uri
        self._apollo = makeApolloClient()
    }

    private func makeApolloClient() -> ApolloClient {
        let client = URLSessionClient()
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let provider = NetworkInterceptorProvider(client: client, store: store)
        let endpointURL: URL
        if let parsed = URL(string: baseUri) {
            endpointURL = parsed
        } else {
            DashXLog.e(tag: "Network", "Invalid GraphQL base URI '\(baseUri)' — falling back to https://api.dashx.com/graphql")
            endpointURL = URL(string: "https://api.dashx.com/graphql")!
        }
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: endpointURL
        )
        return ApolloClient(networkTransport: transport, store: store)
    }
}

class NetworkInterceptorProvider: DefaultInterceptorProvider {
    override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any ApolloInterceptor] {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(ConfigInterceptor.shared, at: 0)
        return interceptors
    }
}

class ConfigInterceptor: ApolloInterceptor {
    static let shared = ConfigInterceptor()

    let id: String = "com.dashx.configInterceptor"

    private let configQueue = DispatchQueue(label: "com.dashx.config", attributes: .concurrent)

    private var _publicKey: String?
    var publicKey: String? {
        get { configQueue.sync { _publicKey } }
        set { configQueue.sync(flags: .barrier) { self._publicKey = newValue } }
    }

    private var _targetEnvironment: String?
    var targetEnvironment: String? {
        get { configQueue.sync { _targetEnvironment } }
        set { configQueue.sync(flags: .barrier) { self._targetEnvironment = newValue } }
    }

    private var _identityToken: String?
    var identityToken: String? {
        get { configQueue.sync { _identityToken } }
        set { configQueue.sync(flags: .barrier) { self._identityToken = newValue } }
    }

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        if let publicKey = self.publicKey {
            request.addHeader(name: "X-PUBLIC-KEY", value: "\(publicKey)")
        }

        if let targetEnvironment = self.targetEnvironment {
            request.addHeader(name: "X-TARGET-ENVIRONMENT", value: "\(targetEnvironment)")
        }

        if let identityToken = self.identityToken {
            request.addHeader(name: "X-IDENTITY-TOKEN", value: "\(identityToken)")
        }

        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}
