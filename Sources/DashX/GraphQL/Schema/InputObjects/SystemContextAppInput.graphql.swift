// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextAppInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String,
      version: String,
      build: String,
      namespace: String
    ) {
      __data = InputDict([
        "name": name,
        "version": version,
        "build": build,
        "namespace": namespace
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

    public var build: String {
      get { __data["build"] }
      set { __data["build"] = newValue }
    }

    public var namespace: String {
      get { __data["namespace"] }
      set { __data["namespace"] = newValue }
    }
  }

}