// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SummarizeInAppChatMessagesQuery: GraphQLQuery {
    static let operationName: String = "SummarizeInAppChatMessages"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SummarizeInAppChatMessages($conversationId: UUID!) { summarizeInAppChatMessages(input: { conversationId: $conversationId }) { __typename count } }"#
      ))

    public var conversationId: UUID

    public init(conversationId: UUID) {
      self.conversationId = conversationId
    }

    public var __variables: Variables? { ["conversationId": conversationId] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("summarizeInAppChatMessages", SummarizeInAppChatMessages.self, arguments: ["input": ["conversationId": .variable("conversationId")]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SummarizeInAppChatMessagesQuery.Data.self
      ] }

      var summarizeInAppChatMessages: SummarizeInAppChatMessages { __data["summarizeInAppChatMessages"] }

      init(
        summarizeInAppChatMessages: SummarizeInAppChatMessages
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "summarizeInAppChatMessages": summarizeInAppChatMessages._fieldData,
        ])
      }

      /// SummarizeInAppChatMessages
      ///
      /// Parent Type: `SummarizeInAppChatMessagesResponse`
      struct SummarizeInAppChatMessages: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.SummarizeInAppChatMessagesResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SummarizeInAppChatMessagesQuery.Data.SummarizeInAppChatMessages.self
        ] }

        var count: Int { __data["count"] }

        init(
          count: Int
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.SummarizeInAppChatMessagesResponse.typename,
            "count": count,
          ])
        }
      }
    }
  }

}