import Foundation

public struct Preference: Codable {
    public var enabled: Bool?
    public var email: Bool?
    public var push: Bool?
    public var sms: Bool?
    public var whatsapp: Bool?
}

public struct PrepareAssetResponse: Codable {
    public var data: ResponseAssetData?
    public var id: String?
}

public struct ResponseAssetData: Codable {
    public var upload: UploadData?
}

public struct UploadData: Codable {
    public var headers: [String: String]?
    public var url: String?
}

public struct AssetResponse: Codable {
    public struct AssetDataResponse: Codable {
        public var assetData: AssetData?
        
        enum CodingKeys: String, CodingKey {
            case assetData = "asset"
        }
    }
    
    public var status: String?
    public var data: AssetDataResponse?
}

public struct AssetData: Codable {
    public var status: String?
    public var url: String?
    public var playbackIds: [PlaybackData]?
    
    enum CodingKeys: String, CodingKey {
        case status
        case url
    }
}

public struct PlaybackData: Codable {
    public var id: String?
    public var policy: String?
}
