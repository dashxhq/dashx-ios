import Foundation
import UIKit

private var previousUncaughtExceptionHandler: (@convention(c) (NSException) -> Void)?

private let installCrashHandlerOnce: Void = {
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler()
    NSSetUncaughtExceptionHandler { exception in
        DashXClient.instance.track(Constants.INTERNAL_EVENT_APP_CRASHED, withData: ["exception": exception.reason ?? "unknown"])
        previousUncaughtExceptionHandler?(exception)
    }
}()

@objc(DashXApplicationLifecycleCallbacks)
class DashXApplicationLifecycleCallbacks: NSObject {
    static let instance = DashXApplicationLifecycleCallbacks()

    enum LaunchKind: Equatable {
        case installed
        case updated(previousBuild: String)
        case downgraded
        case opened
    }

    typealias Tracker = (_ event: String, _ data: [String: Any]) -> Void

    private let track: Tracker
    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let installsCrashHandler: Bool
    private let isConfigured: () -> Bool
    private let buildInfo: () -> (version: String, build: String)
    private let now: () -> TimeInterval

    private let lock = NSLock()
    private var isEnabled = false
    private var foregroundStartedAt: TimeInterval?

    init(
        track: @escaping Tracker = { DashXClient.instance.track($0, withData: $1) },
        defaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default,
        installsCrashHandler: Bool = true,
        isConfigured: @escaping () -> Bool = { ConfigInterceptor.shared.publicKey != nil },
        buildInfo: @escaping () -> (version: String, build: String) = DashXApplicationLifecycleCallbacks.mainBundleBuildInfo,
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.track = track
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.installsCrashHandler = installsCrashHandler
        self.isConfigured = isConfigured
        self.buildInfo = buildInfo
        self.now = now
    }

    static func mainBundleBuildInfo() -> (version: String, build: String) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return (version, build)
    }

    static func launchKind(previousBuild: String?, currentBuild: String) -> LaunchKind {
        guard let previousBuild else { return .installed }
        switch currentBuild.compare(previousBuild, options: .numeric) {
        case .orderedSame: return .opened
        case .orderedDescending: return .updated(previousBuild: previousBuild)
        case .orderedAscending: return .downgraded
        }
    }

    func enable() {
        lock.lock()
        let alreadyEnabled = isEnabled
        isEnabled = true
        lock.unlock()
        guard !alreadyEnabled else { return }

        notificationCenter.addObserver(self, selector: #selector(appBackgrounded), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appForegrounded), name: UIApplication.willEnterForegroundNotification, object: nil)

        if installsCrashHandler {
            _ = installCrashHandlerOnce
        }

        appLaunched()
    }

    private func markForegroundStart() {
        lock.lock()
        foregroundStartedAt = now()
        lock.unlock()
    }

    private func appLaunched() {
        markForegroundStart()

        let info = buildInfo()
        let data: [String: Any] = ["version": info.version, "build": info.build]
        let previousBuild = defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD)
        let kind = Self.launchKind(previousBuild: previousBuild, currentBuild: info.build)

        // Nothing can be sent before configure(); leaving the stored build untouched reports
        // the install/update on the next configured launch.
        guard isConfigured() else {
            DashXLog.d(tag: #function, "Lifecycle tracking enabled before configure(); skipping the launch event")
            return
        }

        switch kind {
        case .installed:
            track(Constants.INTERNAL_EVENT_APP_INSTALLED, data)
        case let .updated(previousBuild):
            track(Constants.INTERNAL_EVENT_APP_UPDATED, data.merging(["previous_build": previousBuild]) { current, _ in current })
        case .downgraded, .opened:
            track(Constants.INTERNAL_EVENT_APP_OPENED, data)
        }
        if kind != .opened {
            defaults.set(info.build, forKey: Constants.USER_PREFERENCES_KEY_BUILD)
        }
    }

    @objc
    func appForegrounded() {
        markForegroundStart()
        let info = buildInfo()
        track(Constants.INTERNAL_EVENT_APP_OPENED, ["version": info.version, "build": info.build, "from_background": true])
    }

    @objc
    func appBackgrounded() {
        lock.lock()
        let startedAt = foregroundStartedAt
        foregroundStartedAt = nil
        lock.unlock()

        guard let startedAt else {
            DashXLog.d(tag: #function, "'appBackgrounded' called without a matching open; returning...")
            return
        }

        track(Constants.INTERNAL_EVENT_APP_BACKGROUNDED, ["session_length": max(0, now() - startedAt)])
    }
}
