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

    // MARK: Device Token Management

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DashXLog.d(tag: #function, "Unable to register for remote notifications: \(error.localizedDescription)")
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // FCM Token
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            DashXLog.d(tag: #function, "FCM token is empty")
            return
        }

        DashXLog.d(tag: #function, "FCM token is \(token)")
        dashXClient.setDeviceToken(to: token)
    }

    // MARK: Push Notifications

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            let alert = UIAlertController(title: "", message: "Alert just at launch", preferredStyle: .alert)
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }

        DashXLog.d(tag: #function, "userInfo is \(userInfo)")
    }

    // Notification Payload is called when in foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DashXLog.d(tag: #function, "notification is \(notification)")
        let message = notification.request.content.userInfo

        let presentationOptions = pushNotificationDeliveredInForeground(message: message)
        completionHandler(presentationOptions)
    }

    // Called after Notification is clicked
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DashXLog.d(tag: #function, "response is \(response)")
        let message = response.notification.request.content.userInfo

        pushNotificationClicked(message: message)
        completionHandler()
    }

    // MARK: Functions

    open func pushNotificationDeliveredInForeground(message: [AnyHashable: Any]) -> UNNotificationPresentationOptions { return [] }

    open func pushNotificationClicked(message: [AnyHashable: Any]) {}

//    // Based on - https://firebase.google.com/docs/cloud-messaging/ios/receive
//    @objc
//    func handleMessage(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        DashXLog.d(tag: #function, "Received APN: \(userInfo)")
//
//        let state = UIApplication.shared.applicationState
//        // Do Nothing when app is in foreground
//        if state == .active {
//            completionHandler(.noData)
//            return
//        }
//
//        if let dashx = userInfo["dashx"] as? String {
//            let maybeDashxDictionary = dashx.convertToDictionary()
//
//            let notificationContent = UNMutableNotificationContent()
//            notificationContent.sound = UNNotificationSound.default
//
//            if let parsedDashxDictionary = maybeDashxDictionary {
//                guard let identifier = parsedDashxDictionary["id"] as? String else {
//                    completionHandler(.newData)
//                    // Do not handle non-DashX notifications
//                    return
//                }
//
//                if let parsedTitle = parsedDashxDictionary["title"] as? String {
//                    notificationContent.title = parsedTitle
//                }
//
//                if let parsedBody = parsedDashxDictionary["body"] as? String {
//                    notificationContent.body = parsedBody
//                }
//
//                let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: nil)
//                let notificationCenter = UNUserNotificationCenter.current()
//                notificationCenter.add(request)
//                // TODO: Finish the implementation
    ////                let data = ["data": userInfo]
//            }
//        }
//
//        completionHandler(.newData)
//    }
}
