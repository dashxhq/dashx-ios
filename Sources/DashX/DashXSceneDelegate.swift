//
//  DashXSceneDelegate.swift
//  DashX
//
//  Created by Amandeep on 17/05/23.
//

import AppTrackingTransparency
import Foundation
import UIKit

@objc(DashXSceneDelegate)
open class DashXSceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var advertisingMonitor = AdvertisingMonitor.shared

    open func sceneDidBecomeActive(_ scene: UIScene) {
        advertisingMonitor.requestAdTrackingPermission()
    }
}
