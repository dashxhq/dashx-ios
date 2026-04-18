// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextScreenInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
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

    public var width: Int {
      get { __data["width"] }
      set { __data["width"] = newValue }
    }

    public var height: Int {
      get { __data["height"] }
      set { __data["height"] = newValue }
    }

    public var density: Int {
      get { __data["density"] }
      set { __data["density"] = newValue }
    }
  }

}