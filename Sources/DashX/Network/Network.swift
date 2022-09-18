import Foundation
import SwiftGraphQLClient

final class Network {
    static let shared = Network()
    
    private var baseURL = URL(string: "https://api.dashx.com/graphql")!
    private var publicKey: String?
    private var targetEnvironment: String?
    private var identityToken: String?
    
    func setBaseURL(to url: URL) {
        self.baseURL = url
    }
    
    func setPublicKey(to key: String?) {
        self.publicKey = key
    }
    
    func setTargetEnvironment(to environment: String?) {
        self.targetEnvironment = environment
    }
    
    func setIdentityToken(to token: String?) {
        self.identityToken = token
    }
    
    private(set) lazy var request: URLRequest = {
        var request = URLRequest(url: baseURL)
        if let publicKey = self.publicKey {
            request.addValue(publicKey, forHTTPHeaderField: "X-PUBLIC-KEY")
        }
        
        if let targetEnvironment = self.targetEnvironment {
            request.addValue(targetEnvironment, forHTTPHeaderField: "X-TARGET-ENVIRONMENT")
        }
        
        if let identityToken = self.identityToken {
            request.addValue(identityToken, forHTTPHeaderField: "X-IDENTITY-TOKEN")
        }
        
        return request
    }()
    
    // Simple client
    // Add exchanges for better performance at the end
    private(set) lazy var client: SwiftGraphQLClient.Client = {
        let client = SwiftGraphQLClient.Client(request: request)
        return client
    }()
}
