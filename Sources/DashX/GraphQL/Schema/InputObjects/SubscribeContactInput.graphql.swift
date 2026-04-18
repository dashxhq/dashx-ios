// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SubscribeContactInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      accountUid: GraphQLNullable<String> = nil,
      accountAnonymousUid: GraphQLNullable<String> = nil,
      name: GraphQLNullable<String> = nil,
      kind: GraphQLEnum<ContactKind>,
      value: String,
      userAgent: GraphQLNullable<String> = nil,
      osName: GraphQLNullable<String> = nil,
      osVersion: GraphQLNullable<String> = nil,
      deviceModel: GraphQLNullable<String> = nil,
      deviceManufacturer: GraphQLNullable<String> = nil,
      deviceUid: GraphQLNullable<String> = nil,
      deviceAdvertisingUid: GraphQLNullable<String> = nil,
      isDeviceAdTrackingEnabled: GraphQLNullable<Bool> = nil,
      metadata: GraphQLNullable<ContactMetadataInput> = nil,
      tag: GraphQLNullable<String> = nil,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "accountUid": accountUid,
        "accountAnonymousUid": accountAnonymousUid,
        "name": name,
        "kind": kind,
        "value": value,
        "userAgent": userAgent,
        "osName": osName,
        "osVersion": osVersion,
        "deviceModel": deviceModel,
        "deviceManufacturer": deviceManufacturer,
        "deviceUid": deviceUid,
        "deviceAdvertisingUid": deviceAdvertisingUid,
        "isDeviceAdTrackingEnabled": isDeviceAdTrackingEnabled,
        "metadata": metadata,
        "tag": tag,
        "targetEnvironment": targetEnvironment
      ])
    }

    public var accountUid: GraphQLNullable<String> {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    public var accountAnonymousUid: GraphQLNullable<String> {
      get { __data["accountAnonymousUid"] }
      set { __data["accountAnonymousUid"] = newValue }
    }

    public var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var kind: GraphQLEnum<ContactKind> {
      get { __data["kind"] }
      set { __data["kind"] = newValue }
    }

    public var value: String {
      get { __data["value"] }
      set { __data["value"] = newValue }
    }

    public var userAgent: GraphQLNullable<String> {
      get { __data["userAgent"] }
      set { __data["userAgent"] = newValue }
    }

    public var osName: GraphQLNullable<String> {
      get { __data["osName"] }
      set { __data["osName"] = newValue }
    }

    public var osVersion: GraphQLNullable<String> {
      get { __data["osVersion"] }
      set { __data["osVersion"] = newValue }
    }

    public var deviceModel: GraphQLNullable<String> {
      get { __data["deviceModel"] }
      set { __data["deviceModel"] = newValue }
    }

    public var deviceManufacturer: GraphQLNullable<String> {
      get { __data["deviceManufacturer"] }
      set { __data["deviceManufacturer"] = newValue }
    }

    public var deviceUid: GraphQLNullable<String> {
      get { __data["deviceUid"] }
      set { __data["deviceUid"] = newValue }
    }

    public var deviceAdvertisingUid: GraphQLNullable<String> {
      get { __data["deviceAdvertisingUid"] }
      set { __data["deviceAdvertisingUid"] = newValue }
    }

    public var isDeviceAdTrackingEnabled: GraphQLNullable<Bool> {
      get { __data["isDeviceAdTrackingEnabled"] }
      set { __data["isDeviceAdTrackingEnabled"] = newValue }
    }

    public var metadata: GraphQLNullable<ContactMetadataInput> {
      get { __data["metadata"] }
      set { __data["metadata"] = newValue }
    }

    public var tag: GraphQLNullable<String> {
      get { __data["tag"] }
      set { __data["tag"] = newValue }
    }

    public var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}