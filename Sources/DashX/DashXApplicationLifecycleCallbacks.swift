import Foundation
import UIKit

@objc(DashXApplicationLifecycleCallbacks)
class DashXApplicationLifecycleCallbacks: NSObject {
    static let instance = DashXApplicationLifecycleCallbacks()
    let dashXClient = DashXClient.instance
    var startSession: Double?

    func enable() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(appBackgrounded), name: UIApplication.willResignActiveNotification, object: nil)

        notificationCenter.addObserver(self, selector: #selector(appResumed), name: UIApplication.willEnterForegroundNotification, object: nil)

        NSSetUncaughtExceptionHandler { exception in
            DashXClient.instance.track(Constants.INTERNAL_EVENT_APP_CRASHED, withData: ["exception": exception.reason as Any? ?? "unknown"])
        }

        appOpened()
    }

    func getAppBuildInfo() -> [String: Any] {
        let currentRelease = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let currentBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return ["version": currentRelease, "build": currentBuild]
    }

    @objc
    func appBackgrounded() {
        guard let startSession = startSession else {
            DashXLog.d(tag: #function, "'appBackgrounded' called before session started; returning...")
            return
        }
        let sessionLength = Date.timeIntervalSinceReferenceDate - startSession

        dashXClient.track(Constants.INTERNAL_EVENT_APP_BACKGROUNDED, withData: ["session_length": sessionLength as Any])
    }

    @objc
    func appOpened() {
        startSession = Date.timeIntervalSinceReferenceDate
        let defaults = UserDefaults.standard
        let appVersionKey = Constants.USER_PREFERENCES_KEY_BUILD
        let appBuildInfo = getAppBuildInfo()
        let previousBuild = defaults.string(forKey: appVersionKey)
        guard let currentBuild = appBuildInfo["build"] as? String else {
            DashXLog.e(tag: #function, "Unable to read build from app info; returning...")
            return
        }

        if previousBuild == nil {
            dashXClient.track(Constants.INTERNAL_EVENT_APP_INSTALLED, withData: appBuildInfo)
            defaults.set(currentBuild, forKey: appVersionKey)
        } else if previousBuild == currentBuild {
            dashXClient.track(Constants.INTERNAL_EVENT_APP_OPENED, withData: appBuildInfo)
        } else {
            dashXClient.track(Constants.INTERNAL_EVENT_APP_UPDATED, withData: appBuildInfo)
            defaults.set(currentBuild, forKey: appVersionKey)
        }
    }

    @objc
    func appResumed() {
        startSession = Date.timeIntervalSinceReferenceDate
        let properties = getAppBuildInfo().merging(["from_background": true]) { current, _ in current }

        dashXClient.track(Constants.INTERNAL_EVENT_APP_OPENED, withData: properties)
    }
}
