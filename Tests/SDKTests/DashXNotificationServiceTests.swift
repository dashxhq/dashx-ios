import DashXCore
@testable import DashXNotificationServiceExtension
import XCTest

/// These tests lock the cross-language hash used to stamp `aps.category` on alert pushes.
/// The backend (`apps/messaging/src/notifiers/fcm.rs::dashx_category_id_for_buttons`) has a
/// matching assertion against the same golden value — if either side drifts, CI on one of
/// the two sides fails loudly. Do not change the golden value without updating both.
final class DashXNotificationServiceHashTests: XCTestCase {
    private func button(_ id: String, _ label: String) -> ActionButton {
        let json = """
        {
            "identifier": "\(id)",
            "label": "\(label)"
        }
        """.data(using: .utf8)!
        // Decode via JSON so we exercise the same entry point as a real payload.
        return try! JSONDecoder().decode(ActionButton.self, from: json)
    }

    func testHashIsDeterministic() {
        let buttons = [button("ACCEPT", "Accept"), button("DECLINE", "Decline")]
        let id1 = DashXNotificationService.dashxCategoryId(forButtons: buttons)
        let id2 = DashXNotificationService.dashxCategoryId(forButtons: buttons)
        XCTAssertEqual(id1, id2)
    }

    func testHashFormat() {
        let buttons = [button("ACCEPT", "Accept")]
        let id = DashXNotificationService.dashxCategoryId(forButtons: buttons)
        XCTAssertTrue(id.hasPrefix("DASHX_CAT_"))
        XCTAssertEqual(id.count, 24)
    }

    func testHashMatchesBackendGoldenValue() {
        // Must equal the value asserted in `fcm.rs::tests::category_id_is_deterministic_and_stable`.
        let buttons = [button("ACCEPT", "Accept"), button("DECLINE", "Decline")]
        let id = DashXNotificationService.dashxCategoryId(forButtons: buttons)
        XCTAssertEqual(id, "DASHX_CAT_eeb7e85ba820dd")
    }

    func testDifferentLabelsProduceDifferentHashes() {
        let a = [button("ACCEPT", "Accept")]
        let b = [button("ACCEPT", "Yes")]
        XCTAssertNotEqual(
            DashXNotificationService.dashxCategoryId(forButtons: a),
            DashXNotificationService.dashxCategoryId(forButtons: b)
        )
    }
}
