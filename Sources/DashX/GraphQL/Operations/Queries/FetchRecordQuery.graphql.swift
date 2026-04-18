// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class FetchRecordQuery: GraphQLQuery {
    public static let operationName: String = "FetchRecord"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchRecord($input: FetchRecordInput!) { fetchRecord(input: $input) }"#
      ))

    public var input: FetchRecordInput

    public init(input: FetchRecordInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("fetchRecord", DashXGql.JSON.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchRecordQuery.Data.self
      ] }

      public var fetchRecord: DashXGql.JSON { __data["fetchRecord"] }

      public init(
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