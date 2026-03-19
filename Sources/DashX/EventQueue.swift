import Foundation

struct QueuedEvent: Codable {
    let event: String
    let data: [String: String]?
    let accountUid: String?
    let accountAnonymousUid: String?
    let enqueuedAt: Date
    var retryCount: Int
}

final class EventQueue {
    static let shared = EventQueue()

    private let queue = DispatchQueue(label: "com.dashx.eventqueue")
    private let storageKey = "com.dashx.sdk.event_queue"
    private let maxQueueSize = 1000
    private let maxRetries = 10
    private let baseRetryInterval: TimeInterval = 2.0

    private var pendingEvents: [QueuedEvent] = []
    private var isFlushing = false
    private var retryTimer: DispatchWorkItem?

    private init() {
        loadFromDisk()
        observeNetworkChanges()
    }

    // MARK: - Public Interface

    func enqueue(event: String, data: [String: Any]?, accountUid: String?, accountAnonymousUid: String?) {
        let stringData = data?.compactMapValues { "\($0)" }
        let queued = QueuedEvent(
            event: event,
            data: stringData,
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid,
            enqueuedAt: Date(),
            retryCount: 0
        )

        queue.async { [weak self] in
            guard let self else { return }
            if self.pendingEvents.count >= self.maxQueueSize {
                self.pendingEvents.removeFirst()
            }
            self.pendingEvents.append(queued)
            self.saveToDisk()
            DashXLog.d(tag: "EventQueue", "Enqueued event '\(event)' (queue size: \(self.pendingEvents.count))")
            self.scheduleRetryFromHead()
        }
    }

    func flush() {
        queue.async { [weak self] in
            self?.flushInternal()
        }
    }

    var queuedCount: Int {
        queue.sync { pendingEvents.count }
    }

    // MARK: - Internal

    private func flushInternal() {
        guard !isFlushing, !pendingEvents.isEmpty else { return }

        guard case .online = NetworkMonitor.shared.connection else {
            DashXLog.d(tag: "EventQueue", "Offline — deferring flush of \(pendingEvents.count) events")
            scheduleRetryFromHead()
            return
        }

        isFlushing = true

        let batch = pendingEvents
        pendingEvents.removeAll()
        saveToDisk()

        DashXLog.d(tag: "EventQueue", "Flushing \(batch.count) queued events")

        for event in batch {
            let dataDict: [String: Any]? = event.data
            DashXClient.instance.track(event.event, withData: dataDict)
        }

        isFlushing = false
    }

    // MARK: - Retry Scheduling

    private func scheduleRetryFromHead() {
        guard let first = pendingEvents.first else { return }
        let retryCount = first.retryCount
        guard retryCount < maxRetries else {
            DashXLog.e(tag: "EventQueue", "Event '\(first.event)' exceeded max retries — dropping")
            pendingEvents.removeFirst()
            saveToDisk()
            scheduleRetryFromHead()
            return
        }

        let delay = baseRetryInterval * pow(2.0, Double(retryCount))
        let jitter = Double.random(in: 0...1)
        let totalDelay = min(delay + jitter, 300)

        DashXLog.d(tag: "EventQueue", "Scheduling retry in \(String(format: "%.1f", totalDelay))s (\(pendingEvents.count) events queued)")

        retryTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.flushInternal()
        }
        retryTimer = work
        queue.asyncAfter(deadline: .now() + totalDelay, execute: work)
    }

    // MARK: - Network Observation

    private func observeNetworkChanges() {
        NotificationCenter.default.addObserver(
            forName: .dashXNetworkBecameAvailable,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            DashXLog.d(tag: "EventQueue", "Network available — flushing queue")
            self?.flush()
        }
    }

    // MARK: - Persistence

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(pendingEvents)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            DashXLog.e(tag: "EventQueue", "Failed to persist event queue: \(error)")
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            pendingEvents = try JSONDecoder().decode([QueuedEvent].self, from: data)
            DashXLog.d(tag: "EventQueue", "Loaded \(pendingEvents.count) queued events from disk")
        } catch {
            DashXLog.e(tag: "EventQueue", "Failed to load event queue: \(error)")
            pendingEvents = []
        }
    }
}
