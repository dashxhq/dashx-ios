// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct PrepareAssetInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var resource: GraphQLNullable<String> {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
    }

    var attribute: GraphQLNullable<String> {
      get { __data["attribute"] }
      set { __data["attribute"] = newValue }
    }

    var operation: GraphQLNullable<String> {
      get { __data["operation"] }
      set { __data["operation"] = newValue }
    }

    var parameter: GraphQLNullable<String> {
      get { __data["parameter"] }
      set { __data["parameter"] = newValue }
    }

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var size: Int {
      get { __data["size"] }
      set { __data["size"] = newValue }
    }

    var mimeType: String {
      get { __data["mimeType"] }
      set { __data["mimeType"] = newValue }
    }

    var width: GraphQLNullable<Int> {
      get { __data["width"] }
      set { __data["width"] = newValue }
    }

    var height: GraphQLNullable<Int> {
      get { __data["height"] }
      set { __data["height"] = newValue }
    }

    var externalUid: GraphQLNullable<String> {
      get { __data["externalUid"] }
      set { __data["externalUid"] = newValue }
    }

    var externalMetadata: GraphQLNullable<JSON> {
      get { __data["externalMetadata"] }
      set { __data["externalMetadata"] = newValue }
    }

    var targetEnvironment: GraphQLNullable<String> {
      get { __data["targetEnvironment"] }
      set { __data["targetEnvironment"] = newValue }
    }
  }

}