//
//  LocationMonitor.swift
//  textfield
//
//  Created by Aditya Kumar Bodapati on 21/09/22.
//
import CoreLocation
import Foundation

class LocationMonitor: NSObject {
    static let shared = LocationMonitor()

    private var locationManager: CLLocationManager!
    private var latitude: Double?
    private var longitude: Double?
    private var speed: Double?

    public var getLatitude: Double? {
        return latitude
    }

    public var getLongitude: Double? {
        return longitude
    }

    public var getSpeed: Double? {
        return speed
    }

    private var authStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
    }

    public func prepareLocationInfo() {
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            setLocationInfo()
        case .restricted, .denied:
            clearLocationInfo()
        default:
            break
        }
    }

    private func setLocationInfo() {
        latitude = locationManager.location?.coordinate.latitude
        longitude = locationManager.location?.coordinate.longitude
        speed = locationManager.location?.speed
    }

    private func clearLocationInfo() {
        (latitude, longitude, speed) = (nil, nil, nil)
    }
}
