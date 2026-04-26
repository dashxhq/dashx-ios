// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class SaveStoredPreferencesMutation: GraphQLMutation {
    static let operationName: String = "SaveStoredPreferences"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SaveStoredPreferences($input: SaveStoredPreferencesInput!) { saveStoredPreferences(input: $input) { __typename success } }"#
      ))

    public var input: SaveStoredPreferencesInput

    public init(input: SaveStoredPreferencesInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("saveStoredPreferences", SaveStoredPreferences.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SaveStoredPreferencesMutation.Data.self
      ] }

      var saveStoredPreferences: SaveStoredPreferences { __data["saveStoredPreferences"] }

      init(
        saveStoredPreferences: SaveStoredPreferences
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "saveStoredPreferences": saveStoredPreferences._fieldData,
        ])
      }

      /// SaveStoredPreferences
      ///
      /// Parent Type: `SaveStoredPreferencesResponse`
      struct SaveStoredPreferences: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.SaveStoredPreferencesResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SaveStoredPreferencesMutation.Data.SaveStoredPreferences.self
        ] }

        var success: Bool { __data["success"] }

        init(
          success: Bool
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.SaveStoredPreferencesResponse.typename,
            "success": success,
          ])
        }
      }
    }
  }

}