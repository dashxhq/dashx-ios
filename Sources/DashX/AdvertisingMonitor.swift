import AdSupport
import AppTrackingTransparency
import Foundation

class AdvertisingMonitor: UIResponder, UIWindowSceneDelegate {
    static let shared = AdvertisingMonitor()

    private var asIdentifierManager: ASIdentifierManager!
    private var isAdTrackingEnabled: Bool = false

    override init() {
        super.init()

        asIdentifierManager = ASIdentifierManager.shared()
    }

    var advertisingId: String {
        if adTrackingEnabled {
            return asIdentifierManager.advertisingIdentifier.uuidString
        }

        return ""
    }

    var adTrackingEnabled: Bool {
        return isAdTrackingEnabled
    }

    func requestAdTrackingPermission() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus

            if DashXClient.instance.shouldRequestIDFAPermissions, status == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    ATTrackingManager.requestTrackingAuthorization { authorizationStatus in
                        switch authorizationStatus {
                        case .authorized:
                            // Ad Tracking authorization dialog was shown
                            // and we are authorized
                            DashXLog.d(tag: #function, "Authorized Ad Tracking Permission")

                            // Now that we are authorized we can get the IDFA
                            self.isAdTrackingEnabled = true
                        case .denied:
                            // Ad Tracking authorization dialog was
                            // shown and permission is denied
                            DashXLog.d(tag: #function, "Denied Ad Tracking Permission")
                        case .notDetermined:
                            // Ad Tracking authorization dialog has not been shown
                            DashXLog.d(tag: #function, "Not Determined Ad Tracking Permission")
                        case .restricted:
                            DashXLog.d(tag: #function, "Restricted Ad Tracking Permission")
                        @unknown default:
                            DashXLog.d(tag: #function, "Unknown Ad Tracking Permission")
                        }
                    }
                }
            }
        }
    }
}
