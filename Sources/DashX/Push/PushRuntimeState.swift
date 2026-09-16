import Foundation

/// Foreground and visibility snapshot so `DashXPush.shouldDisplay` can decide synchronously on the
/// notification thread. The lifecycle observer writes `isForeground`; chat sessions write
/// `visibleConversationIds`.
final class PushRuntimeState {
    struct Snapshot {
        var isForeground: Bool
        var visibleConversationIds: Set<String>
    }

    private let lock = NSLock()
    // Assume backgrounded until the lifecycle observer reports: that displays rather than drops.
    private var snapshot = Snapshot(isForeground: false, visibleConversationIds: [])

    func get() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    func setForeground(_ foreground: Bool) {
        lock.lock()
        defer { lock.unlock() }
        snapshot.isForeground = foreground
    }

    func setConversationVisible(_ conversationId: String, visible: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if visible {
            snapshot.visibleConversationIds.insert(conversationId)
        } else {
            snapshot.visibleConversationIds.remove(conversationId)
        }
    }

    /// Identity switch / reset: visibility is stale, foreground is not.
    func clearVisible() {
        lock.lock()
        defer { lock.unlock() }
        snapshot.visibleConversationIds = []
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        snapshot = Snapshot(isForeground: false, visibleConversationIds: [])
    }
}
