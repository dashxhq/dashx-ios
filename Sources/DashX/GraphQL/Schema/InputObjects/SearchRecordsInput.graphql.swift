// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SearchRecordsInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      resource: String,
      filter: GraphQLNullable<JSON> = nil,
      order: GraphQLNullable<[JSON]> = nil,
      limit: GraphQLNullable<Int> = nil,
      page: GraphQLNullable<Int> = nil,
      preview: GraphQLNullable<Bool> = nil,
      language: GraphQLNullable<String> = nil,
      fields: GraphQLNullable<[JSON]> = nil,
      include: GraphQLNullable<[JSON]> = nil,
      exclude: GraphQLNullable<[JSON]> = nil
    ) {
      __data = InputDict([
        "resource": resource,
        "filter": filter,
        "order": order,
        "limit": limit,
        "page": page,
        "preview": preview,
        "language": language,
        "fields": fields,
        "include": include,
        "exclude": exclude
      ])
    }

    public var resource: String {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
    }

    public var filter: GraphQLNullable<JSON> {
      get { __data["filter"] }
      set { __data["filter"] = newValue }
    }

    public var order: GraphQLNullable<[JSON]> {
      get { __data["order"] }
      set { __data["order"] = newValue }
    }

    public var limit: GraphQLNullable<Int> {
      get { __data["limit"] }
      set { __data["limit"] = newValue }
    }

    public var page: GraphQLNullable<Int> {
      get { __data["page"] }
      set { __data["page"] = newValue }
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