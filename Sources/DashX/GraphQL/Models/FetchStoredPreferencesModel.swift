import Foundation

public struct FetchStoredPreferencesModel {
    public let preferenceData: [String: Any?]?
    
    public init(preferenceData: [String : Any?]? = nil) {
        self.preferenceData = preferenceData
    }
}
