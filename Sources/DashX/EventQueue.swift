import Foundation

/// Persisted queue item. `dataJSON` preserves `[String: Any]` types via JSON (legacy `data` was `[String: String]`).
struct QueuedEvent: Codable {
    let event: String
    /// JSON object bytes for event payload; `nil` means no custom data.
    let dataJSON: Data?
    let accountUid: String?
    let accountAnonymousUid: String?
    let enqueuedAt: Date
    var retryCount: Int

    enum CodingKeys: String, CodingKey {
        case event
        case dataJSON
        case legacyStringData = "data"
        case accountUid
        case accountAnonymousUid
        case enqueuedAt
        case retryCount
    }

    init(
        event: String,
        dataJSON: Data?,
        accountUid: String?,
        accountAnonymousUid: String?,
        enqueuedAt: Date,
        retryCount: Int
    ) {
        self.event = event
        self.dataJSON = dataJSON
        self.accountUid = accountUid
        self.accountAnonymousUid = accountAnonymousUid
        self.enqueuedAt = enqueuedAt
        self.retryCount = retryCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        event = try c.decode(String.self, forKey: .event)
        accountUid = try c.decodeIfPresent(String.self, forKey: .accountUid)
        accountAnonymousUid = try c.decodeIfPresent(String.self, forKey: .accountAnonymousUid)
        enqueuedAt = try c.decode(Date.self, forKey: .enqueuedAt)
        retryCount = try c.decodeIfPresent(Int.self, forKey: .retryCount) ?? 0

        if let json = try c.decodeIfPresent(Data.self, forKey: .dataJSON) {
            dataJSON = json
        } else if let legacy = try c.decodeIfPresent([String: String].self, forKey: .legacyStringData) {
            let dict = legacy.mapValues { $0 as Any }
            dataJSON = Self.makeJSONData(from: dict)
        } else {
            dataJSON = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(event, forKey: .event)
        try c.encodeIfPresent(dataJSON, forKey: .dataJSON)
        try c.encodeIfPresent(accountUid, forKey: .accountUid)
        try c.encodeIfPresent(accountAnonymousUid, forKey: .accountAnonymousUid)
        try c.encode(enqueuedAt, forKey: .enqueuedAt)
        try c.encode(retryCount, forKey: .retryCount)
    }

    static func makeJSONData(from dictionary: [String: Any]?) -> Data? {
        guard let dictionary else { return nil }
        guard JSONSerialization.isValidJSONObject(dictionary) else {
            DashXLog.e(tag: "EventQueue", "Event data is not a valid JSON object. Properties will be dropped.")
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }

    func decodedData() -> [String: Any]? {
        guard let dataJSON else { return nil }
        return try? JSONSerialization.jsonObject(with: dataJSON) as? [String: Any]
    }
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
        let payload = QueuedEvent.makeJSONData(from: data)
        let queued = QueuedEvent(
            event: event,
            dataJSON: payload,
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
            self.retryTimer?.cancel()
            self.flushNextIfNeeded()
        }
    }

    func flush() {
        queue.async { [weak self] in
            self?.flushNextIfNeeded()
        }
    }

    var queuedCount: Int {
        queue.sync { pendingEvents.count }
    }

    // MARK: - Sequential flush + retry

    private func flushNextIfNeeded() {
        guard !isFlushing, !pendingEvents.isEmpty else { return }

        guard case .online = NetworkMonitor.shared.connection else {
            DashXLog.d(tag: "EventQueue", "Offline — deferring flush of \(pendingEvents.count) events")
            scheduleRetryFromHead()
            return
        }

        isFlushing = true
        let head = pendingEvents[0]
        let data = head.decodedData()

        DashXClient.instance.track(
            head.event,
            withData: data,
            queuedAccountUid: head.accountUid,
            queuedAccountAnonymousUid: head.accountAnonymousUid
        ) { [weak self] success in
            guard let self else { return }
            self.queue.async {
                guard self.isFlushing else { return }
                if success {
                    self.pendingEvents.removeFirst()
                    self.saveToDisk()
                    self.isFlushing = false
                    self.flushNextIfNeeded()
                } else {
                    var failed = self.pendingEvents[0]
                    failed.retryCount += 1
                    if failed.retryCount >= self.maxRetries {
                        DashXLog.e(tag: "EventQueue", "Event '\(failed.event)' exceeded max retries — dropping")
                        self.pendingEvents.removeFirst()
                        self.saveToDisk()
                        self.isFlushing = false
                        self.flushNextIfNeeded()
                    } else {
                        self.pendingEvents[0] = failed
                        self.saveToDisk()
                        self.isFlushing = false
                        self.scheduleRetryFromHead()
                    }
                }
            }
        }
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
            self?.flushNextIfNeeded()
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
