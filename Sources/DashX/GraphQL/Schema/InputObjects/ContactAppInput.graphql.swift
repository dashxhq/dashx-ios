// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct ContactAppInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      identifier: GraphQLNullable<String> = nil,
      name: GraphQLNullable<String> = nil,
      version: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "identifier": identifier,
        "name": name,
        "version": version
      ])
    }

    var identifier: GraphQLNullable<String> {
      get { __data["identifier"] }
      set { __data["identifier"] = newValue }
    }

    var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var version: GraphQLNullable<String> {
      get { __data["version"] }
      set { __data["version"] = newValue }
    }
  }

}