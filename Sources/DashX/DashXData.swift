import Apollo
import Foundation

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
