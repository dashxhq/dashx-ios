// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class AssetQuery: GraphQLQuery {
    static let operationName: String = "Asset"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Asset($id: UUID!) { asset(id: $id) { __typename id resourceId attributeId uploadStatus data } }"#
      ))

    public var id: UUID

    public init(id: UUID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("asset", Asset.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AssetQuery.Data.self
      ] }

      var asset: Asset { __data["asset"] }

      init(
        asset: Asset
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Query.typename,
          "asset": asset._fieldData,
        ])
      }

      /// Asset
      ///
      /// Parent Type: `Asset`
      struct Asset: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Asset }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("resourceId", DashXGql.UUID?.self),
          .field("attributeId", DashXGql.UUID?.self),
          .field("uploadStatus", GraphQLEnum<DashXGql.AssetUploadStatus>.self),
          .field("data", DashXGql.JSON.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AssetQuery.Data.Asset.self
        ] }

        var id: DashXGql.UUID { __data["id"] }
        var resourceId: DashXGql.UUID? { __data["resourceId"] }
        var attributeId: DashXGql.UUID? { __data["attributeId"] }
        var uploadStatus: GraphQLEnum<DashXGql.AssetUploadStatus> { __data["uploadStatus"] }
        var data: DashXGql.JSON { __data["data"] }

        init(
          id: DashXGql.UUID,
          resourceId: DashXGql.UUID? = nil,
          attributeId: DashXGql.UUID? = nil,
          uploadStatus: GraphQLEnum<DashXGql.AssetUploadStatus>,
          data: DashXGql.JSON
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.Asset.typename,
            "id": id,
            "resourceId": resourceId,
            "attributeId": attributeId,
            "uploadStatus": uploadStatus,
            "data": data,
          ])
        }
      }
    }
  }

}