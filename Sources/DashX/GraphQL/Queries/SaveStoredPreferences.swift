import Foundation
import GraphQL
import SwiftGraphQL

extension SaveStoredPreferences {
    static func input(uid: String, preferenceData: [String: Any]) -> InputObjects.SaveStoredPreferencesInput {
        let preferenceData = AnyCodable(preferenceData)
        return InputObjects.SaveStoredPreferencesInput(accountUid: uid, preferenceData: preferenceData)
    }
    
    static let selection = Selection.SaveStoredPreferencesResponse<SaveStoredPreferences> {
        let success = try $0.success()
        
        return SaveStoredPreferences(success: success)
    }
    
    static func mutation(input: InputObjects.SaveStoredPreferencesInput) -> Selection<SaveStoredPreferences, Objects.Mutation> {
        return Selection.Mutation<SaveStoredPreferences> {
            try $0.saveStoredPreferences(input: input, selection: selection)
        }
    }
}
