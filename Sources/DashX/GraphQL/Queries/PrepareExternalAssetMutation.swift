import Foundation
import GraphQL
import SwiftGraphQL

extension PrepareExternalAssetModel {
    static func input(externalColumnId: String) -> InputObjects.PrepareExternalAssetInput {
        return InputObjects.PrepareExternalAssetInput(externalColumnId: externalColumnId)
    }
    
    static let selection = Selection.ExternalAsset<PrepareExternalAssetModel> {
        let id = try $0.id()
        let installationId = try $0.installationId()
        let externalColumnId = try $0.externalColumnId()
        let storageProviderId = try $0.storageProviderId()
        let status = try $0.status()
        let data = try $0.data()?.value as? [String: Any?] ?? [:]
        let createdAt = try $0.createdAt()
        let updatedAt = try $0.updatedAt()
        // FIXME: For asset
        // let asset = data?["asset"]
        let upload = data["upload"] as? [String: Any?]
        let uploadData = UploadData(
            headers: upload?["headers"] as? [String : String],
            url: upload?["url"] as? String
        )
        
        return PrepareExternalAssetModel(
            id: id,
            installationId: installationId,
            externalColumnId: externalColumnId,
            storageProviderId: storageProviderId,
            status: status,
            data: data,
            createdAt: createdAt,
            updatedAt: updatedAt,
            upload: uploadData
        )
    }
    
    static func mutation(input: InputObjects.PrepareExternalAssetInput) -> Selection<PrepareExternalAssetModel, Objects.Mutation> {
        return Selection.Mutation<PrepareExternalAssetModel> {
            try $0.prepareExternalAsset(input: input, selection: selection)
        }
    }
}
