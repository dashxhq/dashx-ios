import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import CoreBluetooth
import CoreTelephony
import Network
import CoreLocation

struct SystemContextEnvironment {
    let locale: Locale
    let timeZone: TimeZone
    let bundle: Bundle
    let device: UIDevice
    let advertisingManager: ASIdentifierManager
    let cbCentralManager: CBCentralManager
    let networkMonitor: NetworkMonitor
    let screen: UIScreen
    let locationMonitor: LocationMonitor

    static let live = Self(
        locale: Locale.current,
        timeZone: TimeZone.current,
        bundle: Bundle.main,
        device: UIDevice.current,
        advertisingManager: ASIdentifierManager.shared(),
        cbCentralManager: CBCentralManager.shared,
        networkMonitor: NetworkMonitor.shared,
        screen: UIScreen.main,
        locationMonitor: LocationMonitor.shared
    )
}

extension CBCentralManager {
    static var shared: CBCentralManager {
        return CBCentralManager()
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
    static var shared: SystemContext = SystemContext()
    private let environment: SystemContextEnvironment

    private var libraryInfo: LibraryInfo? = nil

    init(environment: SystemContextEnvironment = .live) {
        self.environment = environment

        super.init()
        setupCBCentralManager()
    }

    func setLibraryInfo(libraryInfo: LibraryInfo) {
        self.libraryInfo = libraryInfo
    }

    func setupCBCentralManager() {
        environment.cbCentralManager.delegate = self
    }

    func getSystemContextInput() -> DashXGql.SystemContextInput? {
        let ipAddresses = getIPAddress()
        if let ipV4 = ipAddresses.ipV4,
           let locale = environment.locale.regionCode {
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
                location: getSystemContextLocationInput()
            )
        }
        return nil
    }

    func getSystemContextAppInput() -> DashXGql.SystemContextAppInput? {
        if let bundleName = environment.bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           let bundleVersion = environment.bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
           let bundleShortVersion = environment.bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let namespace = environment.bundle.bundleIdentifier {
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
        var isAdTrackingEnabled = false
        if #available(iOS 14, *) {
            isAdTrackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            isAdTrackingEnabled = environment.advertisingManager.isAdvertisingTrackingEnabled
        }

        if let id = environment.device.identifierForVendor?.uuidString {
            return DashXGql.SystemContextDeviceInput(
                id: id,
                advertisingId: environment.advertisingManager.advertisingIdentifier.uuidString,
                adTrackingEnabled: "\(isAdTrackingEnabled)",
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
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrierName = networkInfo.serviceSubscriberCellularProviders?.first?.value.carrierName {
            let cellularReachabilityStatus = environment.networkMonitor.isReachableOnCellular
            let wifiReachabilityStatus = environment.networkMonitor.isReachableOnWifi
            return DashXGql.SystemContextNetworkInput(
                bluetooth: environment.cbCentralManager.state == .poweredOn,
                carrier: carrierName,
                cellular: cellularReachabilityStatus,
                wifi: wifiReachabilityStatus
            )
        }
        return nil
    }

    func getSystemContextScreenInput() -> DashXGql.SystemContextScreenInput {
        return DashXGql.SystemContextScreenInput(
            width: Int(environment.screen.bounds.width),
            height: Int(environment.screen.bounds.height),
            density: Int(environment.screen.scale)
        )
    }

    func getSystemContextLocationInput() -> DashXGql.SystemContextLocationInput? {
        if let city = environment.locationMonitor.city,
            let country = environment.locationMonitor.country,
            let latitude = environment.locationMonitor.latitude,
            let longitude = environment.locationMonitor.longitude,
            let speed = environment.locationMonitor.speed {
            return DashXGql.SystemContextLocationInput(
                city: city,
                country: country,
                latitude: DashXGql.BigDecimal(latitude),
                longitude: DashXGql.BigDecimal(longitude),
                speed: DashXGql.BigDecimal(speed)
            )
        }
        return nil
    }
}

extension SystemContext: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) { }
}
