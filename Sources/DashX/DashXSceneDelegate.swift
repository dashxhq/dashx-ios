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

    @available(iOS 13.0, *)
    open func sceneDidBecomeActive(_ scene: UIScene) {
        advertisingMonitor.requestAdTrackingPermission()
    }

    /// Forwards custom URL schemes and app-specific URLs opened via the scene through ``DashXClient/processURL(_:source:forwardToLinkHandler:)``.
    @available(iOS 13.0, *)
    open func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            DashXClient.instance.processURL(context.url, source: "scene_url")
        }
    }

    /// Forwards universal links (`NSUserActivityTypeBrowsingWeb`) to `DashXClient.handleUserActivity`.
    @available(iOS 13.0, *)
    open func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        DashXClient.instance.handleUserActivity(userActivity: userActivity)
    }
}
