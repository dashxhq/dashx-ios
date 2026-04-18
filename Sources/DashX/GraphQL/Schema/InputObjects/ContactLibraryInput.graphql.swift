// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct ContactLibraryInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: GraphQLNullable<String> = nil,
      version: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "version": version
      ])
    }

    public var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var version: GraphQLNullable<String> {
      get { __data["version"] }
      set { __data["version"] = newValue }
    }
  }

}