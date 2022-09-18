import Foundation

public struct Preference: Codable {
    public var enabled: Bool?
    public var email: Bool?
    public var push: Bool?
    public var sms: Bool?
    public var whatsapp: Bool?
}
