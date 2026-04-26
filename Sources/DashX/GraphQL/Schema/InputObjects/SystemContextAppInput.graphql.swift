// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct SystemContextAppInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var version: String {
      get { __data["version"] }
      set { __data["version"] = newValue }
    }

    var build: String {
      get { __data["build"] }
      set { __data["build"] = newValue }
    }

    var namespace: String {
      get { __data["namespace"] }
      set { __data["namespace"] = newValue }
    }
  }

}