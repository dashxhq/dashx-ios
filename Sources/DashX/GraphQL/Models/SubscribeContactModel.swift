import Foundation

public struct SubscribeContactModel {
    public let id: String?
    public let value: String?
    
    public init(
        id: String? = nil,
        value: String? = nil
    ) {
        self.id = id
        self.value = value
    }
}
