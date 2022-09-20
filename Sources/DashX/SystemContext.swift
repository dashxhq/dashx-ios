import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import CoreBluetooth
import CoreTelephony
import Network
import CoreLocation

class SystemContext: NSObject {
    static var shared: SystemContext = SystemContext()
    
    var timeZone: TimeZone
    var locale: Locale
    var bundle: Bundle
    var device: UIDevice
    var advertisingManager: ASIdentifierManager
    var cbCentralManager: CBCentralManager
    var networkMonitor: NetworkMonitor
    var screen: UIScreen
    var locationManager: CLLocationManager
    
    override init() {
        self.locale = Locale.current
        self.timeZone = TimeZone.current
        self.bundle = Bundle.main
        self.advertisingManager = ASIdentifierManager.shared()
        self.cbCentralManager = CBCentralManager()
        self.networkMonitor = NetworkMonitor.shared
        self.device = UIDevice.current
        self.screen = UIScreen.main
        self.locationManager = CLLocationManager()
        
        super.init()
        setupLocationManager()
        setupCBCentralManager()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
    }
    
    func setupCBCentralManager() {
        cbCentralManager.delegate = self
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
            locationManager.startUpdatingLocation()
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
}
