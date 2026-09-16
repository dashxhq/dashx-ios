import Foundation
import UserNotifications

/// Host-supplied final say on displaying a DashX notification in the foreground.
public typealias DashXNotificationDisplayDecider = (DashXNotificationData) -> Bool

/// Push helpers for hosts with their own `UNUserNotificationCenterDelegate`; `DashXAppDelegate`
/// uses the same entry points.
public enum DashXPush {
    static let inAppChatScreenName = "in_app_chat_conversation"
    private static let tag = "DashXPush"

    private static let deciderLock = NSLock()
    private static var _displayDecider: DashXNotificationDisplayDecider?

    static var displayDecider: DashXNotificationDisplayDecider? {
        get { deciderLock.lock(); defer { deciderLock.unlock() }; return _displayDecider }
        set { deciderLock.lock(); defer { deciderLock.unlock() }; _displayDecider = newValue }
    }

    public static func isDashXMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        userInfo[DashXNotificationKeys.payloadBlock] != nil
    }

    /// The conversation a chat push belongs to, or nil for every other notification.
    public static func chatConversationId(in payload: DashXNotificationData) -> String? {
        guard payload.screenName == inAppChatScreenName else { return nil }
        return payload.screenData?["conversationId"]
    }

    /// Whether a notification arriving in the foreground should be presented: a chat push for a
    /// conversation currently on screen is suppressed, then the host decider decides. Non-DashX or
    /// unparseable payloads are displayed.
    public static func shouldDisplay(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let payload = userInfo.dashxNotificationData() else { return true }
        return shouldDisplay(payload)
    }

    public static func shouldDisplay(_ payload: DashXNotificationData) -> Bool {
        shouldDisplay(payload, snapshot: DashXClient.instance.pushRuntime.get(), decider: displayDecider)
    }

    static func shouldDisplay(
        _ payload: DashXNotificationData,
        snapshot: PushRuntimeState.Snapshot,
        decider: DashXNotificationDisplayDecider?
    ) -> Bool {
        if let conversationId = chatConversationId(in: payload),
           snapshot.isForeground,
           snapshot.visibleConversationIds.contains(conversationId)
        {
            DashXLog.d(tag: tag, "Suppressing chat push: conversation \(conversationId) is visible")
            return false
        }
        return decider?(payload) ?? true
    }

    /// Removes a conversation's delivered notifications; called when its screen opens.
    static func dismissConversationNotifications(conversationId: String) {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { delivered in
            let identifiers = delivered.compactMap { notification -> String? in
                guard let payload = notification.request.content.userInfo.dashxNotificationData(),
                      chatConversationId(in: payload) == conversationId
                else { return nil }
                return notification.request.identifier
            }
            guard !identifiers.isEmpty else { return }
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }
}
