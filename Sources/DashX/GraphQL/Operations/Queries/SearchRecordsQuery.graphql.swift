// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class SearchRecordsQuery: GraphQLQuery {
    public static let operationName: String = "SearchRecords"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchRecords($input: SearchRecordsInput!) { searchRecords(input: $input) }"#
      ))

    public var input: SearchRecordsInput

    public init(input: SearchRecordsInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("searchRecords", [DashXGql.JSON].self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchRecordsQuery.Data.self
      ] }

      public var searchRecords: [DashXGql.JSON] { __data["searchRecords"] }

      public init(
        searchRecords: [DashXGql.JSON]
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "searchRecords": searchRecords,
        ])
      }
    }
  }

}