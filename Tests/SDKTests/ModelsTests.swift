import XCTest
@testable import DashX

final class ModelsTests: XCTestCase {

    // MARK: - Preference

    func testPreferenceDefaults() {
        let pref = Preference()
        XCTAssertNil(pref.enabled)
        XCTAssertNil(pref.email)
        XCTAssertNil(pref.push)
        XCTAssertNil(pref.sms)
        XCTAssertNil(pref.whatsapp)
    }

    func testPreferenceRoundTrip() throws {
        let original = Preference(enabled: true, email: false, push: true, sms: false, whatsapp: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Preference.self, from: data)

        XCTAssertEqual(decoded.enabled, true)
        XCTAssertEqual(decoded.email, false)
        XCTAssertEqual(decoded.push, true)
        XCTAssertEqual(decoded.sms, false)
        XCTAssertEqual(decoded.whatsapp, true)
    }

    // MARK: - PrepareAssetResponse

    func testPrepareAssetResponseDecoding() throws {
        let json = """
        {
            "id": "asset_123",
            "data": {
                "upload": {
                    "url": "https://storage.example.com/upload",
                    "headers": {"x-goog-meta-origin-id": "asset_123"}
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PrepareAssetResponse.self, from: json)
        XCTAssertEqual(response.id, "asset_123")
        XCTAssertEqual(response.data?.upload?.url, "https://storage.example.com/upload")
        XCTAssertEqual(response.data?.upload?.headers?["x-goog-meta-origin-id"], "asset_123")
    }

    // MARK: - AssetResponse

    func testAssetResponseDecoding() throws {
        let json = """
        {
            "status": "ready",
            "data": {
                "asset": {
                    "status": "ready",
                    "url": "https://example.com/video.mp4",
                    "playbackIds": [{"id": "pb_1", "policy": "public"}]
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AssetResponse.self, from: json)
        XCTAssertEqual(response.status, "ready")
        XCTAssertEqual(response.data?.assetData?.status, "ready")
        XCTAssertEqual(response.data?.assetData?.url, "https://example.com/video.mp4")
        XCTAssertEqual(response.data?.assetData?.playbackIds?.first?.id, "pb_1")
        XCTAssertEqual(response.data?.assetData?.playbackIds?.first?.policy, "public")
    }

    func testAssetResponseMinimal() throws {
        let json = """
        {"status": "waiting"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AssetResponse.self, from: json)
        XCTAssertEqual(response.status, "waiting")
        XCTAssertNil(response.data)
    }

    // MARK: - PlaybackData

    func testPlaybackDataOptionalFields() throws {
        let json = """
        {"policy": "signed"}
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(PlaybackData.self, from: json)
        XCTAssertNil(data.id)
        XCTAssertEqual(data.policy, "signed")
    }
}
