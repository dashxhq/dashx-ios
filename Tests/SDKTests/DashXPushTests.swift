import XCTest
@testable import DashX

/// Foreground presentation: chat pushes for the conversation on screen are suppressed; every other
/// notification keeps the pre-chat behaviour unless the host's decider vetoes it.
final class DashXPushTests: XCTestCase {

    private func payload(screenName: String? = nil, conversationId: String? = nil) throws -> DashXNotificationData {
        var json: [String: Any] = ["id": "msg-1", "title": "Reply", "body": "Hello"]
        if let screenName { json["screen_name"] = screenName }
        if let conversationId { json["screen_data"] = ["conversationId": conversationId] }
        let bytes = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(DashXNotificationData.self, from: bytes)
    }

    private func snapshot(foreground: Bool, visible: Set<String>) -> PushRuntimeState.Snapshot {
        PushRuntimeState.Snapshot(isForeground: foreground, visibleConversationIds: visible)
    }

    func testChatConversationIdIsReadFromScreenDataOnlyForChatPushes() throws {
        XCTAssertEqual(DashXPush.chatConversationId(in: try payload(screenName: "in_app_chat_conversation", conversationId: "c1")), "c1")
        XCTAssertNil(DashXPush.chatConversationId(in: try payload(screenName: "orders", conversationId: "c1")))
        XCTAssertNil(DashXPush.chatConversationId(in: try payload()))
    }

    func testVisibleConversationInForegroundSuppressesItsChatPush() throws {
        let chat = try payload(screenName: "in_app_chat_conversation", conversationId: "c1")
        XCTAssertFalse(DashXPush.shouldDisplay(chat, snapshot: snapshot(foreground: true, visible: ["c1"]), decider: nil))
        XCTAssertTrue(DashXPush.shouldDisplay(chat, snapshot: snapshot(foreground: true, visible: ["c2"]), decider: nil))
        XCTAssertTrue(DashXPush.shouldDisplay(chat, snapshot: snapshot(foreground: false, visible: ["c1"]), decider: nil),
                      "backgrounded: the visitor is not looking at the conversation")
    }

    func testNonChatPushIsDisplayedRegardlessOfVisibility() throws {
        let promo = try payload(screenName: "orders", conversationId: "c1")
        XCTAssertTrue(DashXPush.shouldDisplay(promo, snapshot: snapshot(foreground: true, visible: ["c1"]), decider: nil))
    }

    func testHostDeciderGetsTheFinalSay() throws {
        let promo = try payload()
        XCTAssertFalse(DashXPush.shouldDisplay(promo, snapshot: snapshot(foreground: true, visible: []), decider: { _ in false }))
        XCTAssertTrue(DashXPush.shouldDisplay(promo, snapshot: snapshot(foreground: true, visible: []), decider: { _ in true }))
    }

    func testUnparseablePayloadsAreDisplayed() {
        XCTAssertTrue(DashXPush.shouldDisplay(["dashx": "{not-json"]))
        XCTAssertTrue(DashXPush.shouldDisplay(["aps": ["alert": "hi"]]))
        XCTAssertFalse(DashXPush.isDashXMessage(["aps": ["alert": "hi"]]))
        XCTAssertTrue(DashXPush.isDashXMessage(["dashx": "{}"]))
    }

    func testPushRuntimeStateWritersOwnTheirFields() {
        let state = PushRuntimeState()
        XCTAssertFalse(state.get().isForeground, "before the lifecycle observer reports, assume backgrounded")
        state.setForeground(true)
        state.setConversationVisible("c1", visible: true)
        state.setConversationVisible("c2", visible: true)
        state.setConversationVisible("c1", visible: false)
        XCTAssertEqual(state.get().visibleConversationIds, ["c2"])
        state.clearVisible()
        XCTAssertTrue(state.get().isForeground, "clearing visibility must not touch foreground")
        XCTAssertTrue(state.get().visibleConversationIds.isEmpty)
        state.reset()
        XCTAssertFalse(state.get().isForeground)
    }
}
