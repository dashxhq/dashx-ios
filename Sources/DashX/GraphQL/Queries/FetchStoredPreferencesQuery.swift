import Foundation
import GraphQL
import SwiftGraphQL

extension FetchStoredPreferencesModel {
    static func input(uid: String) -> InputObjects.FetchStoredPreferencesInput {
        return InputObjects.FetchStoredPreferencesInput(accountUid: uid)
    }
    
    static let selection = Selection.FetchStoredPreferencesResponse<FetchStoredPreferencesModel> {
        let preferenceData = try $0.preferenceData().value as? [String: Any?] ?? [:]
        
        return FetchStoredPreferencesModel(preferenceData: preferenceData)
    }
    
    static func query(input: InputObjects.FetchStoredPreferencesInput) -> Selection<FetchStoredPreferencesModel, Objects.Query> {
        return Selection.Query<FetchStoredPreferencesModel> {
            try $0.fetchStoredPreferences(input: input, selection: selection)
        }
    }
}
