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
        DashXClient.instance.setIdentity(uid: "user-123", token: "ignored")
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID),
            "user-123"
        )

        DashXClient.instance.reset()
        XCTAssertNil(UserDefaults.standard.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID))
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
        XCTAssertEqual(defaultLibrary.name, "com.dashx.ios")
        XCTAssertEqual(defaultLibrary.version, "1.0.21")

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
