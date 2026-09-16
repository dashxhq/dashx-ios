import Foundation

/// State of the realtime connection; observe it via `DashXClient.connectionState` or
/// `addConnectionStateListener(_:)`.
public enum DashXConnectionState {
    /// Configured; nothing subscribed. No socket by design.
    case idle

    /// Connect attempt in flight, retry backoff, or an identity-token load in flight.
    case connecting

    /// Socket open. Individual channels may still be awaiting acknowledgement.
    case connected

    /// Process backgrounded with subscriptions still registered; resumes on foreground.
    case suspended

    /// Terminal: the server rejected the credentials and no token refresh recovered. A later
    /// `setIdentity(uid:token:)` or `setIdentityTokenProvider(uid:provider:)` retries.
    case authenticationFailed(cause: Error?)
}

extension DashXConnectionState: Equatable {
    public static func == (lhs: DashXConnectionState, rhs: DashXConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.connecting, .connecting), (.connected, .connected), (.suspended, .suspended):
            return true
        case let (.authenticationFailed(a), .authenticationFailed(b)):
            switch (a, b) {
            case (nil, nil): return true
            case let (a?, b?): return (a as NSError) == (b as NSError)
            default: return false
            }
        default:
            return false
        }
    }
}

extension DashXConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle: return "idle"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .suspended: return "suspended"
        case .authenticationFailed(let cause):
            return "authenticationFailed(\(cause.map { String(describing: $0) } ?? "nil"))"
        }
    }
}

/// Observer for `DashXConnectionState` changes. Listeners are held strongly until removed.
public protocol DashXConnectionStateListener: AnyObject {
    func onConnectionStateChanged(_ state: DashXConnectionState)
}
