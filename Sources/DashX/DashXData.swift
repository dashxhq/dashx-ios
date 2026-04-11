import Foundation

// MARK: - Decoding helpers

extension KeyedDecodingContainer {
    /// Decodes a value that may arrive as either a native JSON object or a stringified JSON string.
    func decodeStringifiedJSONIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        if let value = try? decode(T.self, forKey: key) { return value }
        if let jsonString = try? decode(String.self, forKey: key),
           let data = jsonString.data(using: .utf8),
           let value = try? JSONDecoder().decode(T.self, from: data) { return value }
        return nil
    }

    /// Decodes a Bool that may arrive as a native JSON boolean or a string (`"true"` / `"false"`).
    /// FCM data payloads deliver all values as strings, so `rich_landing` may be `"true"` instead of `true`.
    func decodeBoolFromStringIfPresent(forKey key: Key) -> Bool? {
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let string = try? decode(String.self, forKey: key) { return string == "true" }
        return nil
    }
}

/// Resolved navigation intent for a notification tap or action (see payload fields `url`, `screen_name`, etc.).
public enum NavigationAction: Equatable {
    case deepLink(url: URL)
    case screen(name: String, data: [String: String]?)
    case richLanding(url: URL)
    /// Intent-based navigation via a fully-qualified class name or action string (Android-oriented, but present in payloads for both platforms).
    case clickAction(action: String)
}

public struct ActionButton: Decodable {
    public let identifier: String
    public let label: String
    public let icon: String?
    public let url: String?
    public let clickAction: String?
    public let screenName: String?
    public let screenData: [String: String]?
    /// When `true` and a `url` is set, navigation resolves to ``NavigationAction/richLanding(url:)`` (in-app Safari) instead of a plain deep link.
    public let richLanding: Bool?

    enum CodingKeys: String, CodingKey {
        case identifier, label, icon, url
        case clickAction, screenName, screenData, richLanding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        label = try container.decode(String.self, forKey: .label)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        clickAction = try container.decodeIfPresent(String.self, forKey: .clickAction)
        screenName = try container.decodeIfPresent(String.self, forKey: .screenName)
        screenData = container.decodeStringifiedJSONIfPresent([String: String].self, forKey: .screenData)
        richLanding = container.decodeBoolFromStringIfPresent(forKey: .richLanding)
    }
}

private let unNotificationDefaultActionIdentifier = "com.apple.UNNotificationDefaultActionIdentifier"

public struct DashXNotificationData: Decodable {
    public let id: String
    public let title: String
    public let body: String
    public let image: String?
    public let url: String?
    public let screenName: String?
    public let screenData: [String: String]?
    public let clickAction: String?
    public let actionButtons: [ActionButton]?
    /// When `true` and `url` is set, navigation resolves to ``NavigationAction/richLanding(url:)`` for the main notification tap.
    public let richLanding: Bool?

    public let interruptionLevel: String?

    public enum CodingKeys: String, CodingKey {
        case id, title, body, image, url
        case actionButtons = "action_buttons"
        case screenName = "screen_name"
        case screenData = "screen_data"
        case clickAction = "click_action"
        case richLanding = "rich_landing"
        case interruptionLevel = "interruption_level"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        screenName = try container.decodeIfPresent(String.self, forKey: .screenName)
        screenData = container.decodeStringifiedJSONIfPresent([String: String].self, forKey: .screenData)
        clickAction = try container.decodeIfPresent(String.self, forKey: .clickAction)
        richLanding = container.decodeBoolFromStringIfPresent(forKey: .richLanding)
        actionButtons = container.decodeStringifiedJSONIfPresent([ActionButton].self, forKey: .actionButtons)
        interruptionLevel = try container.decodeIfPresent(String.self, forKey: .interruptionLevel)
    }

    /// Resolves navigation for the main notification tap or an action button (when `actionIdentifier` matches ``ActionButton/identifier``).
    /// Priority: `screen_name` > `rich_landing` + `url` > `url` > `click_action`.
    public func navigationAction(forActionIdentifier actionIdentifier: String) -> NavigationAction? {
        if actionIdentifier == unNotificationDefaultActionIdentifier {
            if let name = screenName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                return .screen(name: name, data: screenData)
            }
            if richLanding == true, let urlString = url, let url = URL(string: urlString) {
                return .richLanding(url: url)
            }
            if let urlString = url, let url = URL(string: urlString) {
                return .deepLink(url: url)
            }
            if let action = clickAction?.trimmingCharacters(in: .whitespacesAndNewlines), !action.isEmpty {
                return .clickAction(action: action)
            }
            return nil
        }
        guard let buttons = actionButtons,
              let button = buttons.first(where: { $0.identifier == actionIdentifier })
        else {
            return nil
        }
        if let name = button.screenName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return .screen(name: name, data: button.screenData)
        }
        if button.richLanding == true, let urlString = button.url, let url = URL(string: urlString) {
            return .richLanding(url: url)
        }
        if let urlString = button.url, let url = URL(string: urlString) {
            return .deepLink(url: url)
        }
        if let action = button.clickAction?.trimmingCharacters(in: .whitespacesAndNewlines), !action.isEmpty {
            return .clickAction(action: action)
        }
        return nil
    }
}

public typealias DashXNotificationMessage = [AnyHashable: Any]

public extension ISO8601DateFormatter {
    static var timeStamp: DashXGql.Timestamp {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}

public extension DashXNotificationMessage {
    func dashxNotificationData() -> DashXNotificationData? {
        guard let jsonString = self[Constants.DASHX_NOTIFICATION_DATA_KEY] as? String else {
            DashXLog.d(tag: "DashXNotificationMessage", "No DashX data key in notification payload")
            return nil
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            DashXLog.e(tag: "DashXNotificationMessage", "Failed to convert DashX JSON string to Data")
            return nil
        }
        do {
            return try JSONDecoder().decode(DashXNotificationData.self, from: jsonData)
        } catch {
            DashXLog.e(tag: "DashXNotificationMessage", "Failed to decode DashX payload: \(error)")
            return nil
        }
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
