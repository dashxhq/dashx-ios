import AdSupport
import AppTrackingTransparency
import Foundation

class AdvertisingMonitor: NSObject {
    static let shared = AdvertisingMonitor()

    private let asIdentifierManager: ASIdentifierManager
    private let stateLock = NSLock()
    private var _isAdTrackingEnabled: Bool = false

    override init() {
        asIdentifierManager = ASIdentifierManager.shared()
        super.init()
        // `notifyClient: false` is required here — notifying would call back
        // into `AdvertisingMonitor.shared` while it's still mid-init, and
        // Swift's static-let dispatch_once deadlocks on the recursive read.
        // `configure()` runs the post-init wakeup instead.
        syncTrackingAuthorizationState(notifyClient: false)
    }

    var advertisingId: String {
        stateLock.lock()
        let enabled = _isAdTrackingEnabled
        stateLock.unlock()
        if enabled {
            return asIdentifierManager.advertisingIdentifier.uuidString
        }
        return ""
    }

    var adTrackingEnabled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _isAdTrackingEnabled
    }

    /// `true` once the ATT decision is resolved, or always on pre-iOS-14.
    /// Subscribe gates `SUBSCRIBED_AD_INFO_VERSION` on this so the marker
    /// isn't committed against an unresolved IDFA.
    var hasAdInfoBeenResolved: Bool {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus != .notDetermined
        }
        return true
    }

    /// `notifyClient` MUST be false when called from `init()` — see the
    /// dispatch_once deadlock note there.
    private func syncTrackingAuthorizationState(notifyClient: Bool = true) {
        if #available(iOS 14, *) {
            let authorized = ATTrackingManager.trackingAuthorizationStatus == .authorized
            stateLock.lock()
            _isAdTrackingEnabled = authorized
            stateLock.unlock()
        } else {
            stateLock.lock()
            _isAdTrackingEnabled = asIdentifierManager.isAdvertisingTrackingEnabled
            stateLock.unlock()
        }
        // Covers the SDK-integrated-into-already-authorized-app case where
        // the prompt-completion path never fires and a pre-upgrade contact
        // would otherwise never get its IDFA backfilled.
        if notifyClient, hasAdInfoBeenResolved {
            DashXClient.instance.refreshSubscriptionDeviceInfo()
        }
    }

    func requestAdTrackingPermission() {
        syncTrackingAuthorizationState()
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus

            guard DashXClient.instance.isAdTrackingRequested else { return }

            if status == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    ATTrackingManager.requestTrackingAuthorization { authorizationStatus in
                        DispatchQueue.main.async {
                            switch authorizationStatus {
                            case .authorized:
                                DashXLog.d(tag: #function, "Authorized Ad Tracking Permission")
                                self.stateLock.lock()
                                self._isAdTrackingEnabled = true
                                self.stateLock.unlock()
                            case .denied:
                                DashXLog.d(tag: #function, "Denied Ad Tracking Permission")
                                self.stateLock.lock()
                                self._isAdTrackingEnabled = false
                                self.stateLock.unlock()
                            case .notDetermined:
                                DashXLog.d(tag: #function, "Not Determined Ad Tracking Permission")
                            case .restricted:
                                DashXLog.d(tag: #function, "Restricted Ad Tracking Permission")
                                self.stateLock.lock()
                                self._isAdTrackingEnabled = false
                                self.stateLock.unlock()
                            @unknown default:
                                DashXLog.d(tag: #function, "Unknown Ad Tracking Permission")
                                self.syncTrackingAuthorizationState()
                            }
                            // Primary wakeup for the common flow: subscribe
                            // ran before the prompt with an empty IDFA;
                            // re-send now that ATT has resolved.
                            DashXClient.instance.refreshSubscriptionDeviceInfo()
                        }
                    }
                }
            } else {
                syncTrackingAuthorizationState()
            }
        }
    }
}
