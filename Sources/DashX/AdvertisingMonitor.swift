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
        syncTrackingAuthorizationState()
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

    /// Reflects current ATT status (authorized users get IDFA without waiting for a new prompt).
    private func syncTrackingAuthorizationState() {
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
                        }
                    }
                }
            } else {
                syncTrackingAuthorizationState()
            }
        }
    }
}
