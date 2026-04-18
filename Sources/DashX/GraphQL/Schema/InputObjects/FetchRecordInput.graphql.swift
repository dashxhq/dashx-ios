// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct FetchRecordInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      recordId: UUID,
      resource: GraphQLNullable<String> = nil,
      preview: GraphQLNullable<Bool> = nil,
      language: GraphQLNullable<String> = nil,
      fields: GraphQLNullable<[JSON]> = nil,
      include: GraphQLNullable<[JSON]> = nil,
      exclude: GraphQLNullable<[JSON]> = nil
    ) {
      __data = InputDict([
        "recordId": recordId,
        "resource": resource,
        "preview": preview,
        "language": language,
        "fields": fields,
        "include": include,
        "exclude": exclude
      ])
    }

    public var recordId: UUID {
      get { __data["recordId"] }
      set { __data["recordId"] = newValue }
    }

    public var resource: GraphQLNullable<String> {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
    }

    public var preview: GraphQLNullable<Bool> {
      get { __data["preview"] }
      set { __data["preview"] = newValue }
    }

    public var language: GraphQLNullable<String> {
      get { __data["language"] }
      set { __data["language"] = newValue }
    }

    public var fields: GraphQLNullable<[JSON]> {
      get { __data["fields"] }
      set { __data["fields"] = newValue }
    }

    public var include: GraphQLNullable<[JSON]> {
      get { __data["include"] }
      set { __data["include"] = newValue }
    }

    public var exclude: GraphQLNullable<[JSON]> {
      get { __data["exclude"] }
      set { __data["exclude"] = newValue }
    }
  }

}