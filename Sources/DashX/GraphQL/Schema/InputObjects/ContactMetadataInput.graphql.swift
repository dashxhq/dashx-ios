// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct ContactMetadataInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      app: GraphQLNullable<ContactAppInput> = nil,
      library: GraphQLNullable<ContactLibraryInput> = nil,
      osName: GraphQLNullable<String> = nil,
      osVersion: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "app": app,
        "library": library,
        "osName": osName,
        "osVersion": osVersion
      ])
    }

    var app: GraphQLNullable<ContactAppInput> {
      get { __data["app"] }
      set { __data["app"] = newValue }
    }

    var library: GraphQLNullable<ContactLibraryInput> {
      get { __data["library"] }
      set { __data["library"] = newValue }
    }

    var osName: GraphQLNullable<String> {
      get { __data["osName"] }
      set { __data["osName"] = newValue }
    }

    var osVersion: GraphQLNullable<String> {
      get { __data["osVersion"] }
      set { __data["osVersion"] = newValue }
    }
  }

}