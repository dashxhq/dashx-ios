// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SystemContextScreenInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      width: Int,
      height: Int,
      density: Int
    ) {
      __data = InputDict([
        "width": width,
        "height": height,
        "density": density
      ])
    }

    var width: Int {
      get { __data["width"] }
      set { __data["width"] = newValue }
    }

    var height: Int {
      get { __data["height"] }
      set { __data["height"] = newValue }
    }

    var density: Int {
      get { __data["density"] }
      set { __data["density"] = newValue }
    }
  }

}