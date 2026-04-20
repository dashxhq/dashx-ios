// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct SaveStoredPreferencesInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      accountUid: String,
      preferenceData: JSON,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "accountUid": accountUid,
        "preferenceData": preferenceData,
        "targetEnvironment": targetEnvironment
      ])
    }

    var accountUid: String {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    var preferenceData: JSON {
      get { __data["preferenceData"] }
      set { __data["preferenceData"] = newValue }
    }

    var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}