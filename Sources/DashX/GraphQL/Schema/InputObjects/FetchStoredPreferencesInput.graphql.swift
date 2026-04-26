// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct FetchStoredPreferencesInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      accountUid: String,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "accountUid": accountUid,
        "targetEnvironment": targetEnvironment
      ])
    }

    var accountUid: String {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}