// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct IdentifyAccountInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      uid: GraphQLNullable<String> = nil,
      anonymousUid: GraphQLNullable<String> = nil,
      email: GraphQLNullable<String> = nil,
      phone: GraphQLNullable<String> = nil,
      name: GraphQLNullable<String> = nil,
      firstName: GraphQLNullable<String> = nil,
      lastName: GraphQLNullable<String> = nil,
      systemContext: GraphQLNullable<SystemContextInput> = nil,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "uid": uid,
        "anonymousUid": anonymousUid,
        "email": email,
        "phone": phone,
        "name": name,
        "firstName": firstName,
        "lastName": lastName,
        "systemContext": systemContext,
        "targetEnvironment": targetEnvironment
      ])
    }

    var uid: GraphQLNullable<String> {
      get { __data["uid"] }
      set { __data["uid"] = newValue }
    }

    var anonymousUid: GraphQLNullable<String> {
      get { __data["anonymousUid"] }
      set { __data["anonymousUid"] = newValue }
    }

    var email: GraphQLNullable<String> {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var firstName: GraphQLNullable<String> {
      get { __data["firstName"] }
      set { __data["firstName"] = newValue }
    }

    var lastName: GraphQLNullable<String> {
      get { __data["lastName"] }
      set { __data["lastName"] = newValue }
    }

    var systemContext: GraphQLNullable<SystemContextInput> {
      get { __data["systemContext"] }
      set { __data["systemContext"] = newValue }
    }

    var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}