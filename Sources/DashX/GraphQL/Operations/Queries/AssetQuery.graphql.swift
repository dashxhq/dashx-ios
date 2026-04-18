// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class AssetQuery: GraphQLQuery {
    public static let operationName: String = "Asset"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Asset($id: UUID!) { asset(id: $id) { __typename id resourceId attributeId uploadStatus data } }"#
      ))

    public var id: UUID

    public init(id: UUID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("asset", Asset.self, arguments: ["id": .variable("id")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AssetQuery.Data.self
      ] }

      public var asset: Asset { __data["asset"] }

      public init(
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
      public struct Asset: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Asset }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("resourceId", DashXGql.UUID?.self),
          .field("attributeId", DashXGql.UUID?.self),
          .field("uploadStatus", GraphQLEnum<DashXGql.AssetUploadStatus>.self),
          .field("data", DashXGql.JSON.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AssetQuery.Data.Asset.self
        ] }

        public var id: DashXGql.UUID { __data["id"] }
        public var resourceId: DashXGql.UUID? { __data["resourceId"] }
        public var attributeId: DashXGql.UUID? { __data["attributeId"] }
        public var uploadStatus: GraphQLEnum<DashXGql.AssetUploadStatus> { __data["uploadStatus"] }
        public var data: DashXGql.JSON { __data["data"] }

        public init(
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