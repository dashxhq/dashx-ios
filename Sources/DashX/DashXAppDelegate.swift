import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit

@objc(DashXAppDelegate)
open class DashXAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
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

    // MARK: - Device Token Management

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DashXLog.d(tag: #function, "Unable to register for remote notifications: \(error.localizedDescription)")
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Firebase Token
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            DashXLog.d(tag: #function, "FCM token is empty")
            return
        }

        DashXLog.d(tag: #function, "FCM token is \(token)")
        dashXClient.setDeviceToken(to: token)
    }

    // MARK: - Push Notifications

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let message = notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)
        
        if let id = dashXClient.getNotificationID(message) {
            dashXClient.trackNotification(id, .delivered, ISO8601DateFormatter.timeStamp)
        }
        
        let presentationOptions = notificationDeliveredInForeground(message: message)

        completionHandler(presentationOptions)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let message = response.notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)
        
        if let id = dashXClient.getNotificationID(message) {
            dashXClient.trackNotification(id, .clicked, ISO8601DateFormatter.timeStamp)
        }
        
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

    // MARK: - Functions

    open func notificationDeliveredInForeground(message: [AnyHashable: Any]) -> UNNotificationPresentationOptions { return [] }

    open func notificationClicked(message: [AnyHashable: Any]) {}
}
