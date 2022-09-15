import Foundation
import GraphQL
import SwiftGraphQL

extension FetchStoredPreferences {
    static func input(uid: String) -> InputObjects.FetchStoredPreferencesInput {
        return InputObjects.FetchStoredPreferencesInput(accountUid: uid)
    }
    
    static let selection = Selection.FetchStoredPreferencesResponse<FetchStoredPreferences> {
        let preferenceData = try $0.preferenceData().value as? [String: Any?] ?? [:]
        
        return FetchStoredPreferences(preferenceData: preferenceData)
    }
    
    static func query(input: InputObjects.FetchStoredPreferencesInput) -> Selection<FetchStoredPreferences, Objects.Query> {
        return Selection.Query<FetchStoredPreferences> {
            try $0.fetchStoredPreferences(input: input, selection: selection)
        }
    }
}
