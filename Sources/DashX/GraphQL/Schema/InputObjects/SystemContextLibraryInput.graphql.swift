// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextLibraryInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String,
      version: String
    ) {
      __data = InputDict([
        "name": name,
        "version": version
      ])
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var version: String {
      get { __data["version"] }
      set { __data["version"] = newValue }
    }
  }

}