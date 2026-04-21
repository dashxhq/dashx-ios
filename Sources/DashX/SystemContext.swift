import AdSupport
// @_implementationOnly — see DashXClient.swift for rationale.
@_implementationOnly import Apollo
import AppTrackingTransparency
import Foundation
import UIKit

struct SystemContextEnvironment {
    let locale: Locale
    let timeZone: TimeZone
    let bundle: Bundle
    let device: UIDevice
    let advertisingMonitor: AdvertisingMonitor
    let networkMonitor: NetworkMonitor
    let screen: UIScreen

    static let live = Self(
        locale: Locale.current,
        timeZone: TimeZone.current,
        bundle: Bundle.main,
        device: UIDevice.current,
        advertisingMonitor: AdvertisingMonitor.shared,
        networkMonitor: NetworkMonitor.shared,
        screen: readScreen()
    )

    /// Read whichever `UIScreen` is most relevant right now. Callable from
    /// any thread — the `UIApplication.connectedScenes` / `UIScreen.screens`
    /// accessors are documented as main-thread-only but their backing state
    /// is effectively immutable snapshots for the width/height/scale values
    /// we care about, and reading them off-main has been stable in practice.
    ///
    /// The previous implementation gated off-main calls through
    /// `DispatchQueue.main.sync { ... }`, which **deadlocked** on
    /// cold-launch notification delivery: `configure()` dispatches
    /// `EventQueue.shared.flush()` to a background serial queue, that
    /// queue became the first thread to touch `SystemContext.shared`,
    /// grabbed the `.live` static-init lock, and then `main.sync`'d for
    /// the screen — while the main thread, delivering the tapped
    /// notification via `userNotificationCenter(_:didReceive:)`, blocked
    /// on the same static-init lock trying to `track(...)` the delivery.
    /// See the 1.4.1 changelog for the full chain.
    private static func readScreen() -> UIScreen {
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.screen
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen
        }
        return UIScreen.screens[0]
    }
}

public struct LibraryInfo {
    public let name: String
    public let version: String

    public init(
        name: String,
        version: String
    ) {
        self.name = name
        self.version = version
    }
}

class SystemContext: NSObject {
    static var shared: SystemContext = .init()
    private let environment: SystemContextEnvironment

    private var libraryInfo: LibraryInfo? = nil

    init(environment: SystemContextEnvironment = .live) {
        self.environment = environment

        super.init()
    }

    func setLibraryInfo(libraryInfo: LibraryInfo) {
        self.libraryInfo = libraryInfo
    }

    func getSystemContextInput() -> DashXGql.SystemContextInput? {
        let ipAddresses = getIPAddress()
        if let ipV4 = ipAddresses.ipV4,
           let locale = environment.locale.regionCode
        {
            let ipV6 = ipAddresses.ipV6

            return DashXGql.SystemContextInput(
                ipV4: ipV4,
                ipV6: ipV6.map { .some($0) } ?? .null,
                locale: locale,
                timeZone: environment.timeZone.identifier,
                userAgent: userAgentString(),
                app: getSystemContextAppInput().map { .some($0) } ?? .null,
                device: getSystemContextDeviceInput().map { .some($0) } ?? .null,
                os: .some(getSystemContextOsInput()),
                library: .some(getSystemContextLibraryInput()),
                network: getSystemContextNetworkInput().map { .some($0) } ?? .null,
                screen: .some(getSystemContextScreenInput()),
                campaign: .null,
                location: .null
            )
        }
        return nil
    }

    func getSystemContextAppInput() -> DashXGql.SystemContextAppInput? {
        if let bundleName = environment.bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           let bundleVersion = environment.bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
           let bundleShortVersion = environment.bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let namespace = environment.bundle.bundleIdentifier
        {
            return DashXGql.SystemContextAppInput(
                name: bundleName,
                version: bundleShortVersion,
                build: bundleVersion,
                namespace: namespace
            )
        }
        return nil
    }

    func getSystemContextDeviceInput() -> DashXGql.SystemContextDeviceInput? {
        if let id = environment.device.identifierForVendor?.uuidString {
            return DashXGql.SystemContextDeviceInput(
                id: id,
                advertisingId: environment.advertisingMonitor.advertisingId,
                adTrackingEnabled: environment.advertisingMonitor.adTrackingEnabled,
                manufacturer: "Apple",
                model: environment.device.model,
                name: environment.device.name,
                kind: environment.device.systemName
            )
        }
        return nil
    }

    func getSystemContextOsInput() -> DashXGql.SystemContextOsInput {
        return DashXGql.SystemContextOsInput(name: environment.device.systemName, version: environment.device.systemVersion)
    }

    func getSystemContextLibraryInput() -> DashXGql.SystemContextLibraryInput {
        if let libraryInfo = libraryInfo {
            return DashXGql.SystemContextLibraryInput(name: libraryInfo.name, version: libraryInfo.version)
        }
        return DashXGql.SystemContextLibraryInput(name: Constants.LIBRARY_NAME, version: Constants.PACKAGE_VERSION)
    }

    func getSystemContextNetworkInput() -> DashXGql.SystemContextNetworkInput? {
        // networkInfo.serviceSubscriberCellularProviders?.first?.value.carrierName
        // CTCarrier is 'Deprecated with no replacement' - https://developer.apple.com/documentation/coretelephony/ctcarrier
        let carrierName = "--"

        let connection = environment.networkMonitor.connection

        var cellular = false
        var wifi = false
        var bluetooth = false

        switch connection {
        case .online(.cellular):
            cellular = true
        case .online(.wifi):
            wifi = true
        case .online(.bluetooth):
            bluetooth = true
        default:
            break
        }

        return DashXGql.SystemContextNetworkInput(
            bluetooth: bluetooth, // TODO: Get this status WITHOUT using CoreBluetooth
            carrier: carrierName,
            cellular: cellular,
            wifi: wifi
        )
    }

    func getSystemContextScreenInput() -> DashXGql.SystemContextScreenInput {
        return DashXGql.SystemContextScreenInput(
            width: Int(environment.screen.bounds.width),
            height: Int(environment.screen.bounds.height),
            density: Int(environment.screen.scale)
        )
    }
}
