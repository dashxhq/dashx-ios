// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SummarizeInAppChatUnreadQuery: GraphQLQuery {
    static let operationName: String = "SummarizeInAppChatUnread"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SummarizeInAppChatUnread($identityId: UUID!) { summarizeInAppChatUnread(input: { identityId: $identityId }) { __typename count } }"#
      ))

    public var identityId: UUID

    public init(identityId: UUID) {
      self.identityId = identityId
    }

    public var __variables: Variables? { ["identityId": identityId] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("summarizeInAppChatUnread", SummarizeInAppChatUnread.self, arguments: ["input": ["identityId": .variable("identityId")]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SummarizeInAppChatUnreadQuery.Data.self
      ] }

      var summarizeInAppChatUnread: SummarizeInAppChatUnread { __data["summarizeInAppChatUnread"] }

      init(
        summarizeInAppChatUnread: SummarizeInAppChatUnread
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "summarizeInAppChatUnread": summarizeInAppChatUnread._fieldData,
        ])
      }

      /// SummarizeInAppChatUnread
      ///
      /// Parent Type: `SummarizeInAppChatUnreadResponse`
      struct SummarizeInAppChatUnread: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.SummarizeInAppChatUnreadResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SummarizeInAppChatUnreadQuery.Data.SummarizeInAppChatUnread.self
        ] }

        var count: Int { __data["count"] }

        init(
          count: Int
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.SummarizeInAppChatUnreadResponse.typename,
            "count": count,
          ])
        }
      }
    }
  }

}