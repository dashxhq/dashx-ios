// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class FetchInAppChatMessagesQuery: GraphQLQuery {
    static let operationName: String = "FetchInAppChatMessages"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchInAppChatMessages($conversationId: UUID!, $limit: Int, $page: Int, $afterMessageId: UUID) { fetchInAppChatMessages( input: { conversationId: $conversationId limit: $limit page: $page afterMessageId: $afterMessageId } ) { __typename ...ChatMessageFragment } }"#,
        fragments: [ChatMessageFragment.self]
      ))

    public var conversationId: UUID
    public var limit: GraphQLNullable<Int>
    public var page: GraphQLNullable<Int>
    public var afterMessageId: GraphQLNullable<UUID>

    public init(
      conversationId: UUID,
      limit: GraphQLNullable<Int>,
      page: GraphQLNullable<Int>,
      afterMessageId: GraphQLNullable<UUID>
    ) {
      self.conversationId = conversationId
      self.limit = limit
      self.page = page
      self.afterMessageId = afterMessageId
    }

    public var __variables: Variables? { [
      "conversationId": conversationId,
      "limit": limit,
      "page": page,
      "afterMessageId": afterMessageId
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("fetchInAppChatMessages", [FetchInAppChatMessage].self, arguments: ["input": [
          "conversationId": .variable("conversationId"),
          "limit": .variable("limit"),
          "page": .variable("page"),
          "afterMessageId": .variable("afterMessageId")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchInAppChatMessagesQuery.Data.self
      ] }

      var fetchInAppChatMessages: [FetchInAppChatMessage] { __data["fetchInAppChatMessages"] }

      init(
        fetchInAppChatMessages: [FetchInAppChatMessage]
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "fetchInAppChatMessages": fetchInAppChatMessages._fieldData,
        ])
      }

      /// FetchInAppChatMessage
      ///
      /// Parent Type: `Message`
      struct FetchInAppChatMessage: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ChatMessageFragment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FetchInAppChatMessagesQuery.Data.FetchInAppChatMessage.self,
          ChatMessageFragment.self
        ] }

        var id: DashXGql.UUID { __data["id"] }
        var conversationId: DashXGql.UUID? { __data["conversationId"] }
        var renderedContent: DashXGql.JSON { __data["renderedContent"] }
        var externalUid: String? { __data["externalUid"] }
        var senderId: DashXGql.UUID? { __data["senderId"] }
        var aiRole: String? { __data["aiRole"] }
        var turnSeq: Int { __data["turnSeq"] }
        var sentAt: DashXGql.Timestamp? { __data["sentAt"] }
        var createdAt: DashXGql.Timestamp { __data["createdAt"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var chatMessageFragment: ChatMessageFragment { _toFragment() }
        }

        init(
          id: DashXGql.UUID,
          conversationId: DashXGql.UUID? = nil,
          renderedContent: DashXGql.JSON,
          externalUid: String? = nil,
          senderId: DashXGql.UUID? = nil,
          aiRole: String? = nil,
          turnSeq: Int,
          sentAt: DashXGql.Timestamp? = nil,
          createdAt: DashXGql.Timestamp
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.Message.typename,
            "id": id,
            "conversationId": conversationId,
            "renderedContent": renderedContent,
            "externalUid": externalUid,
            "senderId": senderId,
            "aiRole": aiRole,
            "turnSeq": turnSeq,
            "sentAt": sentAt,
            "createdAt": createdAt,
          ])
        }
      }
    }
  }

}