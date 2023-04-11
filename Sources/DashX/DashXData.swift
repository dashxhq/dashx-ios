import Apollo
import Foundation

struct DashXNotificationData: Decodable {
    let id: String
    let title: String
    let body: String
}

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
