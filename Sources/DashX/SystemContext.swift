import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import CoreBluetooth
import CoreTelephony
import Network

class SystemContext {
    
    struct AppContext {
        let name: String?
        let version: String?
        let build: String?
        let namespace: String?
        
        init(
            name: String? = nil,
            version: String? = nil,
            build: String? = nil,
            namespace: String? = nil
        ) {
            self.name = name
            self.version = version
            self.build = build
            self.namespace = namespace
        }
    }
    var app: AppContext?
    
    struct DeviceContext {
            let id: String?
            let advertisingId: String?
            let adTrackingEnabled: Bool?
            let manufacturer: String?
            let model: String?
            let name: String?
            let kind: String?
            let token: String?
        
        init(
            id: String? = nil,
            advertisingId: String? = nil,
            adTrackingEnabled: Bool? = nil,
            manufacturer: String? = "Apple",
            model: String? = nil,
            name: String? = nil,
            kind: String? = nil,
            token: String? = nil
        ) {
            self.id = id
            self.advertisingId = advertisingId
            self.adTrackingEnabled = adTrackingEnabled
            self.manufacturer = manufacturer
            self.model = model
            self.name = name
            self.kind = kind
            self.token = token
        }
    }
    var device: DeviceContext?
    
    struct OSContext {
        let name: String?
        let version: String?
        
        init(
            name: String? = nil,
            version: String? = nil
        ) {
            self.name = name
            self.version = version
        }
    }
    var os: OSContext?
    
    struct LibraryContext {
        let name: String?
        let version: String?
        
        init(
            name: String? = nil,
            version: String? = nil
        ) {
            self.name = name
            self.version = version
        }
    }
    var library: LibraryContext?
    
    struct NetworkContext {
        let bluetooth: Bool?
        let carrier: String?
        let cellular: Bool?
        let wifi: Bool?
        
        init(
            bluetooth: Bool? = nil,
            carrier: String? = nil,
            cellular: Bool? = nil,
            wifi: Bool? = nil
        ) {
            self.bluetooth = bluetooth
            self.carrier = carrier
            self.cellular = cellular
            self.wifi = wifi
        }
    }
    var network: NetworkContext?
    
    struct ScreenContext {
        let width: Double?
        let height: Double?
        let density: Double?
        
        init(
            width: Double? = nil,
            height: Double? = nil,
            density: Double? = nil
        ) {
            self.width = width
            self.height = height
            self.density = density
        }
    }
    var screen: ScreenContext?
    
    struct LocationContext {
        let city: String?
        let country: String?
        let latitude: Double?
        let longitude: Double?
        let speed: Double?
        
        init(
            city: String? = nil,
            country: String? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil,
            speed: Double? = nil
        ) {
            self.city = city
            self.country = country
            self.latitude = latitude
            self.longitude = longitude
            self.speed = speed
        }
    }
    var location: LocationContext?
    
    var ip: String?
    var locale: String?
    var timeZone: String?
    
    init() {
        setAppContext(bundle: Bundle.main)
        setDeviceContext(device: UIDevice.current, advertisingManager: ASIdentifierManager.shared())
        setOSContext(device: UIDevice.current)
        setLibraryContext()
        setNetworkContext(cbCentralManager: CBCentralManager(), networkMonitor: NetworkMonitor.shared)
        setScreenContext(screen: UIScreen.main)
        setLocationContext()
        
        self.ip = ""//FIXME: Get IP address
        self.locale = Locale.current.regionCode
        self.timeZone = TimeZone.current.identifier
    }
    
    func setAppContext(bundle: Bundle) {
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let bundleVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let bundleShortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        self.app = AppContext(
            name: bundleName,
            version: bundleShortVersion,
            build: bundleVersion,
            namespace: bundle.bundleIdentifier
        )
    }
    
    func setDeviceContext(device: UIDevice, advertisingManager: ASIdentifierManager) {
        var isAdTrackingEnabled = false
        if #available(iOS 14, *) {
            isAdTrackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            isAdTrackingEnabled = advertisingManager.isAdvertisingTrackingEnabled
        }
        self.device = DeviceContext(
            id: device.identifierForVendor?.uuidString,
            advertisingId: advertisingManager.advertisingIdentifier.uuidString,
            adTrackingEnabled: isAdTrackingEnabled,
            manufacturer: "Apple",
            model: device.model,
            name: device.name,
            kind: "ios",
            token: "" //FIXME: Find out what is the token here
        )
    }
    
    func setOSContext(device: UIDevice) {
        self.os = OSContext(
            name: device.systemName,
            version: device.systemVersion
        )
    }
    
    func setLibraryContext() {
        self.library = LibraryContext(
            name: Constants.PACKAGE_NAME,
            version: Constants.PACKAGE_VERSION
        )
    }
    
    func setNetworkContext(cbCentralManager: CBCentralManager, networkMonitor: NetworkMonitor) {
        let bluetoothStatus = cbCentralManager.state == .poweredOn
        let networkInfo = CTTelephonyNetworkInfo()
        let carrierName = networkInfo.serviceSubscriberCellularProviders?.first?.value.carrierName
        let cellularReachabilityStatus = networkMonitor.isReachableOnCellular
        let wifiReachabilityStatus = networkMonitor.isReachableOnWifi
        
        self.network = NetworkContext(
            bluetooth: bluetoothStatus,
            carrier: carrierName,
            cellular: cellularReachabilityStatus,
            wifi: wifiReachabilityStatus
        )
    }
    
    func setScreenContext(screen: UIScreen) {
        self.screen = ScreenContext(
            width: screen.bounds.width,
            height: screen.bounds.height,
            density: screen.scale
        )
    }
    
    func setLocationContext() {
    }
}

extension SystemContext.AppContext: Encodable { }
extension SystemContext.DeviceContext: Encodable { }
extension SystemContext.OSContext: Encodable { }
extension SystemContext.LibraryContext: Encodable { }
extension SystemContext.NetworkContext: Encodable { }
extension SystemContext.ScreenContext: Encodable { }
extension SystemContext.LocationContext: Encodable { }

extension SystemContext: Encodable {
    func getSystemContext() throws -> [String: Any] {
        let jsonEncoder = JSONEncoder()
        let data = try jsonEncoder.encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return dictionary ?? [:]
    }
    // Not needed atleast for now
    enum CodingKeys: CodingKey { } // Declare raw type --> String
}
