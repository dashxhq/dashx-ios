// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class ResolveInAppChatConversationMutation: GraphQLMutation {
    static let operationName: String = "ResolveInAppChatConversation"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResolveInAppChatConversation($identityId: UUID!, $conversationId: UUID!) { resolveInAppChatConversation( input: { identityId: $identityId, conversationId: $conversationId } ) { __typename ...ChatConversationSummaryFragment } }"#,
        fragments: [ChatConversationSummaryFragment.self]
      ))

    public var identityId: UUID
    public var conversationId: UUID

    public init(
      identityId: UUID,
      conversationId: UUID
    ) {
      self.identityId = identityId
      self.conversationId = conversationId
    }

    public var __variables: Variables? { [
      "identityId": identityId,
      "conversationId": conversationId
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("resolveInAppChatConversation", ResolveInAppChatConversation.self, arguments: ["input": [
          "identityId": .variable("identityId"),
          "conversationId": .variable("conversationId")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResolveInAppChatConversationMutation.Data.self
      ] }

      var resolveInAppChatConversation: ResolveInAppChatConversation { __data["resolveInAppChatConversation"] }

      init(
        resolveInAppChatConversation: ResolveInAppChatConversation
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "resolveInAppChatConversation": resolveInAppChatConversation._fieldData,
        ])
      }

      /// ResolveInAppChatConversation
      ///
      /// Parent Type: `ChatConversationSummary`
      struct ResolveInAppChatConversation: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.ChatConversationSummary }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ChatConversationSummaryFragment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResolveInAppChatConversationMutation.Data.ResolveInAppChatConversation.self,
          ChatConversationSummaryFragment.self
        ] }

        var conversationId: DashXGql.UUID { __data["conversationId"] }
        var category: String { __data["category"] }
        var context: Context? { __data["context"] }
        var topic: Topic? { __data["topic"] }
        var status: String { __data["status"] }
        var title: String { __data["title"] }
        var lastMessagePreview: String? { __data["lastMessagePreview"] }
        var lastMessageAt: String? { __data["lastMessageAt"] }
        var lastSenderKind: String? { __data["lastSenderKind"] }
        var activityAt: String { __data["activityAt"] }
        var assignedGroups: [AssignedGroup] { __data["assignedGroups"] }
        var unreadCount: Int { __data["unreadCount"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var chatConversationSummaryFragment: ChatConversationSummaryFragment { _toFragment() }
        }

        init(
          conversationId: DashXGql.UUID,
          category: String,
          context: Context? = nil,
          topic: Topic? = nil,
          status: String,
          title: String,
          lastMessagePreview: String? = nil,
          lastMessageAt: String? = nil,
          lastSenderKind: String? = nil,
          activityAt: String,
          assignedGroups: [AssignedGroup],
          unreadCount: Int
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.ChatConversationSummary.typename,
            "conversationId": conversationId,
            "category": category,
            "context": context._fieldData,
            "topic": topic._fieldData,
            "status": status,
            "title": title,
            "lastMessagePreview": lastMessagePreview,
            "lastMessageAt": lastMessageAt,
            "lastSenderKind": lastSenderKind,
            "activityAt": activityAt,
            "assignedGroups": assignedGroups._fieldData,
            "unreadCount": unreadCount,
          ])
        }

        typealias Context = ChatConversationSummaryFragment.Context

        typealias Topic = ChatConversationSummaryFragment.Topic

        typealias AssignedGroup = ChatConversationSummaryFragment.AssignedGroup
      }
    }
  }

}