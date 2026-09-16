import Foundation

/// Frames exchanged with the realtime server: `{"type": "...", "data": {...}}`. Unknown types
/// decode to `.unknown` so a newer server never drops an older client.
enum DashXRealtimeMessage {
    case ping
    case pong
    case connected(connectionId: String)
    case subscriptionSucceeded(channel: String)
    case unsubscriptionSucceeded(channel: String)
    /// Two-way chat message. Distinct from `.inAppMessage`, which is notification-style.
    case inAppChatMessage(DashXRealtimeChatMessage)
    case inAppMessage(DashXRealtimeInAppMessage)
    /// Read-state change for one notification; `readAt == nil` means marked unread.
    case inAppMessageRead(id: String, readAt: String?)
    case inAppMessagesReadAll(readAt: String)
    case error(code: Int, extensionCode: String, message: String)
    case unknown(type: String, data: [String: Any]?)
}

struct DashXRealtimeChatMessage {
    let id: String
    let externalUid: String
    let conversationId: String
    let senderId: String?
    /// `USER` for the visitor's own message; anything else is an agent or AI reply.
    let aiRole: String?
    let turnSeq: Int
    let renderedContent: [String: Any]
    let createdAt: String?
    let sentAt: String?

    init(
        id: String,
        externalUid: String,
        conversationId: String,
        senderId: String? = nil,
        aiRole: String? = nil,
        turnSeq: Int = 0,
        renderedContent: [String: Any] = [:],
        createdAt: String? = nil,
        sentAt: String? = nil
    ) {
        self.id = id
        self.externalUid = externalUid
        self.conversationId = conversationId
        self.senderId = senderId
        self.aiRole = aiRole
        self.turnSeq = turnSeq
        self.renderedContent = renderedContent
        self.createdAt = createdAt
        self.sentAt = sentAt
    }

    init?(json: [String: Any]?) {
        guard let json,
              let id = json.dashxString("id"),
              let externalUid = json.dashxString("externalUid"),
              let conversationId = json.dashxString("conversationId")
        else { return nil }
        self.init(
            id: id,
            externalUid: externalUid,
            conversationId: conversationId,
            senderId: json.dashxString("senderId"),
            aiRole: json.dashxString("aiRole"),
            turnSeq: json.dashxInt("turnSeq") ?? 0,
            renderedContent: json["renderedContent"] as? [String: Any] ?? [:],
            createdAt: json.dashxString("createdAt"),
            sentAt: json.dashxString("sentAt")
        )
    }
}

struct DashXRealtimeInAppMessage {
    let id: String
    let renderedContent: [String: Any]
    let readAt: String?
    let sentAt: String?

    init?(json: [String: Any]?) {
        guard let json, let id = json.dashxString("id") else { return nil }
        self.id = id
        self.renderedContent = json["renderedContent"] as? [String: Any] ?? [:]
        self.readAt = json.dashxString("readAt")
        self.sentAt = json.dashxString("sentAt")
    }
}

enum DashXRealtimeCodec {
    static let typePing = "PING"
    static let typePong = "PONG"
    static let typeSubscribe = "SUBSCRIBE"
    static let typeUnsubscribe = "UNSUBSCRIBE"

    static func decode(_ text: String) -> DashXRealtimeMessage? {
        guard let bytes = text.data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any],
              let type = root["type"] as? String
        else { return nil }
        let data = root["data"] as? [String: Any]

        switch type {
        case typePing:
            return .ping
        case typePong:
            return .pong
        case "CONNECTED":
            return .connected(connectionId: data?.dashxString("connectionId") ?? "")
        case "SUBSCRIPTION_SUCCEEDED":
            return .subscriptionSucceeded(channel: data?.dashxString("channel") ?? "")
        case "UNSUBSCRIPTION_SUCCEEDED":
            return .unsubscriptionSucceeded(channel: data?.dashxString("channel") ?? "")
        case "IN_APP_CHAT_MESSAGE":
            return DashXRealtimeChatMessage(json: data).map { .inAppChatMessage($0) }
        case "IN_APP_MESSAGE":
            return DashXRealtimeInAppMessage(json: data).map { .inAppMessage($0) }
        case "IN_APP_MESSAGE_READ":
            return .inAppMessageRead(id: data?.dashxString("id") ?? "", readAt: data?.dashxString("readAt"))
        case "IN_APP_MESSAGES_READ_ALL":
            return .inAppMessagesReadAll(readAt: data?.dashxString("readAt") ?? "")
        case "ERROR":
            return .error(
                code: data?.dashxInt("code") ?? 0,
                extensionCode: data?.dashxString("extensionCode") ?? "",
                message: data?.dashxString("message") ?? ""
            )
        default:
            return .unknown(type: type, data: data)
        }
    }

    static func encodeChannelFrame(type: String, channelName: String) -> String {
        encode(["type": type, "data": ["channelName": channelName]])
    }

    static func encodeBareFrame(type: String) -> String {
        encode(["type": type])
    }

    private static func encode(_ object: [String: Any]) -> String {
        guard let bytes = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: bytes, encoding: .utf8)
        else { return "{}" }
        return text
    }
}

private extension Dictionary where Key == String, Value == Any {
    func dashxString(_ key: String) -> String? {
        switch self[key] {
        case let value as String: return value
        case let value as NSNumber: return value.stringValue
        default: return nil
        }
    }

    func dashxInt(_ key: String) -> Int? {
        switch self[key] {
        case let value as NSNumber: return value.intValue
        case let value as String: return Int(value)
        default: return nil
        }
    }
}
