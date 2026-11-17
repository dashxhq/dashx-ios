import DashX
import UIKit
import XCTest
@testable import DashXSmokeHost

/// Runs inside a scene-based host that opened a conversation during `didFinishLaunching`. Nothing
/// here posts a lifecycle notification: UIKit's own cold launch must bring the SDK to the foreground.
final class SceneColdLaunchSmokeTests: XCTestCase {
    func testConversationOpenedAtLaunchConnectsWithoutAForegroundCycle() throws {
        let host = SmokeHost.shared
        XCTAssertNil(host.startError)
        XCTAssertEqual(
            host.launchApplicationState, .background,
            "a scene-based app reports .background during didFinishLaunching; otherwise this launch does not exercise the foreground notification"
        )
        let lease = try XCTUnwrap(host.lease)

        awaitUntil(what: "the realtime connection to reach .connected") { DashX.connectionState == .connected }
        awaitUntil(what: "the conversation to reach .ready") {
            if case .ready = lease.state { return true }
            return false
        }

        guard case .ready(let messages, let hasOlderMessages, _) = lease.state else { return }
        XCTAssertEqual(messages.map(\.id), [SmokeHost.messageId])
        XCTAssertFalse(hasOlderMessages)
        XCTAssertFalse(host.didEnterBackground, "the launch must connect without a background/foreground cycle")
    }

    private func awaitUntil(timeout: TimeInterval = 15, what: String, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTFail("Timed out waiting for \(what); connection is \(DashX.connectionState), conversation is \(String(describing: SmokeHost.shared.lease?.state))")
    }
}
