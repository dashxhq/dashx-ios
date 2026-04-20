// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SystemContextOsInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      name: String,
      version: String
    ) {
      __data = InputDict([
        "name": name,
        "version": version
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
  }

}