import XCTest
@testable import DashX

final class UtilsTests: XCTestCase {

    // MARK: - generateMuxVideoUrl

    func testGenerateMuxVideoUrl() {
        let url = generateMuxVideoUrl(playbackId: "abc123")
        XCTAssertEqual(url, "https://stream.mux.com/abc123.m3u8")
    }

    func testGenerateMuxVideoUrlWithEmptyId() {
        let url = generateMuxVideoUrl(playbackId: "")
        XCTAssertEqual(url, "https://stream.mux.com/.m3u8")
    }

    // MARK: - URL.mimeType()

    func testMimeTypeForJpeg() {
        let url = URL(fileURLWithPath: "/tmp/photo.jpg")
        let mime = url.mimeType()
        XCTAssertTrue(mime.contains("jpeg") || mime.contains("jpg"), "Expected JPEG mime type, got: \(mime)")
    }

    func testMimeTypeForPng() {
        let url = URL(fileURLWithPath: "/tmp/image.png")
        let mime = url.mimeType()
        XCTAssertEqual(mime, "image/png")
    }

    func testMimeTypeForUnknownExtension() {
        let url = URL(fileURLWithPath: "/tmp/file.xyz123unknown")
        let mime = url.mimeType()
        XCTAssertEqual(mime, "application/octet-stream")
    }

    func testMimeTypeForNoExtension() {
        let url = URL(fileURLWithPath: "/tmp/noextension")
        let mime = url.mimeType()
        XCTAssertEqual(mime, "application/octet-stream")
    }

    // MARK: - Data.string

    func testDataToHexString() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        XCTAssertEqual(data.string, "48656c6c6f")
    }

    func testEmptyDataString() {
        let data = Data()
        XCTAssertEqual(data.string, "")
    }

    // MARK: - Constants

    func testConstantsPackageName() {
        XCTAssertEqual(Constants.PACKAGE_NAME, "com.dashx.ios")
    }

    func testUserPreferencesKeysHaveCorrectPrefix() {
        XCTAssertTrue(Constants.USER_PREFERENCES_KEY_ACCOUNT_UID.hasPrefix("com.dashx.ios"))
        XCTAssertTrue(Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID.hasPrefix("com.dashx.ios"))
        XCTAssertTrue(Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN.hasPrefix("com.dashx.ios"))
        XCTAssertTrue(Constants.USER_PREFERENCES_KEY_FCM_TOKEN.hasPrefix("com.dashx.ios"))
        XCTAssertTrue(Constants.USER_PREFERENCES_KEY_BUILD.hasPrefix("com.dashx.ios"))
    }

    func testInternalEventNames() {
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_INSTALLED.isEmpty)
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_UPDATED.isEmpty)
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_OPENED.isEmpty)
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_BACKGROUNDED.isEmpty)
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_CRASHED.isEmpty)
        XCTAssertFalse(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED.isEmpty)
        XCTAssertFalse(Constants.EVENT_DEEP_LINK_OPENED.isEmpty)
    }

    func testUserAttributes() {
        XCTAssertEqual(UserAttributes.UID, "uid")
        XCTAssertEqual(UserAttributes.ANONYMOUS_UID, "anonymousUid")
        XCTAssertEqual(UserAttributes.EMAIL, "email")
        XCTAssertEqual(UserAttributes.PHONE, "phone")
        XCTAssertEqual(UserAttributes.NAME, "name")
        XCTAssertEqual(UserAttributes.FIRST_NAME, "firstName")
        XCTAssertEqual(UserAttributes.LAST_NAME, "lastName")
    }
}
