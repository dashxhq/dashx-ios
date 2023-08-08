import Apollo
import Foundation

public struct ActionButton: Decodable {
    public let identifier: String
    public let label: String
    public let icon: String?
}

public struct DashXNotificationData: Decodable {
    public let id: String
    public let title: String
    public let body: String
    public let image: String?
    public let url: String?
    public let actionButtons: [ActionButton]?

    public enum CodingKeys: String, CodingKey {
        case id, title, body, image, url
        case actionButtons = "action_buttons"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        url = try container.decodeIfPresent(String.self, forKey: .url)

        if let actionButtonsString = try container.decodeIfPresent(String.self, forKey: .actionButtons) {
            let actionButtonsData = actionButtonsString.data(using: .utf8)!
            actionButtons = try JSONDecoder().decode([ActionButton].self, from: actionButtonsData)
        } else {
            actionButtons = nil
        }
    }
}

public typealias DashXNotificationMessage = [AnyHashable: Any]

public extension DashXGql {
    public typealias JSON = [String: Any?]
    public typealias UUID = String
    public typealias Timestamp = String
    public typealias Decimal = String
}

public extension ISO8601DateFormatter {
    public static var timeStamp: DashXGql.Timestamp {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}

public extension DashXNotificationMessage {
    public func dashxNotificationData() -> DashXNotificationData? {
        guard let jsonString = self[Constants.DASHX_NOTIFICATION_DATA_KEY] as? String else {
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        guard let notificationData = try? JSONDecoder().decode(DashXNotificationData.self, from: jsonData) else {
            return nil
        }
        return notificationData
    }

    public func dashxNotificationId() -> String? {
        guard let dashxNotificationData = dashxNotificationData() else {
            return nil
        }
        return dashxNotificationData.id
    }

    public func dashxNotificationUrl() -> URL? {
        guard let dashxNotificationData = dashxNotificationData() else {
            return nil
        }
        guard let url = dashxNotificationData.url else {
            return nil
        }
        return URL(string: url)
    }
}
