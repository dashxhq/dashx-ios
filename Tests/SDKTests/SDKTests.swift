import SwiftUI
import UIKit
import XCTest
@testable import DashX

final class DashXClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearUserPreferences()
        DashXClient.instance.reset()
    }

    override func tearDown() {
        DashXClient.instance.reset()
        clearUserPreferences()
        super.tearDown()
    }

    func testDeprecatedIdentifyThrowsWhenOptionsAreNil() {
        XCTAssertThrowsError(try DashXClient.instance.identify(withOptions: nil)) { error in
            guard case DashXClientError.noArgsInIdentify = error else {
                XCTFail("Unexpected error thrown: \(error)")
                return
            }
        }
    }

    func testIdentifyAcceptsSwiftDictionary() {
        DashXClient.instance.identify(options: [
            UserAttributes.EMAIL: "test@example.com",
            UserAttributes.FIRST_NAME: "Test"
        ])
    }

    func testSetIdentityPersistsUidAndResetClearsIt() {
        DashXClient.instance.setIdentity(uid: "user-123", token: nil)
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID),
            "user-123"
        )

        DashXClient.instance.reset()
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID))
    }

    func testSetIdentityNilClearsStoredUidAndToken() {
        DashXClient.instance.setIdentity(uid: "user-1", token: "token-1")
        XCTAssertEqual(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN), "token-1")

        DashXClient.instance.setIdentity(uid: nil, token: nil)
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID))
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN))
        XCTAssertNil(ConfigInterceptor.shared.identityToken)
    }

    func testEnableAdTrackingSetsRequestFlag() {
        DashXClient.instance.enableAdTracking()
        XCTAssertTrue(DashXClient.instance.isAdTrackingRequested)
    }

    private func clearUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        defaults.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        defaults.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        defaults.removeObject(forKey: Constants.USER_PREFERENCES_KEY_FCM_TOKEN)
    }
}

final class DashXDataTests: XCTestCase {
    func testDashxNotificationDataDecodesActionButtons() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: """
            {"id":"notif-1","title":"Hi","body":"Body","url":"https://example.com","action_buttons":"[{\\"identifier\\":\\"open\\",\\"label\\":\\"Open\\",\\"icon\\":\\"icon-link\\"}]"}
            """
        ]

        let data = message.dashxNotificationData()
        XCTAssertEqual(data?.id, "notif-1")
        XCTAssertEqual(data?.actionButtons?.first?.identifier, "open")
        XCTAssertEqual(data?.actionButtons?.first?.label, "Open")
    }

    func testDashxNotificationIdAndUrlHelpers() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: """
            {"id":"notif-42","title":"Hi","body":"Body","url":"https://dashx.com"}
            """
        ]

        XCTAssertEqual(message.dashxNotificationId(), "notif-42")
        XCTAssertEqual(message.dashxNotificationUrl(), URL(string: "https://dashx.com"))
    }

    func testDashxNotificationDataReturnsNilForInvalidPayload() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: "{not-json"
        ]
        XCTAssertNil(message.dashxNotificationData())
        XCTAssertNil(message.dashxNotificationId())
        XCTAssertNil(message.dashxNotificationUrl())
    }
}

final class SystemContextTests: XCTestCase {
    func testGetSystemContextLibraryInputUsesDefaultAndCustomValues() {
        let context = SystemContext()

        let defaultLibrary = context.getSystemContextLibraryInput()
        XCTAssertEqual(defaultLibrary.name, Constants.LIBRARY_NAME)
        XCTAssertEqual(defaultLibrary.name, "dashx-ios")
        XCTAssertEqual(defaultLibrary.version, Constants.PACKAGE_VERSION)

        context.setLibraryInfo(libraryInfo: .init(name: "com.example.custom", version: "9.9.9"))
        let customLibrary = context.getSystemContextLibraryInput()
        XCTAssertEqual(customLibrary.name, "com.example.custom")
        XCTAssertEqual(customLibrary.version, "9.9.9")
    }

