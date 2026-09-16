// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SummarizeInAppChatConversationsQuery: GraphQLQuery {
    static let operationName: String = "SummarizeInAppChatConversations"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SummarizeInAppChatConversations($identityId: UUID!, $statuses: [String!], $properties: JSON) { summarizeInAppChatConversations( input: { identityId: $identityId, statuses: $statuses, properties: $properties } ) { __typename count } }"#
      ))

    public var identityId: UUID
    public var statuses: GraphQLNullable<[String]>
    public var properties: GraphQLNullable<JSON>

    public init(
      identityId: UUID,
      statuses: GraphQLNullable<[String]>,
      properties: GraphQLNullable<JSON>
    ) {
      self.identityId = identityId
      self.statuses = statuses
      self.properties = properties
    }

    public var __variables: Variables? { [
      "identityId": identityId,
      "statuses": statuses,
      "properties": properties
    ] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("summarizeInAppChatConversations", SummarizeInAppChatConversations.self, arguments: ["input": [
          "identityId": .variable("identityId"),
          "statuses": .variable("statuses"),
          "properties": .variable("properties")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SummarizeInAppChatConversationsQuery.Data.self
      ] }

      var summarizeInAppChatConversations: SummarizeInAppChatConversations { __data["summarizeInAppChatConversations"] }

      init(
        summarizeInAppChatConversations: SummarizeInAppChatConversations
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "summarizeInAppChatConversations": summarizeInAppChatConversations._fieldData,
        ])
      }

      /// SummarizeInAppChatConversations
      ///
      /// Parent Type: `SummarizeInAppChatConversationsResponse`
      struct SummarizeInAppChatConversations: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.SummarizeInAppChatConversationsResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("count", Int.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SummarizeInAppChatConversationsQuery.Data.SummarizeInAppChatConversations.self
        ] }

        var count: Int { __data["count"] }

        init(
          count: Int
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.SummarizeInAppChatConversationsResponse.typename,
            "count": count,
          ])
        }
      }
    }
  }

}