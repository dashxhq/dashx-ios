// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SendInAppChatMessageMutation: GraphQLMutation {
    static let operationName: String = "SendInAppChatMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SendInAppChatMessage($conversationId: UUID!, $identityId: UUID!, $content: JSON!, $clientMessageId: String!) { sendInAppChatMessage( input: { conversationId: $conversationId identityId: $identityId content: $content clientMessageId: $clientMessageId } ) { __typename ...ChatMessageFragment } }"#,
        fragments: [ChatMessageFragment.self]
      ))

    public var conversationId: UUID
    public var identityId: UUID
    public var content: JSON
    public var clientMessageId: String

    public init(
      conversationId: UUID,
      identityId: UUID,
      content: JSON,
      clientMessageId: String
    ) {
      self.conversationId = conversationId
      self.identityId = identityId
      self.content = content
      self.clientMessageId = clientMessageId
    }

    public var __variables: Variables? { [
      "conversationId": conversationId,
      "identityId": identityId,
      "content": content,
      "clientMessageId": clientMessageId
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("sendInAppChatMessage", SendInAppChatMessage.self, arguments: ["input": [
          "conversationId": .variable("conversationId"),
          "identityId": .variable("identityId"),
          "content": .variable("content"),
          "clientMessageId": .variable("clientMessageId")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SendInAppChatMessageMutation.Data.self
      ] }

      var sendInAppChatMessage: SendInAppChatMessage { __data["sendInAppChatMessage"] }

      init(
        sendInAppChatMessage: SendInAppChatMessage
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "sendInAppChatMessage": sendInAppChatMessage._fieldData,
        ])
      }

      /// SendInAppChatMessage
      ///
      /// Parent Type: `Message`
      struct SendInAppChatMessage: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Message }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ChatMessageFragment.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SendInAppChatMessageMutation.Data.SendInAppChatMessage.self,
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