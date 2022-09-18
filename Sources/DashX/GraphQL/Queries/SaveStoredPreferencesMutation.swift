import Foundation
import GraphQL
import SwiftGraphQL

extension SaveStoredPreferencesModel {
    static func input(uid: String, preferenceData: [String: Any]) -> InputObjects.SaveStoredPreferencesInput {
        let preferenceData = AnyCodable(preferenceData)
        return InputObjects.SaveStoredPreferencesInput(accountUid: uid, preferenceData: preferenceData)
    }
    
    static let selection = Selection.SaveStoredPreferencesResponse<SaveStoredPreferencesModel> {
        let success = try $0.success()
        
        return SaveStoredPreferencesModel(success: success)
    }
    
    static func mutation(input: InputObjects.SaveStoredPreferencesInput) -> Selection<SaveStoredPreferencesModel, Objects.Mutation> {
        return Selection.Mutation<SaveStoredPreferencesModel> {
            try $0.saveStoredPreferences(input: input, selection: selection)
        }
    }
}
