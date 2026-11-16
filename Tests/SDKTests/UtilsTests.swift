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

    // Wire contract: customers' dashboards and the public docs depend on these names.
    func testInternalEventNames() {
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_INSTALLED, "Application Installed")
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_UPDATED, "Application Updated")
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_OPENED, "Application Opened")
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_BACKGROUNDED, "Application Backgrounded")
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_CRASHED, "Application Crashed")
        XCTAssertEqual(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, "$screen")
        XCTAssertEqual(Constants.EVENT_DEEP_LINK_OPENED, "Deep Link Opened")
        XCTAssertEqual(Constants.EVENT_NOTIFICATION_NAVIGATED, "Push Notification Tapped")
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

final class DashXLogTests: XCTestCase {
    override func tearDown() {
        DashXLog.setLogLevel(to: .off)
        super.tearDown()
    }

    func testMessagesBelowTheLogLevelAreNeverBuilt() {
        var built = 0
        func message() -> String {
            built += 1
            return "message"
        }

        DashXLog.setLogLevel(to: .error)
        DashXLog.d(tag: "test", message())
        DashXLog.i(tag: "test", message())
        XCTAssertEqual(built, 0)

        DashXLog.e(tag: "test", message())
        XCTAssertEqual(built, 1)
    }

    // MARK: - ipAddresses

    /// A `getifaddrs`-style list built by hand, freed after [body] runs.
    private func withInterfaces(
        _ entries: [(name: String, address: UnsafeMutablePointer<sockaddr>?)],
        _ body: (UnsafeMutablePointer<ifaddrs>) -> Void
    ) {
        var next: UnsafeMutablePointer<ifaddrs>?
        var nodes: [UnsafeMutablePointer<ifaddrs>] = []
        for entry in entries.reversed() {
            let node = UnsafeMutablePointer<ifaddrs>.allocate(capacity: 1)
            node.initialize(to: ifaddrs())
            node.pointee.ifa_name = strdup(entry.name)
            node.pointee.ifa_addr = entry.address
            node.pointee.ifa_next = next
            next = node
            nodes.append(node)
        }
        defer {
            for node in nodes {
                free(node.pointee.ifa_name)
                if let address = node.pointee.ifa_addr { address.deallocate() }
                node.deallocate()
            }
        }
        body(next!)
    }

    private func ipv4Address(_ text: String) -> UnsafeMutablePointer<sockaddr> {
        let address = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
        address.initialize(to: sockaddr_in())
        address.pointee.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.pointee.sin_family = sa_family_t(AF_INET)
        inet_pton(AF_INET, text, &address.pointee.sin_addr)
        return UnsafeMutableRawPointer(address).bindMemory(to: sockaddr.self, capacity: 1)
    }

    private func linkLayerAddress() -> UnsafeMutablePointer<sockaddr> {
        let address = UnsafeMutablePointer<sockaddr>.allocate(capacity: 1)
        address.initialize(to: sockaddr())
        address.pointee.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        address.pointee.sa_family = sa_family_t(AF_LINK)
        return address
    }

    func testIpAddressesSkipsAnInterfaceWithANullAddress() {
        withInterfaces([("en0", nil), ("en0", ipv4Address("192.0.2.10"))]) { first in
            XCTAssertEqual(ipAddresses(from: first).ipV4, "192.0.2.10")
        }
    }

    func testIpAddressesIgnoresNonIPFamiliesAndOtherInterfaces() {
        withInterfaces([
            ("en0", linkLayerAddress()),
            ("lo0", ipv4Address("127.0.0.1")),
            ("pdp_ip0", ipv4Address("198.51.100.7")),
        ]) { first in
            let addresses = ipAddresses(from: first)
            XCTAssertEqual(addresses.ipV4, "198.51.100.7")
            XCTAssertNil(addresses.ipV6)
        }
    }
}
