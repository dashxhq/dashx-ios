import Foundation

// Internal-only — DashXGql.Timestamp is not part of DashX's public surface.
extension ISO8601DateFormatter {
    static var timeStamp: DashXGql.Timestamp {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }
}
