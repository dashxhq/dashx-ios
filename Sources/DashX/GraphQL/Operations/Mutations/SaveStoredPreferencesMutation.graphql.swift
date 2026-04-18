// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class SaveStoredPreferencesMutation: GraphQLMutation {
    public static let operationName: String = "SaveStoredPreferences"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SaveStoredPreferences($input: SaveStoredPreferencesInput!) { saveStoredPreferences(input: $input) { __typename success } }"#
      ))

    public var input: SaveStoredPreferencesInput

    public init(input: SaveStoredPreferencesInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("saveStoredPreferences", SaveStoredPreferences.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SaveStoredPreferencesMutation.Data.self
      ] }

      public var saveStoredPreferences: SaveStoredPreferences { __data["saveStoredPreferences"] }

      public init(
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
      public struct SaveStoredPreferences: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.SaveStoredPreferencesResponse }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SaveStoredPreferencesMutation.Data.SaveStoredPreferences.self
        ] }

        public var success: Bool { __data["success"] }

        public init(
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