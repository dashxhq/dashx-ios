import Foundation
import GraphQL
import SwiftGraphQL

extension FetchStoredPreferences {
    static let fetchStoredPreferencesSelection = Selection.FetchStoredPreferencesResponse<FetchStoredPreferences> {
        guard let preferenceData = try $0.preferenceData().value as? [String: Any?] else {
            throw DecodingError.invalidType
        }
        
        return FetchStoredPreferences(preferenceData: preferenceData)
    }
    
    static func fetchStoredPreferencesQuery(uid: String) -> Selection<FetchStoredPreferences, Objects.Query> {
        return Selection.Query<FetchStoredPreferences> {
            try $0.fetchStoredPreferences(input: InputObjects.FetchStoredPreferencesInput(accountUid: uid), selection: fetchStoredPreferencesSelection)
        }
    }
}
