// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextDeviceInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
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

    public var id: String {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    public var advertisingId: String {
      get { __data["advertisingId"] }
      set { __data["advertisingId"] = newValue }
    }

    public var adTrackingEnabled: Bool {
      get { __data["adTrackingEnabled"] }
      set { __data["adTrackingEnabled"] = newValue }
    }

    public var manufacturer: String {
      get { __data["manufacturer"] }
      set { __data["manufacturer"] = newValue }
    }

    public var model: String {
      get { __data["model"] }
      set { __data["model"] = newValue }
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var kind: String {
      get { __data["kind"] }
      set { __data["kind"] = newValue }
    }
  }

}