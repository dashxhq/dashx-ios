import Foundation
import GraphQL
import SwiftGraphQL

extension SubscribeContactModel {
    static func input(
        accountUid: String? = nil,
        accountAnonymousUid: String? = nil,
        name: String? = nil,
        kind: Enums.ContactKind = .ios,
        value: String,
        userAgent: String? = nil,
        osName: String? = nil,
        osVersion: String? = nil,
        deviceModel: String? = nil,
        deviceManufacturer: String? = nil,
        deviceUid: String? = nil,
        deviceAdvertisingUid: String? = nil,
        isDeviceAdTrackingEnabled: Bool? = nil,
        tag: String? = nil
    ) -> InputObjects.SubscribeContactInput {
        let accountUid = OptionalArgument(present: accountUid)
        let accountAnonymousUid = OptionalArgument(present: accountAnonymousUid)
        let name = OptionalArgument(present: name)
        let userAgent = OptionalArgument(present: userAgent)
        let osName = OptionalArgument(present: osName)
        let osVersion = OptionalArgument(present: osVersion)
        let deviceModel = OptionalArgument(present: deviceModel)
        let deviceManufacturer = OptionalArgument(present: deviceManufacturer)
        let deviceUid = OptionalArgument(present: deviceUid)
        let deviceAdvertisingUid = OptionalArgument(present: deviceAdvertisingUid)
        let isDeviceAdTrackingEnabled = OptionalArgument(present: isDeviceAdTrackingEnabled)
        let tag = OptionalArgument(present: tag)
        
        return InputObjects.SubscribeContactInput(
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid,
            name: name,
            kind: kind,
            value: value,
            userAgent: userAgent,
            osName: osName,
            osVersion: osVersion,
            deviceModel: deviceModel,
            deviceManufacturer: deviceManufacturer,
            deviceUid: deviceUid,
            deviceAdvertisingUid: deviceAdvertisingUid,
            isDeviceAdTrackingEnabled: isDeviceAdTrackingEnabled,
            tag: tag
        )
    }
    
    static let selection = Selection.Contact<SubscribeContactModel> {
        let id = try $0.id()
        let value = try $0.value()
        
        return SubscribeContactModel(id: id, value: value)
    }
    
    static func mutation(input: InputObjects.SubscribeContactInput) -> Selection<SubscribeContactModel, Objects.Mutation> {
        return Selection.Mutation<SubscribeContactModel> {
            try $0.subscribeContact(input: input, selection: selection)
        }
    }
}
