import Foundation
import GraphQL
import SwiftGraphQLClient

enum Network {
    // FIXME: Update it
    static let baseURL = URL(string: "https://api.dashx-staging.com/graphql")!
    
    // Simple client
    // Add exchanges for better performance at the end
    static func client(publicKey: String, environment: String) -> SwiftGraphQLClient.Client {
        var request = URLRequest(url: baseURL)
        request.addValue(publicKey, forHTTPHeaderField: "X-PUBLIC-KEY")
        request.addValue(environment, forHTTPHeaderField: "X-TARGET-ENVIRONMENT")
        
        let client = SwiftGraphQLClient.Client(request: request)
        return client
    }
}
