// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SearchRecordsQuery: GraphQLQuery {
    static let operationName: String = "SearchRecords"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchRecords($input: SearchRecordsInput!) { searchRecords(input: $input) }"#
      ))

    public var input: SearchRecordsInput

    public init(input: SearchRecordsInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchRecords", [DashXGql.JSON].self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchRecordsQuery.Data.self
      ] }

      var searchRecords: [DashXGql.JSON] { __data["searchRecords"] }

      init(
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