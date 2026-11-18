import DashX
import UIKit

/// Configures DashX against loopback stubs and opens a conversation during
/// `didFinishLaunching`, as a host that restores a chat screen at launch would.
final class SmokeHost {
    static let shared = SmokeHost()

    static let conversationId = "11111111-1111-4111-8111-111111111111"
    static let messageId = "22222222-2222-4222-8222-222222222222"

    private(set) var launchApplicationState: UIApplication.State?
    private(set) var didEnterBackground = false
    private(set) var lease: DashXConversationLease?
    private(set) var startError: Error?

    private var graphQLServer: LoopbackGraphQLServer?
    private var realtimeServer: LoopbackRealtimeServer?
    private var backgroundObserver: NSObjectProtocol?

    func startAtLaunch(applicationState: UIApplication.State) {
        launchApplicationState = applicationState
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.didEnterBackground = true }

        do {
            let graphQL = try LoopbackGraphQLServer(respond: Self.graphQLResponse)
            let realtime = try LoopbackRealtimeServer()
            graphQLServer = graphQL
            realtimeServer = realtime

            DashX.setRealtimeBaseURI("ws://localhost:\(realtime.port)")
            DashX.configure(withPublicKey: "smoke-public-key", baseURI: "http://localhost:\(graphQL.port)/graphql")
            DashX.setIdentity(uid: "smoke-user", token: "smoke-identity-token")
            lease = DashX.chat(chatIdentityId: "smoke-chat-identity").openConversation(Self.conversationId)
        } catch {
            startError = error
        }
    }

    private static func graphQLResponse(operationName: String) -> String {
        switch operationName {
        case "SummarizeInAppChatMessages":
            return #"{"data":{"summarizeInAppChatMessages":{"__typename":"SummarizeInAppChatMessagesResponse","count":1}}}"#
        case "FetchInAppChatMessages":
            return """
            {"data":{"fetchInAppChatMessages":[{"__typename":"Message","id":"\(messageId)",\
            "conversationId":"\(conversationId)","renderedContent":{"text":"hello"},"externalUid":null,\
            "senderId":null,"aiRole":"assistant","turnSeq":1,"sentAt":null,"createdAt":"2026-11-17 10:00:00"}]}}
            """
        default:
            return #"{"data":null,"errors":[{"message":"Not stubbed by the smoke host"}]}"#
        }
    }
}
