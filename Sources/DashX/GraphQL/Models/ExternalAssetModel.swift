import Foundation

public struct ExternalAssetModel {
    public let id: String?
    public let externalColumnId: String?
    public let status: String?
    public let data: [String: Any?]?
    
    public init(
        id: String? = nil,
        externalColumnId: String? = nil,
        status: String? = nil,
        data: [String : Any?]? = nil
    ) {
        self.id = id
        self.externalColumnId = externalColumnId
        self.status = status
        self.data = data
    }
}

