import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit

@objc(DashXAppDelegate)
open class DashXAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // MARK: Getters

    private var app: UIApplication = .shared

    private var dashXClient = DashXClient.instance

    // MARK: Init

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self

        // Register to ensure device token can be fetched
        app.registerForRemoteNotifications()
    }

    // MARK: - APNS Token Management

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DashXLog.d(tag: #function, "Unable to register for remote notifications: \(error.localizedDescription)")
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        dashXClient.setAPNSToken(to: deviceToken)
    }

    // MARK: - Push Notifications

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let message = notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)
        
        dashXClient.trackNotification(message: message, event: .delivered)
        
        let presentationOptions = notificationDeliveredInForeground(message: message)

        completionHandler(presentationOptions)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let message = response.notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)
        
        dashXClient.trackNotification(message: message, event: .clicked)
        
        notificationClicked(message: message)
        completionHandler()
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(userInfo)

        guard case let stringData as String = userInfo[Constants.DASHX_NOTIFICATION_DATA_KEY] else {
            // Do not handle non-DashX notifications
            completionHandler(.failed)
            return
        }

        if let jsonData = stringData.data(using: .utf8) {
            do {
                let dashxData = try JSONDecoder().decode(DashXNotificationData.self, from: jsonData)

                let notificationContent = UNMutableNotificationContent()
                notificationContent.sound = UNNotificationSound.default
                notificationContent.title = dashxData.title
                notificationContent.body = dashxData.body
                notificationContent.userInfo = userInfo

                let request = UNNotificationRequest(identifier: dashxData.id, content: notificationContent, trigger: nil)

                UNUserNotificationCenter.current().add(request)
            } catch {
                DashXLog.d(tag: #function, "Unable to parse DashX notification data \(error)")
            }
        }

        completionHandler(.newData)
    }

    // MARK: - Push Notifications handlers

    open func notificationDeliveredInForeground(message: [AnyHashable: Any]) -> UNNotificationPresentationOptions { return [] }

    open func notificationClicked(message: [AnyHashable: Any]) {}
}