    func testGetSystemContextOsInputMatchesCurrentDevice() {
        let context = SystemContext()
        let os = context.getSystemContextOsInput()
        XCTAssertEqual(os.name, UIDevice.current.systemName)
        XCTAssertEqual(os.version, UIDevice.current.systemVersion)
    }

    func testGetSystemContextScreenInputHasPositiveValues() {
        let context = SystemContext()
        let screen = context.getSystemContextScreenInput()
        XCTAssertGreaterThan(screen.width, 0)
        XCTAssertGreaterThan(screen.height, 0)
        XCTAssertGreaterThan(screen.density, 0)
    }
}

final class LifecycleTrackingTests: XCTestCase {
    private var defaults: UserDefaults!
    private var center: NotificationCenter!
    private var events: [(name: String, data: [String: Any])] = []
    private var clock: TimeInterval = 100
    private let suiteName = "com.dashx.ios.tests.lifecycle"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        center = NotificationCenter()
        events = []
        clock = 100
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeCallbacks(build: String = "42", configured: Bool = true, active: Bool = true) -> DashXApplicationLifecycleCallbacks {
        DashXApplicationLifecycleCallbacks(
            track: { [unowned self] name, data in self.events.append((name, data)) },
            defaults: defaults,
            notificationCenter: center,
            installsCrashHandler: false,
            isConfigured: { configured },
            isActive: { active },
            buildInfo: { ("1.2.0", build) },
            now: { [unowned self] in self.clock }
        )
    }

    func testLaunchKindDecision() {
        XCTAssertEqual(DashXApplicationLifecycleCallbacks.launchKind(previousBuild: nil, currentBuild: "2"), .installed)
        XCTAssertEqual(DashXApplicationLifecycleCallbacks.launchKind(previousBuild: "2", currentBuild: "2"), .opened)
        XCTAssertEqual(DashXApplicationLifecycleCallbacks.launchKind(previousBuild: "9", currentBuild: "10"), .updated(previousBuild: "9"))
        XCTAssertEqual(DashXApplicationLifecycleCallbacks.launchKind(previousBuild: "1.9", currentBuild: "1.10"), .updated(previousBuild: "1.9"))
        XCTAssertEqual(DashXApplicationLifecycleCallbacks.launchKind(previousBuild: "10", currentBuild: "9"), .downgraded)
    }

