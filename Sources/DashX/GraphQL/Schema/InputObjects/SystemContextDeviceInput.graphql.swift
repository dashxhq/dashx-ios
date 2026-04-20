// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SystemContextDeviceInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      id: String,
      advertisingId: String,
      adTrackingEnabled: Bool,
      manufacturer: String,
      model: String,
      name: String,
      kind: String
    ) {
      __data = InputDict([
        "id": id,
        "advertisingId": advertisingId,
        "adTrackingEnabled": adTrackingEnabled,
        "manufacturer": manufacturer,
        "model": model,
        "name": name,
        "kind": kind
      ])
    }

    var id: String {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    var advertisingId: String {
      get { __data["advertisingId"] }
      set { __data["advertisingId"] = newValue }
    }

    var adTrackingEnabled: Bool {
      get { __data["adTrackingEnabled"] }
      set { __data["adTrackingEnabled"] = newValue }
    }

    var manufacturer: String {
      get { __data["manufacturer"] }
      set { __data["manufacturer"] = newValue }
    }

    var model: String {
      get { __data["model"] }
      set { __data["model"] = newValue }
    }

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var kind: String {
      get { __data["kind"] }
      set { __data["kind"] = newValue }
    }
  }

}