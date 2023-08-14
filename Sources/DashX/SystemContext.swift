import AdSupport
import AppTrackingTransparency
import Foundation
import Network
import SystemConfiguration
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
        screen: UIScreen.main
    )
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
                ipV6: ipV6,
                locale: locale,
                timeZone: environment.timeZone.identifier,
                userAgent: userAgentString(),
                app: getSystemContextAppInput(),
                device: getSystemContextDeviceInput(),
                os: getSystemContextOsInput(),
                library: getSystemContextLibraryInput(),
                network: getSystemContextNetworkInput(),
                screen: getSystemContextScreenInput(),
                campaign: nil,
                location: nil
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
        return DashXGql.SystemContextLibraryInput(name: Constants.PACKAGE_NAME, version: Constants.PACKAGE_VERSION)
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
