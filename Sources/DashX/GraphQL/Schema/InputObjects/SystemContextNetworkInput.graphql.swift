// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SystemContextNetworkInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var bluetooth: Bool {
      get { __data["bluetooth"] }
      set { __data["bluetooth"] = newValue }
    }

    var carrier: String {
      get { __data["carrier"] }
      set { __data["carrier"] = newValue }
    }

    var cellular: Bool {
      get { __data["cellular"] }
      set { __data["cellular"] = newValue }
    }

    var wifi: Bool {
      get { __data["wifi"] }
      set { __data["wifi"] = newValue }
    }
  }

}