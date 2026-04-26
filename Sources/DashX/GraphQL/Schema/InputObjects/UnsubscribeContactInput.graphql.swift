// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct UnsubscribeContactInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var accountUid: GraphQLNullable<String> {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    var accountAnonymousUid: GraphQLNullable<String> {
      get { __data["accountAnonymousUid"] }
      set { __data["accountAnonymousUid"] = newValue }
    }

    var value: String {
      get { __data["value"] }
      set { __data["value"] = newValue }
    }

    var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}