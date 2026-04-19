// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class FetchStoredPreferencesQuery: GraphQLQuery {
    static let operationName: String = "FetchStoredPreferences"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query FetchStoredPreferences($input: FetchStoredPreferencesInput!) { fetchStoredPreferences(input: $input) { __typename preferenceData } }"#
      ))

    public var input: FetchStoredPreferencesInput

    public init(input: FetchStoredPreferencesInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("fetchStoredPreferences", FetchStoredPreferences.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FetchStoredPreferencesQuery.Data.self
      ] }

      var fetchStoredPreferences: FetchStoredPreferences { __data["fetchStoredPreferences"] }

      init(
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
      struct FetchStoredPreferences: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.FetchStoredPreferencesResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("preferenceData", DashXGql.JSON.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FetchStoredPreferencesQuery.Data.FetchStoredPreferences.self
        ] }

        var preferenceData: DashXGql.JSON { __data["preferenceData"] }

        init(
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