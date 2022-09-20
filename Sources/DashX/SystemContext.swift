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
    let locationManager: CLLocationManager
    
    static let live = Self(
        locale: Locale.current,
        timeZone: TimeZone.current,
        bundle: Bundle.main,
        device: UIDevice.current,
        advertisingManager: ASIdentifierManager.shared(),
        cbCentralManager: CBCentralManager.shared,
        networkMonitor: NetworkMonitor.shared,
        screen: UIScreen.main,
        locationManager: CLLocationManager.shared
    )
}

extension CBCentralManager {
    static var shared: CBCentralManager {
        return CBCentralManager()
    }
}

extension CLLocationManager {
    static var shared: CLLocationManager {
        return CLLocationManager()
    }
}

class SystemContext: NSObject {
    static var shared: SystemContext = SystemContext()
    private let environment: SystemContextEnvironment
    
    init(environment: SystemContextEnvironment = .live) {
        self.environment = environment
        
        super.init()
        setupLocationManager()
        setupCBCentralManager()
    }
    
    func setupLocationManager() {
        environment.locationManager.delegate = self
        environment.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        environment.locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        environment.locationManager.startUpdatingLocation()
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
                app: nil,
                device: nil,
                os: nil,
                library: nil,
                network: nil,
                screen: nil,
                campaign: nil,
                location: nil
            )
        }
        return nil
    }
}

extension SystemContext: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) { }
}

extension SystemContext: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        var authStatus = CLAuthorizationStatus.notDetermined
        if #available(iOS 14.0, *) {
            authStatus = manager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }
        switch authStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            environment.locationManager.startUpdatingLocation()
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
}
