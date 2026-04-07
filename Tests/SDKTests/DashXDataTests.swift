import XCTest
@testable import DashX

final class DashXNotificationDataTests: XCTestCase {

    // MARK: - DashXNotificationData decoding

    func testFullPayloadDecoding() throws {
        let json = """
        {
            "id": "notif-1",
            "title": "Hello",
            "body": "World",
            "image": "https://example.com/img.png",
            "url": "https://example.com",
            "action_buttons": [{"identifier": "open", "label": "Open", "icon": "icon-link"}]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.id, "notif-1")
        XCTAssertEqual(data.title, "Hello")
        XCTAssertEqual(data.body, "World")
        XCTAssertEqual(data.image, "https://example.com/img.png")
        XCTAssertEqual(data.url, "https://example.com")
        XCTAssertEqual(data.actionButtons?.count, 1)
        XCTAssertEqual(data.actionButtons?.first?.identifier, "open")
        XCTAssertEqual(data.actionButtons?.first?.label, "Open")
        XCTAssertEqual(data.actionButtons?.first?.icon, "icon-link")
        XCTAssertNil(data.screenName)
        XCTAssertNil(data.screenData)
        XCTAssertNil(data.clickAction)
    }

    func testExtendedPayloadDecoding() throws {
        let json = """
        {
            "id": "notif-ext",
            "title": "Hi",
            "body": "Body",
            "url": "https://example.com",
            "screen_name": "Detail",
            "screen_data": {"k": "v"},
            "click_action": "com.app.OPEN",
            "action_buttons": [
                {"identifier": "go", "label": "Go", "url": "https://go", "clickAction": "com.app.GO"}
            ]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.screenName, "Detail")
        XCTAssertEqual(data.screenData?["k"], "v")
        XCTAssertEqual(data.clickAction, "com.app.OPEN")
        XCTAssertEqual(data.actionButtons?.first?.url, "https://go")
        XCTAssertEqual(data.actionButtons?.first?.clickAction, "com.app.GO")
    }

    func testMinimalPayloadDecoding() throws {
        let json = """
        {"id": "notif-2", "title": "Hi", "body": "There"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.id, "notif-2")
        XCTAssertNil(data.image)
        XCTAssertNil(data.url)
        XCTAssertNil(data.screenName)
        XCTAssertNil(data.screenData)
        XCTAssertNil(data.clickAction)
        XCTAssertNil(data.actionButtons)
    }

    func testActionButtonsAsJsonString() throws {
        let json = """
        {
            "id": "notif-3",
            "title": "Test",
            "body": "Body",
            "action_buttons": "[{\\"identifier\\":\\"btn1\\",\\"label\\":\\"Click\\"}]"
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.actionButtons?.count, 1)
        XCTAssertEqual(data.actionButtons?.first?.identifier, "btn1")
        XCTAssertEqual(data.actionButtons?.first?.label, "Click")
        XCTAssertNil(data.actionButtons?.first?.icon)
    }

    // MARK: - ActionButton

    func testActionButtonWithOptionalIcon() throws {
        let json = """
        {"identifier": "act1", "label": "Do it"}
        """.data(using: .utf8)!

        let button = try JSONDecoder().decode(ActionButton.self, from: json)
        XCTAssertEqual(button.identifier, "act1")
        XCTAssertEqual(button.label, "Do it")
        XCTAssertNil(button.icon)
    }

    func testActionButtonWithIcon() throws {
        let json = """
        {"identifier": "act2", "label": "Open", "icon": "link-icon"}
        """.data(using: .utf8)!

        let button = try JSONDecoder().decode(ActionButton.self, from: json)
        XCTAssertEqual(button.icon, "link-icon")
    }

    // MARK: - Stringified screen_data

