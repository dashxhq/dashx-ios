// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SearchRecordsInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var resource: String {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
    }

    var filter: GraphQLNullable<JSON> {
      get { __data["filter"] }
      set { __data["filter"] = newValue }
    }

    var order: GraphQLNullable<[JSON]> {
      get { __data["order"] }
      set { __data["order"] = newValue }
    }

    var limit: GraphQLNullable<Int> {
      get { __data["limit"] }
      set { __data["limit"] = newValue }
    }

    var page: GraphQLNullable<Int> {
      get { __data["page"] }
      set { __data["page"] = newValue }
    }

    var preview: GraphQLNullable<Bool> {
      get { __data["preview"] }
      set { __data["preview"] = newValue }
    }

    var language: GraphQLNullable<String> {
      get { __data["language"] }
      set { __data["language"] = newValue }
    }

    var fields: GraphQLNullable<[JSON]> {
      get { __data["fields"] }
      set { __data["fields"] = newValue }
    }

    var include: GraphQLNullable<[JSON]> {
      get { __data["include"] }
      set { __data["include"] = newValue }
    }

    var exclude: GraphQLNullable<[JSON]> {
      get { __data["exclude"] }
      set { __data["exclude"] = newValue }
    }
  }

}