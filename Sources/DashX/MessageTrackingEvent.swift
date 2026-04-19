import Foundation

/// Public mirror of `DashXGql.TrackMessageStatus`. `DashXGql` itself is
/// internal (kept out of DashX's public `.swiftinterface` to keep Apollo
/// off the consumer's module graph); this enum is the public surface for
/// notification-lifecycle events so integrators can call
/// `DashX.trackMessage(message:event:)` from their own AppDelegate / NSE.
public enum MessageTrackingEvent {
    case delivered
    case dismissed
    case opened
    case clicked
    case read

    /// Internal mapping — consumers never see `DashXGql.TrackMessageStatus`.
    var gqlStatus: DashXGql.TrackMessageStatus {
        switch self {
        case .delivered: return .delivered
        case .dismissed: return .dismissed
        case .opened: return .opened
        case .clicked: return .clicked
        case .read: return .read
        }
    }
}
