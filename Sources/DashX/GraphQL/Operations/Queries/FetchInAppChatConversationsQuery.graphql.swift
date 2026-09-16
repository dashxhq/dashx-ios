// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class FetchInAppChatConversationsQuery: GraphQLQuery {
    static let operationName: String = "FetchInAppChatConversations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchInAppChatConversations($identityId: UUID!, $limit: Int, $page: Int, $statuses: [String!], $properties: JSON) { fetchInAppChatConversations( input: { identityId: $identityId limit: $limit page: $page statuses: $statuses properties: $properties } ) { __typename ...ChatConversationSummaryFragment } }"#,
        fragments: [ChatConversationSummaryFragment.self]
      ))

    public var identityId: UUID
    public var limit: GraphQLNullable<Int>
    public var page: GraphQLNullable<Int>
    public var statuses: GraphQLNullable<[String]>
    public var properties: GraphQLNullable<JSON>

    public init(
      identityId: UUID,
      limit: GraphQLNullable<Int>,
      page: GraphQLNullable<Int>,
      statuses: GraphQLNullable<[String]>,
      properties: GraphQLNullable<JSON>
    ) {
      self.identityId = identityId
      self.limit = limit
      self.page = page
      self.statuses = statuses
      self.properties = properties
    }

    public var __variables: Variables? { [
      "identityId": identityId,
      "limit": limit,
      "page": page,
      "statuses": statuses,
      "properties": properties
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("fetchInAppChatConversations", [FetchInAppChatConversation].self, arguments: ["input": [
          "identityId": .variable("identityId"),
          "limit": .variable("limit"),
          "page": .variable("page"),
          "statuses": .variable("statuses"),
          "properties": .variable("properties")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchInAppChatConversationsQuery.Data.self
      ] }

      var fetchInAppChatConversations: [FetchInAppChatConversation] { __data["fetchInAppChatConversations"] }

      init(
        fetchInAppChatConversations: [FetchInAppChatConversation]
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "fetchInAppChatConversations": fetchInAppChatConversations._fieldData,
        ])
      }

      /// FetchInAppChatConversation
      ///
      /// Parent Type: `ChatConversationSummary`
      struct FetchInAppChatConversation: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.ChatConversationSummary }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ChatConversationSummaryFragment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FetchInAppChatConversationsQuery.Data.FetchInAppChatConversation.self,
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