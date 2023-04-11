import AdSupport
import AppTrackingTransparency
import Foundation

class AdvertisingMonitor: NSObject {
    static let shared = AdvertisingMonitor()

    private var asIdentifierManager: ASIdentifierManager!

    override init() {
        super.init()

        asIdentifierManager = ASIdentifierManager.shared()

        if #available(iOS 14, *), DashXClient.instance.isAdTrackingEnabled {
            ATTrackingManager.requestTrackingAuthorization { _ in
            }
        }
    }

    var isAdTrackingEnabled: Bool {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus

            if status == .authorized {
                return true
            }
        }

        return false
    }

    var advertisingId: String {
        if isAdTrackingEnabled {
            return asIdentifierManager.advertisingIdentifier.uuidString
        }

        return ""
    }
}
