import Foundation
import XCTest
@testable import DashX

/// Polls `condition` while servicing the main run loop, so main-queue callbacks keep flowing.
func awaitUntil(
    timeout: TimeInterval = 5,
    what: String = "condition",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: () -> Bool
) {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return }
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    XCTFail("Timed out waiting for: \(what)", file: file, line: line)
}

/// Sleeps while still servicing the main run loop.
func settle(_ seconds: TimeInterval) {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
}

/// Thread-safe box for values written from SDK queues and read by the test.
final class Atomic<Value> {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        get { lock.lock(); defer { lock.unlock() }; return storage }
        set { lock.lock(); defer { lock.unlock() }; storage = newValue }
    }

    func mutate(_ body: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body(&storage)
    }
}

extension Atomic where Value: RangeReplaceableCollection {
    func append(_ element: Value.Element) {
        mutate { $0.append(element) }
    }
}

extension Atomic where Value == Int {
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        storage += 1
        return storage
    }
}

/// An `async` latch: `wait()` suspends until `open()`.
final class Gate {
    private let lock = NSLock()
    private var opened = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if opened {
                lock.unlock()
                continuation.resume()
                return
            }
            waiters.append(continuation)
            lock.unlock()
        }
    }

    func open() {
        lock.lock()
        opened = true
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        pending.forEach { $0.resume() }
    }
}

func chatMessage(_ id: String, seq: Int, externalUid: String? = nil, conversationId: String = "c1") -> DashXChatMessage {
    DashXChatMessage(
        id: id,
        conversationId: conversationId,
        externalUid: externalUid,
        senderId: nil,
        aiRole: "ASSISTANT",
        turnSeq: seq,
        renderedContent: [:],
        createdAt: "2026-08-25 10:00:00",
        sentAt: nil
    )
}

func chatFrame(_ id: String, seq: Int) -> DashXRealtimeMessage {
    .inAppChatMessage(DashXRealtimeChatMessage(id: id, externalUid: "e-\(id)", conversationId: "c1", turnSeq: seq))
}

func graphQLFailure(_ message: String, code: String?) -> DashXClientError {
    .graphQLErrors(DashXGraphQLErrors(messages: [message], code: code))
}
