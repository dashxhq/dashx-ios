// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class MarkInAppChatConversationReadMutation: GraphQLMutation {
    static let operationName: String = "MarkInAppChatConversationRead"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkInAppChatConversationRead($identityId: UUID!, $conversationId: UUID!, $lastMessageId: UUID!) { markInAppChatConversationRead( input: { identityId: $identityId conversationId: $conversationId lastMessageId: $lastMessageId } ) { __typename success } }"#
      ))

    public var identityId: UUID
    public var conversationId: UUID
    public var lastMessageId: UUID

    public init(
      identityId: UUID,
      conversationId: UUID,
      lastMessageId: UUID
    ) {
      self.identityId = identityId
      self.conversationId = conversationId
      self.lastMessageId = lastMessageId
    }

    public var __variables: Variables? { [
      "identityId": identityId,
      "conversationId": conversationId,
      "lastMessageId": lastMessageId
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markInAppChatConversationRead", MarkInAppChatConversationRead.self, arguments: ["input": [
          "identityId": .variable("identityId"),
          "conversationId": .variable("conversationId"),
          "lastMessageId": .variable("lastMessageId")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkInAppChatConversationReadMutation.Data.self
      ] }

      var markInAppChatConversationRead: MarkInAppChatConversationRead { __data["markInAppChatConversationRead"] }

      init(
        markInAppChatConversationRead: MarkInAppChatConversationRead
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "markInAppChatConversationRead": markInAppChatConversationRead._fieldData,
        ])
      }

      /// MarkInAppChatConversationRead
      ///
      /// Parent Type: `MarkInAppChatConversationReadResponse`
      struct MarkInAppChatConversationRead: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.MarkInAppChatConversationReadResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkInAppChatConversationReadMutation.Data.MarkInAppChatConversationRead.self
        ] }

        var success: Bool { __data["success"] }

        init(
          success: Bool
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.MarkInAppChatConversationReadResponse.typename,
            "success": success,
          ])
        }
      }
    }
  }

}