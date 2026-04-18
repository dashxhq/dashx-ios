// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct ContactMetadataInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      library: GraphQLNullable<ContactLibraryInput> = nil,
      osName: GraphQLNullable<String> = nil,
      osVersion: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "library": library,
        "osName": osName,
        "osVersion": osVersion
      ])
    }

    public var library: GraphQLNullable<ContactLibraryInput> {
      get { __data["library"] }
      set { __data["library"] = newValue }
    }

    public var osName: GraphQLNullable<String> {
      get { __data["osName"] }
      set { __data["osName"] = newValue }
    }

    public var osVersion: GraphQLNullable<String> {
      get { __data["osVersion"] }
      set { __data["osVersion"] = newValue }
    }
  }

}