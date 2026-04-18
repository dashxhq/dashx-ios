// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class FetchStoredPreferencesQuery: GraphQLQuery {
    public static let operationName: String = "FetchStoredPreferences"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchStoredPreferences($input: FetchStoredPreferencesInput!) { fetchStoredPreferences(input: $input) { __typename preferenceData } }"#
      ))

    public var input: FetchStoredPreferencesInput

    public init(input: FetchStoredPreferencesInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("fetchStoredPreferences", FetchStoredPreferences.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchStoredPreferencesQuery.Data.self
      ] }

      public var fetchStoredPreferences: FetchStoredPreferences { __data["fetchStoredPreferences"] }

      public init(
        fetchStoredPreferences: FetchStoredPreferences
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "fetchStoredPreferences": fetchStoredPreferences._fieldData,
        ])
      }

      /// FetchStoredPreferences
      ///
      /// Parent Type: `FetchStoredPreferencesResponse`
      public struct FetchStoredPreferences: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.FetchStoredPreferencesResponse }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("preferenceData", DashXGql.JSON.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FetchStoredPreferencesQuery.Data.FetchStoredPreferences.self
        ] }

        public var preferenceData: DashXGql.JSON { __data["preferenceData"] }

        public init(
          preferenceData: DashXGql.JSON
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.FetchStoredPreferencesResponse.typename,
            "preferenceData": preferenceData,
          ])
        }
      }
    }
  }

}