    func testFirstLaunchSendsInstalledAndStoresBuild() {
        makeCallbacks().enable()

        XCTAssertEqual(events.map(\.name), ["Application Installed"])
        XCTAssertEqual(events[0].data["version"] as? String, "1.2.0")
        XCTAssertEqual(events[0].data["build"] as? String, "42")
        XCTAssertNil(events[0].data["from_background"])
        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD), "42")
    }

    func testNewBuildSendsUpdatedWithPreviousBuildAndVersion() {
        defaults.set("41", forKey: Constants.USER_PREFERENCES_KEY_BUILD)
        defaults.set("1.1.0", forKey: Constants.USER_PREFERENCES_KEY_VERSION)

        makeCallbacks().enable()

        XCTAssertEqual(events.map(\.name), ["Application Updated"])
        XCTAssertEqual(events[0].data["previous_build"] as? String, "41")
        XCTAssertEqual(events[0].data["previous_version"] as? String, "1.1.0")
        XCTAssertEqual(events[0].data["build"] as? String, "42")
        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD), "42")
        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_VERSION), "1.2.0")
    }

    func testUpdateFromABuildWithoutAStoredVersionOmitsPreviousVersion() {
        defaults.set("41", forKey: Constants.USER_PREFERENCES_KEY_BUILD)

        makeCallbacks().enable()

        XCTAssertEqual(events[0].data["previous_build"] as? String, "41")
        XCTAssertFalse(events[0].data.keys.contains("previous_version"))
    }

    func testColdOpenStoresTheVersionForTheNextUpdate() {
        defaults.set("42", forKey: Constants.USER_PREFERENCES_KEY_BUILD)

        makeCallbacks().enable()

        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_VERSION), "1.2.0")
    }

    func testDowngradeSendsOpenedAndStoresCurrentBuild() {
        defaults.set("43", forKey: Constants.USER_PREFERENCES_KEY_BUILD)

        makeCallbacks().enable()

        XCTAssertEqual(events.map(\.name), ["Application Opened"])
        XCTAssertNil(events[0].data["from_background"])
        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD), "42")
    }

    func testInstallBeforeConfigureIsDeferredToNextLaunch() {
        makeCallbacks(configured: false).enable()

        XCTAssertEqual(events.map(\.name), [])
        XCTAssertNil(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD))

        events = []
        makeCallbacks(configured: true).enable()
        XCTAssertEqual(events.map(\.name), ["Application Installed"])
    }

    func testUpdateBeforeConfigureIsDeferredToNextLaunch() {
        defaults.set("41", forKey: Constants.USER_PREFERENCES_KEY_BUILD)

        makeCallbacks(configured: false).enable()

        XCTAssertEqual(events.map(\.name), [])
        XCTAssertEqual(defaults.string(forKey: Constants.USER_PREFERENCES_KEY_BUILD), "41")
    }

    func testSameBuildSendsColdOpen() {
        defaults.set("42", forKey: Constants.USER_PREFERENCES_KEY_BUILD)

        makeCallbacks().enable()

        XCTAssertEqual(events.map(\.name), ["Application Opened"])
        XCTAssertEqual(events[0].data["build"] as? String, "42")
        XCTAssertNil(events[0].data["from_background"])
    }

    func testEnableIsIdempotent() {
        let callbacks = makeCallbacks()
        callbacks.enable()
        callbacks.enable()
        XCTAssertEqual(events.count, 1)

        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.map(\.name), ["Application Installed", "Application Backgrounded"])
    }

    func testForegroundAtLaunchIsNotAReturnFromBackground() {
        let callbacks = makeCallbacks()
        callbacks.enable()

        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertEqual(events.map(\.name), ["Application Installed"])
        withExtendedLifetime(callbacks) {}
    }

    func testLaunchIsSentOnFirstActivation() {
        let callbacks = makeCallbacks(active: false)
        callbacks.enable()
        XCTAssertEqual(events.map(\.name), [])

        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertEqual(events.map(\.name), ["Application Installed"])
        withExtendedLifetime(callbacks) {}
    }

    func testBackgroundLaunchIsNotAnOpen() {
        defaults.set("42", forKey: Constants.USER_PREFERENCES_KEY_BUILD)
        let callbacks = makeCallbacks(active: false)
        callbacks.enable()

        clock += 600
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.map(\.name), [])

        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertEqual(events.map(\.name), ["Application Opened"])
        XCTAssertNil(events[0].data["from_background"])

        clock += 2
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.last?.name, "Application Backgrounded")
        XCTAssertEqual(events.last?.data["session_length"] as? Double, 2)
        withExtendedLifetime(callbacks) {}
    }

    func testBackgroundAndForegroundTransitions() {
        let callbacks = makeCallbacks()
        callbacks.enable()

        center.post(name: UIApplication.willResignActiveNotification, object: nil)
        XCTAssertEqual(events.count, 1, "resigning active (Control Center, calls) is not backgrounding")

        clock += 1.5
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.last?.name, "Application Backgrounded")
        XCTAssertEqual(events.last?.data["session_length"] as? Double, 1.5)

        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.count, 2, "no second backgrounded event without a matching open")

        center.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertEqual(events.last?.name, "Application Opened")
        XCTAssertEqual(events.last?.data["from_background"] as? Bool, true)
        XCTAssertEqual(events.last?.data["build"] as? String, "42")

        clock += 0.25
        center.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(events.last?.data["session_length"] as? Double, 0.25)
        withExtendedLifetime(callbacks) {}
    }
}

final class ScreenTrackingTests: XCTestCase {
    private final class CheckoutViewController: UIViewController {}
    private final class AppNavigationController: UINavigationController {}

    private func name(
        _ className: String,
        title: String? = nil,
        navigationTitle: String? = nil,
        hosting: Bool = false,
        system: Bool = false
    ) -> String? {
        DashXScreenTracking.screenName(
            className: className,
            title: title,
            navigationTitle: navigationTitle,
            isHostingController: hosting,
            isSystemClass: system
        )
    }

