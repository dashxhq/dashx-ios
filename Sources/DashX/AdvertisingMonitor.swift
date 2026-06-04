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
        // CRITICAL: pass `notifyClient: false` from inside the singleton
        // initializer. Reading `DashXClient.instance.refreshSubscriptionDeviceInfo()`
        // from this path can re-enter `AdvertisingMonitor.shared` (the
        // refresh reads `AdvertisingMonitor.shared.hasAdInfoBeenResolved`),
        // and Swift's static-let initialization uses dispatch_once — a
        // recursive access from inside the initializer deadlocks the
        // current thread inside `_dispatch_once_wait`. The startup
        // backfill wakeup is still covered: `configure()` calls
        // `refreshSubscriptionDeviceInfo()` directly after the public
        // key is installed.
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

    /// `true` once the user's ATT decision is resolved — or always on
    /// pre-iOS-14 systems, where there is no ATT prompt. Subscribe consults
    /// this to decide whether it's safe to commit
    /// `SUBSCRIBED_AD_INFO_VERSION`: writing the marker before the prompt
    /// settles would short-circuit the post-prompt refresh that backfills
    /// the resolved IDFA / consent state onto the contact.
    var hasAdInfoBeenResolved: Bool {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus != .notDetermined
        }
        return true
    }

    /// Reflects current ATT status (authorized users get IDFA without waiting for a new prompt).
    ///
    /// `notifyClient`: when true (the default for post-init callers),
    /// reaches into `DashXClient` to trigger an ad-info backfill once
    /// the ATT state is settled. MUST be false when called from `init()`
    /// — see the comment there for the dispatch_once deadlock that
    /// notification path otherwise creates.
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
        // Trigger optional ad-info backfill once the ATT state is settled.
        // Covers the common case where the SDK was integrated into an app
        // that already had ATT authorized in a previous session — the
        // current session never goes through the prompt-completion path,
        // so without this call a pre-this-SDK-version contact would never
        // get its IDFA backfilled. `refreshSubscriptionDeviceInfo` is a
        // no-op when the SDK isn't configured yet, when there's no saved
        // FCM token, or when the version marker is already current.
        //
        // Skipped from `init()` (notifyClient: false) — the refresh path
        // re-reads `AdvertisingMonitor.shared` and would deadlock on
        // dispatch_once while the singleton is mid-initialization.
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
                            // Trigger ad-info backfill now that the ATT
                            // decision has settled. This is the primary
                            // wakeup for the common flow where subscribe
                            // ran before the ATT prompt (so the contact
                            // has an empty IDFA + consent=false) and now
                            // needs to be re-sent with the resolved
                            // values. Safe to call on every branch: the
                            // refresh's own gates (saved token, version
                            // marker, in-flight CAS) short-circuit when
                            // nothing needs to be done.
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
