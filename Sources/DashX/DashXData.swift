import Apollo
import Foundation

struct ActionButton: Decodable {
    let identifier: String
    let label: String
    let icon: String?
}

struct DashXNotificationData: Decodable {
    let id: String
    let title: String
    let body: String
    let image: String?
    let url: String?
    let actionButtons: [ActionButton]?

    enum CodingKeys: String, CodingKey {
        case id, title, body, image, url
        case actionButtons = "action_buttons"
    }

    init(from decoder: Decoder) throws {
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
    typealias JSON = [String: Any?]
    typealias UUID = String
    typealias Timestamp = String
    typealias Decimal = String
}

extension ISO8601DateFormatter {
    static var timeStamp: DashXGql.Timestamp {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}

extension DashXNotificationMessage {
    func dashxNotificationData() -> DashXNotificationData? {
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

    func dashxNotificationId() -> String? {
        guard let dashxNotificationData = dashxNotificationData() else {
            return nil
        }
        return dashxNotificationData.id
    }

    func dashxNotificationUrl() -> URL? {
        guard let dashxNotificationData = dashxNotificationData() else {
            return nil
        }
        guard let url = dashxNotificationData.url else {
            return nil
        }
        return URL(string: url)
    }
}