    func testNameResolutionOrder() {
        XCTAssertEqual(name("HomeViewController", title: "Home", navigationTitle: "Nav"), "Home")
        XCTAssertEqual(name("HomeViewController", navigationTitle: "Nav"), "Nav")
        XCTAssertEqual(name("HomeViewController", title: "  ", navigationTitle: "Nav"), "Nav")
        XCTAssertEqual(name("HomeViewController"), "HomeViewController")
        XCTAssertEqual(name("MyApp.HomeViewController"), "HomeViewController")
    }

    func testSkipsContainersAndPrivateControllers() {
        for container in ["UINavigationController", "UITabBarController", "UISplitViewController", "UIPageViewController", "UIAlertController"] {
            XCTAssertNil(name(container, title: "Titled"), container)
        }
        XCTAssertNil(name("UIInputWindowController"))
        XCTAssertNil(name("_UIPrivateViewController", title: "Titled"))
    }

    func testHostingAndSystemControllersNeedTitle() {
        XCTAssertNil(name("UIHostingController<AnyView>", hosting: true))
        XCTAssertNil(name("UIHostingController<ModifiedContent<MyApp.Root, _EnvironmentKeyWritingModifier<Bool>>>", hosting: true))
        XCTAssertEqual(name("UIHostingController<AnyView>", title: "Settings", hosting: true), "Settings")
        XCTAssertNil(name("UIViewController", system: true))
        XCTAssertEqual(name("UIViewController", title: "Profile", system: true), "Profile")
    }

    func testResolvesRealControllers() {
        XCTAssertEqual(DashXScreenTracking.screenName(for: CheckoutViewController()), "CheckoutViewController")

        let titled = CheckoutViewController()
        titled.title = "Checkout"
        XCTAssertEqual(DashXScreenTracking.screenName(for: titled), "Checkout")

        XCTAssertNil(DashXScreenTracking.screenName(for: UIViewController()))
        XCTAssertNil(DashXScreenTracking.screenName(for: UINavigationController()))
        XCTAssertNil(DashXScreenTracking.screenName(for: AppNavigationController()))
        XCTAssertNil(DashXScreenTracking.screenName(for: UIAlertController(title: "Oops", message: nil, preferredStyle: .alert)))

        XCTAssertTrue(DashXScreenTracking.isSystemClass(UIViewController.self))
        XCTAssertFalse(DashXScreenTracking.isSystemClass(CheckoutViewController.self))
    }

    func testHostingControllers() {
        let untitled = UIHostingController(rootView: Text("Hi"))
        XCTAssertNil(DashXScreenTracking.screenName(for: untitled))

        let titled = UIHostingController(rootView: Text("Hi"))
        titled.title = "Greeting"
        XCTAssertEqual(DashXScreenTracking.screenName(for: titled), "Greeting")
    }

    func testEnableSwizzlesOnlyOnce() {
        func implementationImage(_ cls: AnyClass, _ selector: Selector) -> String {
            guard let method = class_getInstanceMethod(cls, selector) else { return "" }
            var info = Dl_info()
            dladdr(unsafeBitCast(method_getImplementation(method), to: UnsafeRawPointer.self), &info)
            return info.dli_fname.map { String(cString: $0) } ?? ""
        }
        // Which binary holds DashX's code depends on how the test build links it, so compare
        // against unswizzled methods rather than a path.
        let dashxImage = implementationImage(DashXApplicationLifecycleCallbacks.self, #selector(DashXApplicationLifecycleCallbacks.appForegrounded))
        let uikitImage = implementationImage(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)))
        XCTAssertNotEqual(dashxImage, uikitImage)

        // A second exchange would swap the implementations back.
        DashXScreenTracking.enable()
        DashXScreenTracking.enable()

        XCTAssertEqual(implementationImage(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))), dashxImage)
        XCTAssertEqual(implementationImage(UIViewController.self, #selector(UIViewController.dashx_viewDidAppear(_:))), uikitImage)
    }
}
