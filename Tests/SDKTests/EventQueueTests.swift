import XCTest
@testable import DashX

final class QueuedEventTests: XCTestCase {

    // MARK: - Encoding / Decoding

    func testRoundTripEncoding() throws {
        let original = QueuedEvent(
            event: "button_click",
            dataJSON: QueuedEvent.makeJSONData(from: ["key": "value", "count": 42]),
            accountUid: "user_123",
            accountAnonymousUid: "anon_456",
            enqueuedAt: Date(timeIntervalSince1970: 1700000000),
            retryCount: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(QueuedEvent.self, from: data)

        XCTAssertEqual(decoded.event, "button_click")
        XCTAssertEqual(decoded.accountUid, "user_123")
        XCTAssertEqual(decoded.accountAnonymousUid, "anon_456")
        XCTAssertEqual(decoded.retryCount, 3)
        XCTAssertEqual(decoded.enqueuedAt.timeIntervalSince1970, 1700000000.0, accuracy: 1.0)

        let decodedData = decoded.decodedData()
        XCTAssertEqual(decodedData?["key"] as? String, "value")
        XCTAssertEqual(decodedData?["count"] as? Int, 42)
    }

    func testMinimalEvent() throws {
        let event = QueuedEvent(
            event: "page_view",
            dataJSON: nil,
            accountUid: nil,
            accountAnonymousUid: nil,
            enqueuedAt: Date(),
            retryCount: 0
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(QueuedEvent.self, from: data)

        XCTAssertEqual(decoded.event, "page_view")
        XCTAssertNil(decoded.dataJSON)
        XCTAssertNil(decoded.accountUid)
        XCTAssertNil(decoded.accountAnonymousUid)
        XCTAssertEqual(decoded.retryCount, 0)
    }

    func testLegacyStringDataMigration() throws {
        // Simulate legacy format where "data" was [String: String]
        let legacyJSON = """
        {
            "event": "legacy_event",
            "data": {"foo": "bar", "baz": "123"},
            "enqueuedAt": 1700000000,
            "retryCount": 0
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(QueuedEvent.self, from: legacyJSON)

        XCTAssertEqual(decoded.event, "legacy_event")
        XCTAssertNotNil(decoded.dataJSON)

        let decodedData = decoded.decodedData()
        XCTAssertEqual(decodedData?["foo"] as? String, "bar")
        XCTAssertEqual(decodedData?["baz"] as? String, "123")
    }

    func testRetryCountDefaultsToZero() throws {
        let json = """
        {
            "event": "test",
            "enqueuedAt": 1700000000
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(QueuedEvent.self, from: json)
        XCTAssertEqual(decoded.retryCount, 0)
    }

    // MARK: - makeJSONData

    func testMakeJSONDataWithValidDictionary() {
        let data = QueuedEvent.makeJSONData(from: ["key": "value"])
        XCTAssertNotNil(data)

        let parsed = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        XCTAssertEqual(parsed?["key"] as? String, "value")
    }

    func testMakeJSONDataWithNilReturnsNil() {
        let data = QueuedEvent.makeJSONData(from: nil)
        XCTAssertNil(data)
    }

    // MARK: - decodedData

    func testDecodedDataReturnsNilForNilJSON() {
        let event = QueuedEvent(
            event: "test",
            dataJSON: nil,
            accountUid: nil,
            accountAnonymousUid: nil,
            enqueuedAt: Date(),
            retryCount: 0
        )
        XCTAssertNil(event.decodedData())
    }

    func testDecodedDataPreservesTypes() {
        let original: [String: Any] = [
            "string": "hello",
            "number": 42,
            "boolean": true,
            "decimal": 3.14
        ]
        let jsonData = QueuedEvent.makeJSONData(from: original)!
        let event = QueuedEvent(
            event: "test",
            dataJSON: jsonData,
            accountUid: nil,
            accountAnonymousUid: nil,
            enqueuedAt: Date(),
            retryCount: 0
        )

        let decoded = event.decodedData()!
        XCTAssertEqual(decoded["string"] as? String, "hello")
        XCTAssertEqual(decoded["number"] as? Int, 42)
        XCTAssertEqual(decoded["boolean"] as? Bool, true)
        XCTAssertEqual(decoded["decimal"] as! Double, 3.14, accuracy: 0.001)
    }

    // MARK: - List encoding (simulates persistence)

    func testEventListRoundTrip() throws {
        let events = [
            QueuedEvent(event: "e1", dataJSON: nil, accountUid: "u1", accountAnonymousUid: nil, enqueuedAt: Date(), retryCount: 0),
            QueuedEvent(event: "e2", dataJSON: QueuedEvent.makeJSONData(from: ["a": "b"]), accountUid: nil, accountAnonymousUid: "a2", enqueuedAt: Date(), retryCount: 5)
        ]

        let data = try JSONEncoder().encode(events)
        let decoded = try JSONDecoder().decode([QueuedEvent].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].event, "e1")
        XCTAssertEqual(decoded[0].accountUid, "u1")
        XCTAssertEqual(decoded[1].event, "e2")
        XCTAssertEqual(decoded[1].retryCount, 5)
        XCTAssertEqual(decoded[1].decodedData()?["a"] as? String, "b")
    }
}
