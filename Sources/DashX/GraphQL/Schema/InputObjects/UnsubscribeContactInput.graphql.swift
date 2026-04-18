// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct UnsubscribeContactInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      accountUid: GraphQLNullable<String> = nil,
      accountAnonymousUid: GraphQLNullable<String> = nil,
      value: String,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "accountUid": accountUid,
        "accountAnonymousUid": accountAnonymousUid,
        "value": value,
        "targetEnvironment": targetEnvironment
      ])
    }

    public var accountUid: GraphQLNullable<String> {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    public var accountAnonymousUid: GraphQLNullable<String> {
      get { __data["accountAnonymousUid"] }
      set { __data["accountAnonymousUid"] = newValue }
    }

    public var value: String {
      get { __data["value"] }
      set { __data["value"] = newValue }
    }

    public var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}