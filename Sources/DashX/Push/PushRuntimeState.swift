import Foundation

/// Foreground and visibility snapshot so `DashXPush.shouldDisplay` can decide synchronously on the
/// notification thread. The lifecycle observer writes `isForeground`; chat sessions write
/// `visibleConversationIds`, each as one owner: a conversation stays visible while any owner shows
/// it, so one chat identity closing its screen never unsuppresses another's.
final class PushRuntimeState {
    struct Snapshot {
        var isForeground: Bool
        var visibleConversationIds: Set<String>
    }

    private let lock = NSLock()
    // Assume backgrounded until the lifecycle observer reports: that displays rather than drops.
    private var snapshot = Snapshot(isForeground: false, visibleConversationIds: [])
    private var visibleOwners: [String: Set<ObjectIdentifier>] = [:]

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

    func setConversationVisible(_ conversationId: String, owner: ObjectIdentifier, visible: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if visible {
            visibleOwners[conversationId, default: []].insert(owner)
        } else {
            visibleOwners[conversationId]?.remove(owner)
            if visibleOwners[conversationId]?.isEmpty == true { visibleOwners.removeValue(forKey: conversationId) }
        }
        snapshot.visibleConversationIds = Set(visibleOwners.keys)
    }
}