    func testScreenDataAsNativeDict() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "screen_name": "Home", "screen_data": {"k": "v"}}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.screenData?["k"], "v")
    }

    func testScreenDataAsStringifiedJson() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "screen_name": "Home", "screen_data": "{\\"k\\":\\"v\\"}"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.screenData?["k"], "v")
    }

    func testActionButtonScreenDataAsStringifiedJson() throws {
        let json = """
        {"identifier": "btn", "label": "Go", "screenData": "{\\"id\\":\\"1\\"}"}
        """.data(using: .utf8)!

        let button = try JSONDecoder().decode(ActionButton.self, from: json)
        XCTAssertEqual(button.screenData?["id"], "1")
    }

    // MARK: - Bool from string (FCM delivers all values as strings)

    func testRichLandingAsStringTrue() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "url": "https://example.com", "rich_landing": "true"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.richLanding, true)
    }

    func testRichLandingAsStringFalse() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "rich_landing": "false"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.richLanding, false)
    }

    func testRichLandingAsNativeBool() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "rich_landing": true}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.richLanding, true)
    }

    func testActionButtonRichLandingAsString() throws {
        let json = """
        {"identifier": "btn", "label": "Go", "url": "https://example.com", "richLanding": "true"}
        """.data(using: .utf8)!

        let button = try JSONDecoder().decode(ActionButton.self, from: json)
        XCTAssertEqual(button.richLanding, true)
    }

    func testScreenDataMalformedStringReturnsNil() throws {
        let json = """
        {"id": "n", "title": "T", "body": "B", "screen_data": "not json"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertNil(data.screenData)
    }

    // MARK: - DashXNotificationMessage helpers

    func testDashxNotificationMessageWithValidPayload() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: """
            {"id":"n1","title":"T","body":"B","url":"https://dashx.com"}
            """
        ]

        XCTAssertEqual(message.dashxNotificationId(), "n1")
        XCTAssertEqual(message.dashxNotificationUrl(), URL(string: "https://dashx.com"))

        let data = message.dashxNotificationData()
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.title, "T")
    }

    func testDashxNotificationMessageWithoutUrl() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: """
            {"id":"n2","title":"T","body":"B"}
            """
        ]

        XCTAssertEqual(message.dashxNotificationId(), "n2")
        XCTAssertNil(message.dashxNotificationUrl())
    }

    func testDashxNotificationMessageWithMissingKey() {
        let message: DashXNotificationMessage = ["other": "data"]
        XCTAssertNil(message.dashxNotificationData())
        XCTAssertNil(message.dashxNotificationId())
        XCTAssertNil(message.dashxNotificationUrl())
    }

    func testDashxNotificationMessageWithInvalidJson() {
        let message: DashXNotificationMessage = [
            Constants.DASHX_NOTIFICATION_DATA_KEY: "not json at all {"
        ]
        XCTAssertNil(message.dashxNotificationData())
    }

    // MARK: - navigationAction(forActionIdentifier:)

    func testNavigationAction_defaultTap_prefersScreenOverUrl() throws {
        let json = """
        {
            "id": "n1",
            "title": "T",
            "body": "B",
            "url": "https://example.com",
            "screen_name": "Home"
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier")
        guard case let .screen(name, screenData) = action else {
            return XCTFail("Expected screen action")
        }
        XCTAssertEqual(name, "Home")
        XCTAssertNil(screenData)
    }

    func testNavigationAction_defaultTap_deepLinkFromUrl() throws {
        let json = """
        {"id": "n2", "title": "T", "body": "B", "url": "https://open.example"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier")
        guard case let .deepLink(url) = action else {
            return XCTFail("Expected deepLink")
        }
        XCTAssertEqual(url.absoluteString, "https://open.example")
    }

    func testNavigationAction_defaultTap_richLandingFromUrl() throws {
        let json = """
        {"id": "n2rl", "title": "T", "body": "B", "url": "https://landing.example", "rich_landing": true}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier")
        guard case let .richLanding(url) = action else {
            return XCTFail("Expected richLanding")
        }
        XCTAssertEqual(url.absoluteString, "https://landing.example")
    }

    func testNavigationAction_actionButton_deepLink() throws {
        let json = """
        {
            "id": "n3",
            "title": "T",
            "body": "B",
            "action_buttons": [{"identifier": "go", "label": "Go", "url": "https://btn"}]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "go")
        guard case let .deepLink(url) = action else {
            return XCTFail("Expected deepLink for button")
        }
        XCTAssertEqual(url.absoluteString, "https://btn")
    }

    func testNavigationAction_actionButton_prefersScreenOverUrl() throws {
        let json = """
        {
            "id": "n4",
            "title": "T",
            "body": "B",
            "action_buttons": [
                {
                    "identifier": "cart",
                    "label": "Cart",
                    "url": "https://cart",
                    "screenName": "Cart",
                    "screenData": {"id": "1"}
                }
            ]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "cart")
        guard case let .screen(name, screenData) = action else {
            return XCTFail("Expected screen for button")
        }
        XCTAssertEqual(name, "Cart")
        XCTAssertEqual(screenData?["id"], "1")
    }

    func testNavigationAction_defaultTap_clickActionFallback() throws {
        let json = """
        {"id": "nca", "title": "T", "body": "B", "click_action": "com.app.OPEN"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier")
        guard case let .clickAction(actionString) = action else {
            return XCTFail("Expected clickAction")
        }
        XCTAssertEqual(actionString, "com.app.OPEN")
    }

    func testNavigationAction_actionButton_clickActionFallback() throws {
        let json = """
        {
            "id": "ncab",
            "title": "T",
            "body": "B",
            "action_buttons": [
                {"identifier": "act", "label": "Act", "clickAction": "com.app.ACT"}
            ]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "act")
        guard case let .clickAction(actionString) = action else {
            return XCTFail("Expected clickAction for button")
        }
        XCTAssertEqual(actionString, "com.app.ACT")
    }

    func testNavigationAction_actionButton_richLanding() throws {
        let json = """
        {
            "id": "n5",
            "title": "T",
            "body": "B",
            "action_buttons": [
                {
                    "identifier": "open",
                    "label": "Open",
                    "url": "https://promo.example",
                    "richLanding": true
                }
            ]
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        let action = data.navigationAction(forActionIdentifier: "open")
        guard case let .richLanding(url) = action else {
            return XCTFail("Expected richLanding for button")
        }
        XCTAssertEqual(url.absoluteString, "https://promo.example")
    }
}
