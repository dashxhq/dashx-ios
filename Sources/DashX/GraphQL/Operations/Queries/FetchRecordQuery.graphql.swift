// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension DashXGql {
  class FetchRecordQuery: GraphQLQuery {
    static let operationName: String = "FetchRecord"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchRecord($input: FetchRecordInput!) { fetchRecord(input: $input) }"#
      ))

    public var input: FetchRecordInput

    public init(input: FetchRecordInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("fetchRecord", DashXGql.JSON.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchRecordQuery.Data.self
      ] }

      var fetchRecord: DashXGql.JSON { __data["fetchRecord"] }

      init(
        fetchRecord: DashXGql.JSON
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "fetchRecord": fetchRecord,
        ])
      }
    }
  }

}