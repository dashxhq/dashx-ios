// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct FetchStoredPreferencesInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      accountUid: String,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "accountUid": accountUid,
        "targetEnvironment": targetEnvironment
      ])
    }

    public var accountUid: String {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    public var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}