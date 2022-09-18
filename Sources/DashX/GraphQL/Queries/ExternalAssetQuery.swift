import Foundation
import GraphQL
import SwiftGraphQL

extension ExternalAssetModel {
    static let selection = Selection.ExternalAsset<ExternalAssetModel> {
        let id = try $0.id()
        let externalColumnId = try $0.externalColumnId()
        let status = try $0.status()
        let data = try $0.data()?.value as? [String: Any?] ?? [:]
        
        return ExternalAssetModel(
            id: id,
            externalColumnId: externalColumnId,
            status: status,
            data: data
        )
    }
    
    static func query(assetId: String) -> Selection<ExternalAssetModel, Objects.Query> {
        return Selection.Query<ExternalAssetModel> {
            try $0.externalAsset(id: assetId, selection: selection)
        }
    }
}
