import Foundation

public struct PrepareExternalAssetModel {
    public let id: String?
    public let installationId: String?
    public let externalColumnId: String?
    public let storageProviderId: String?
    public let status: String?
    public let data: [String: Any?]?
    public let createdAt: String?
    public let updatedAt: String?
    // FIXME: Getting `nil`, update the model
    // public let asset: nil
    public let upload: UploadData?
    
    public init(
        id: String? = nil,
        installationId: String? = nil,
        externalColumnId: String? = nil,
        storageProviderId: String? = nil,
        status: String? = nil,
        data: [String : Any?]? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        upload: UploadData? = nil
    ) {
        self.id = id
        self.installationId = installationId
        self.externalColumnId = externalColumnId
        self.storageProviderId = storageProviderId
        self.status = status
        self.data = data
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.upload = upload
    }
}

public struct UploadData {
    public let headers: [String: String]?
    public let url: String?
    
    public init(headers: [String : String]?, url: String?) {
        self.headers = headers
        self.url = url
    }
}
