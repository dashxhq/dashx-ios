// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension DashXGql {
  class PrepareAssetMutation: GraphQLMutation {
    static let operationName: String = "PrepareAsset"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation PrepareAsset($input: PrepareAssetInput!) { prepareAsset(input: $input) { __typename id resourceId attributeId storageProviderId uploadStatus data createdAt updatedAt } }"#
      ))

    public var input: PrepareAssetInput

    public init(input: PrepareAssetInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("prepareAsset", PrepareAsset.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PrepareAssetMutation.Data.self
      ] }

      var prepareAsset: PrepareAsset { __data["prepareAsset"] }

      init(
        prepareAsset: PrepareAsset
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "prepareAsset": prepareAsset._fieldData,
        ])
      }

      /// PrepareAsset
      ///
      /// Parent Type: `Asset`
      struct PrepareAsset: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Asset }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("resourceId", DashXGql.UUID?.self),
          .field("attributeId", DashXGql.UUID?.self),
          .field("storageProviderId", DashXGql.UUID?.self),
          .field("uploadStatus", GraphQLEnum<DashXGql.AssetUploadStatus>.self),
          .field("data", DashXGql.JSON.self),
          .field("createdAt", DashXGql.Timestamp.self),
          .field("updatedAt", DashXGql.Timestamp.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PrepareAssetMutation.Data.PrepareAsset.self
        ] }

        var id: DashXGql.UUID { __data["id"] }
        var resourceId: DashXGql.UUID? { __data["resourceId"] }
        var attributeId: DashXGql.UUID? { __data["attributeId"] }
        var storageProviderId: DashXGql.UUID? { __data["storageProviderId"] }
        var uploadStatus: GraphQLEnum<DashXGql.AssetUploadStatus> { __data["uploadStatus"] }
        var data: DashXGql.JSON { __data["data"] }
        var createdAt: DashXGql.Timestamp { __data["createdAt"] }
        var updatedAt: DashXGql.Timestamp { __data["updatedAt"] }

        init(
          id: DashXGql.UUID,
          resourceId: DashXGql.UUID? = nil,
          attributeId: DashXGql.UUID? = nil,
          storageProviderId: DashXGql.UUID? = nil,
          uploadStatus: GraphQLEnum<DashXGql.AssetUploadStatus>,
          data: DashXGql.JSON,
          createdAt: DashXGql.Timestamp,
          updatedAt: DashXGql.Timestamp
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.Asset.typename,
            "id": id,
            "resourceId": resourceId,
            "attributeId": attributeId,
            "storageProviderId": storageProviderId,
            "uploadStatus": uploadStatus,
            "data": data,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
          ])
        }
      }
    }
  }

}