import Foundation

/// One chat message, normalized from history fetches and realtime frames alike.
public struct DashXChatMessage {
    static let clientMessagePrefix = "in_app_chat:"

    public let id: String
    public let conversationId: String
    /// Raw server key. Prefer `clientMessageId` for reconciling a pending send.
    public let externalUid: String?
    public let senderId: String?
    /// `USER` for the visitor's own message; anything else is an agent or AI reply.
    public let aiRole: String?
    public let turnSeq: Int
    public let renderedContent: [String: Any?]
    public let createdAt: String?
    public let sentAt: String?

    public init(
        id: String,
        conversationId: String,
        externalUid: String?,
        senderId: String?,
        aiRole: String?,
        turnSeq: Int,
        renderedContent: [String: Any?],
        createdAt: String?,
        sentAt: String?
    ) {
        self.id = id
        self.conversationId = conversationId
        self.externalUid = externalUid
        self.senderId = senderId
        self.aiRole = aiRole
        self.turnSeq = turnSeq
        self.renderedContent = renderedContent
        self.createdAt = createdAt
        self.sentAt = sentAt
    }

    /// The client message id this visitor message was sent with, or nil for agent, AI and system
    /// rows. Reconcile an optimistic row against this: `id` is only known once the server commits.
    public var clientMessageId: String? {
        guard let externalUid, externalUid.hasPrefix(Self.clientMessagePrefix) else { return nil }
        return String(externalUid.dropFirst(Self.clientMessagePrefix.count))
    }

    /// Server message order: `(turnSeq, createdAt, id)` ascending.
    public static func order(_ lhs: DashXChatMessage, _ rhs: DashXChatMessage) -> Bool {
        if lhs.turnSeq != rhs.turnSeq { return lhs.turnSeq < rhs.turnSeq }
        let lhsCreated = lhs.createdAt ?? ""
        let rhsCreated = rhs.createdAt ?? ""
        if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
        return lhs.id < rhs.id
    }

    init(frame: DashXRealtimeChatMessage) {
        self.init(
            id: frame.id,
            conversationId: frame.conversationId,
            externalUid: frame.externalUid,
            senderId: frame.senderId,
            aiRole: frame.aiRole,
            turnSeq: frame.turnSeq,
            renderedContent: frame.renderedContent.mapValues { Optional($0) },
            createdAt: frame.createdAt,
            sentAt: frame.sentAt
        )
    }
}

extension DashXChatMessage: Equatable {
    public static func == (lhs: DashXChatMessage, rhs: DashXChatMessage) -> Bool {
        lhs.id == rhs.id
            && lhs.conversationId == rhs.conversationId
            && lhs.externalUid == rhs.externalUid
            && lhs.senderId == rhs.senderId
            && lhs.aiRole == rhs.aiRole
            && lhs.turnSeq == rhs.turnSeq
            && lhs.createdAt == rhs.createdAt
            && lhs.sentAt == rhs.sentAt
            && NSDictionary(dictionary: lhs.renderedContent.mapValues { $0 ?? NSNull() })
                == NSDictionary(dictionary: rhs.renderedContent.mapValues { $0 ?? NSNull() })
    }
}

public struct DashXChatConversationSummary: Equatable {
    public struct Context: Equatable {
        public let kind: String
        public let subtype: String?
        public let id: String
        public let reference: String?
        public let name: String?

        public init(kind: String, subtype: String?, id: String, reference: String?, name: String?) {
            self.kind = kind
            self.subtype = subtype
            self.id = id
            self.reference = reference
            self.name = name
        }
    }

    public struct Topic: Equatable {
        public let id: String
        public let label: String

        public init(id: String, label: String) {
            self.id = id
            self.label = label
        }
    }

    public struct AssignedGroup: Equatable {
        public let id: String
        public let name: String

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    public let conversationId: String
    public let category: String
    public let context: Context?
    public let topic: Topic?
    public let status: String
    public let title: String
    public let lastMessagePreview: String?
    public let lastMessageAt: String?
    public let lastSenderKind: String?
    public let activityAt: String
    public let assignedGroups: [AssignedGroup]
    /// Messages the visitor has not read yet.
    public let unreadCount: Int

    public init(
        conversationId: String,
        category: String,
        context: Context?,
        topic: Topic?,
        status: String,
        title: String,
        lastMessagePreview: String?,
        lastMessageAt: String?,
        lastSenderKind: String?,
        activityAt: String,
        assignedGroups: [AssignedGroup],
        unreadCount: Int
    ) {
        self.conversationId = conversationId
        self.category = category
        self.context = context
        self.topic = topic
        self.status = status
        self.title = title
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.lastSenderKind = lastSenderKind
        self.activityAt = activityAt
        self.assignedGroups = assignedGroups
        self.unreadCount = unreadCount
    }
}

public enum DashXConversationState {
    case loading
    /// `hasOlderMessages` is true while `loadPreviousPage` still has history to fetch.
    case ready(messages: [DashXChatMessage], hasOlderMessages: Bool)
    case error(DashXClientError)
}

extension DashXConversationState: Equatable {
    public static func == (lhs: DashXConversationState, rhs: DashXConversationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.ready(lhsMessages, lhsOlder), .ready(rhsMessages, rhsOlder)):
            return lhsOlder == rhsOlder && lhsMessages == rhsMessages
        case let (.error(lhsError), .error(rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        default:
            return false
        }
    }
}

/// Observer for `DashXConversationState` changes. Listeners are lease-owned: `close()` drops them.
public protocol DashXConversationStateListener: AnyObject {
    func onConversationStateChanged(_ state: DashXConversationState)
}

/// Closure-backed `DashXConversationStateListener`; keep a reference so it can be removed.
public final class DashXConversationStateObserver: DashXConversationStateListener {
    private let handler: (DashXConversationState) -> Void

    public init(_ handler: @escaping (DashXConversationState) -> Void) {
        self.handler = handler
    }

    public func onConversationStateChanged(_ state: DashXConversationState) {
        handler(state)
    }
}

public enum DashXSubscriptionEnd {
    case sessionEnded
    case unsubscribed
}

/// The identity is part of the key: the same conversation id under another chat identity is a
/// different resource.
struct ChatSessionKey: Hashable {
    let chatIdentityId: String
    let conversationId: String
}
