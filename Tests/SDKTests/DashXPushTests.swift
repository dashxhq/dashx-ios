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
        XCTAssertTrue(DashXPush.shouldDisplay(promo, snapshot: snapshot(foreground: false, visible: []), decider: { _ in false }),
                      "backgrounded: the decider is a foreground decision, a silent push still schedules its notification")
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
        let owner = ObjectIdentifier(NSObject())
        state.setConversationVisible("c1", owner: owner, visible: true)
        state.setConversationVisible("c2", owner: owner, visible: true)
        state.setConversationVisible("c1", owner: owner, visible: false)
        XCTAssertEqual(state.get().visibleConversationIds, ["c2"])
        XCTAssertTrue(state.get().isForeground, "visibility writes must not touch foreground")
    }

    func testAConversationStaysVisibleWhileAnyOwnerShowsIt() {
        let state = PushRuntimeState()
        let first = NSObject()
        let second = NSObject()
        state.setConversationVisible("c1", owner: ObjectIdentifier(first), visible: true)
        state.setConversationVisible("c1", owner: ObjectIdentifier(second), visible: true)

        state.setConversationVisible("c1", owner: ObjectIdentifier(first), visible: false)
        XCTAssertEqual(state.get().visibleConversationIds, ["c1"], "the second owner still shows it")
        state.setConversationVisible("c1", owner: ObjectIdentifier(first), visible: false)
        XCTAssertEqual(state.get().visibleConversationIds, ["c1"], "a repeated hide is not another owner's")

        state.setConversationVisible("c1", owner: ObjectIdentifier(second), visible: false)
        XCTAssertTrue(state.get().visibleConversationIds.isEmpty)
    }
}
