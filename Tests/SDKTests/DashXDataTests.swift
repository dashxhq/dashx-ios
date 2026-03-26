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
    }

    func testMinimalPayloadDecoding() throws {
        let json = """
        {"id": "notif-2", "title": "Hi", "body": "There"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(DashXNotificationData.self, from: json)
        XCTAssertEqual(data.id, "notif-2")
        XCTAssertNil(data.image)
        XCTAssertNil(data.url)
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
}
