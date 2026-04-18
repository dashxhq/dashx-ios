// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct PrepareAssetInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      resource: GraphQLNullable<String> = nil,
      attribute: GraphQLNullable<String> = nil,
      operation: GraphQLNullable<String> = nil,
      parameter: GraphQLNullable<String> = nil,
      name: String,
      size: Int,
      mimeType: String,
      width: GraphQLNullable<Int> = nil,
      height: GraphQLNullable<Int> = nil,
      externalUid: GraphQLNullable<String> = nil,
      externalMetadata: GraphQLNullable<JSON> = nil,
      targetEnvironment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "resource": resource,
        "attribute": attribute,
        "operation": operation,
        "parameter": parameter,
        "name": name,
        "size": size,
        "mimeType": mimeType,
        "width": width,
        "height": height,
        "externalUid": externalUid,
        "externalMetadata": externalMetadata,
        "targetEnvironment": targetEnvironment
      ])
    }

    public var resource: GraphQLNullable<String> {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
    }

    public var attribute: GraphQLNullable<String> {
      get { __data["attribute"] }
      set { __data["attribute"] = newValue }
    }

    public var operation: GraphQLNullable<String> {
      get { __data["operation"] }
      set { __data["operation"] = newValue }
    }

    public var parameter: GraphQLNullable<String> {
      get { __data["parameter"] }
      set { __data["parameter"] = newValue }
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var size: Int {
      get { __data["size"] }
      set { __data["size"] = newValue }
    }

    public var mimeType: String {
      get { __data["mimeType"] }
      set { __data["mimeType"] = newValue }
    }

    public var width: GraphQLNullable<Int> {
      get { __data["width"] }
      set { __data["width"] = newValue }
    }

    public var height: GraphQLNullable<Int> {
      get { __data["height"] }
      set { __data["height"] = newValue }
    }

    public var externalUid: GraphQLNullable<String> {
      get { __data["externalUid"] }
      set { __data["externalUid"] = newValue }
    }

    public var externalMetadata: GraphQLNullable<JSON> {
      get { __data["externalMetadata"] }
      set { __data["externalMetadata"] = newValue }
    }

    public var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}