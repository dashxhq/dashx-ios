import Foundation

public struct Preference: Codable {
    public var enabled: Bool?
    public var email: Bool?
    public var push: Bool?
    public var sms: Bool?
    public var whatsapp: Bool?
}

public struct PrepareExternalAssetResponse: Codable {
    let data: AssetData?
    let createdAt: String?
    let status: String?
    // let storageProviderId: nil
    let updatedAt: String?
    let externalColumnId: String?
    let id: String?
    let installationId: String?
}

public struct AssetData: Codable {
    // let asset: nil
    let upload: UploadData?
}

public struct UploadData: Codable {
    let headers: [String: String]?
    let url: String?
}
