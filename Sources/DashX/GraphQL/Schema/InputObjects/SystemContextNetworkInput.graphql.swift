// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextNetworkInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      bluetooth: Bool,
      carrier: String,
      cellular: Bool,
      wifi: Bool
    ) {
      __data = InputDict([
        "bluetooth": bluetooth,
        "carrier": carrier,
        "cellular": cellular,
        "wifi": wifi
      ])
    }

    public var bluetooth: Bool {
      get { __data["bluetooth"] }
      set { __data["bluetooth"] = newValue }
    }

    public var carrier: String {
      get { __data["carrier"] }
      set { __data["carrier"] = newValue }
    }

    public var cellular: Bool {
      get { __data["cellular"] }
      set { __data["cellular"] = newValue }
    }

    public var wifi: Bool {
      get { __data["wifi"] }
      set { __data["wifi"] = newValue }
    }
  }

}