import Foundation

public extension ISO8601DateFormatter {
    static var timeStamp: DashXGql.Timestamp {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}
