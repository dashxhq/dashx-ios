// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct FetchRecordInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var recordId: UUID {
      get { __data["recordId"] }
      set { __data["recordId"] = newValue }
    }

    var resource: GraphQLNullable<String> {
      get { __data["resource"] }
      set { __data["resource"] = newValue }
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