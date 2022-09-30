//
//  LocationMonitor.swift
//  textfield
//
//  Created by Aditya Kumar Bodapati on 21/09/22.
//
import Foundation
import CoreLocation

class LocationMonitor: NSObject {
    static var shared = LocationMonitor()
    
    var locationManager: CLLocationManager!
    var city: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?
    var speed: Double?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    func startMonitoring() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationMonitor: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        var authStatus = CLAuthorizationStatus.notDetermined
        if #available(iOS 14.0, *) {
            authStatus = manager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }
        switch authStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()
            break
        case .denied:
            stopMonitoring()
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            speed = location.speed
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard error == nil else { return }
                if let placemarks = placemarks, let placemark = placemarks.first {
                    self?.city = placemark.name
                    self?.country = placemark.country
                }
            }
        }
    }
}
