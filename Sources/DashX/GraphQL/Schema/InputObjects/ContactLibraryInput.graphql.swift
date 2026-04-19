// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct ContactLibraryInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: GraphQLNullable<String> = nil,
      version: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "version": version
      ])
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