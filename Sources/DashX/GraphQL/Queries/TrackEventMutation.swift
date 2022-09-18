import Foundation
import GraphQL
import SwiftGraphQL

extension TrackEventModel {
    static func input(
        event: String,
        accountUid: String?,
        accountAnonymousUid: String?,
        data: NSDictionary? = nil,
        timeStamp: DateTimeScalar? = nil,
        systemContext: InputObjects.SystemContextInput? = nil
    ) -> InputObjects.TrackEventInput {
        let event = event
        let accountUid = OptionalArgument(present: accountUid)
        let accountAnonymousUid = OptionalArgument(present: accountAnonymousUid)
        let dataAsAnyCodable = AnyCodable(data)
        let data = OptionalArgument(present: dataAsAnyCodable)
        let timeStamp = OptionalArgument(present: timeStamp)
        let systemContext = OptionalArgument(present: systemContext)
        
        return InputObjects.TrackEventInput(
            event: event,
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid,
            data: data,
            timestamp: timeStamp,
            systemContext: systemContext
        )
    }
    
    static let selection = Selection.TrackEventResponse<TrackEventModel> {
        let success = try $0.success()
        
        return TrackEventModel(success: success)
    }
    
    static func mutation(input: InputObjects.TrackEventInput) -> Selection<TrackEventModel, Objects.Mutation> {
        return Selection.Mutation<TrackEventModel> {
            try $0.trackEvent(input: input, selection: selection)
        }
    }
}
