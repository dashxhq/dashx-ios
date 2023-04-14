import Apollo
import Foundation

struct DashXNotificationData: Decodable {
    let id: String
    let title: String
    let body: String
    let image: String?
}

public typealias DashXNotificationMessage = [AnyHashable : Any]

public extension DashXGql {
    typealias JSON = [String: Any?]
    typealias UUID = String
    typealias Timestamp = String
    typealias Decimal = String
}

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        }
        return nil
    }
}

extension ISO8601DateFormatter {
    static var timeStamp: DashXGql.Timestamp {
        struct Static {
            static let instance = ISO8601DateFormatter()
        }
        return Static.instance.string(from: Date())
    }
}

extension DashXNotificationMessage {
    func dashxNotificationData() -> DashXNotificationData? {
        if let theJSONString = self[Constants.DASHX_NOTIFICATION_DATA_KEY] as? String {
            if let jsonData = theJSONString.data(using: .utf8) {
                do {
                    return try JSONDecoder().decode(DashXNotificationData.self, from: jsonData)
                } catch {
                    DashXLog.d(tag: #function, "Unable to parse DashX notification data \(error)")
                }
            }
        }
        return nil
    }
    
    func dashxNotificationId() -> String? {
        guard let dashxNotificationData = self.dashxNotificationData() else {
            return nil
        }
        return dashxNotificationData.id
    }
}
