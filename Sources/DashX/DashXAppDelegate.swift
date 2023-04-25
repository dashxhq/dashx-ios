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
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
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

        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            dashXClient.trackNotification(message: message, event: .dismissed)
            return
        }

        dashXClient.trackNotification(message: message, event: .clicked)

        notificationClicked(message: message)
        completionHandler()
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(userInfo)

        guard let dashxData = userInfo.dashxNotificationData() else {
            DashXLog.d(tag: #function, "Unable to parse DashX notification data")
            completionHandler(.failed)
            return
        }

        let notificationContent = UNMutableNotificationContent()
        notificationContent.sound = UNNotificationSound.default
        notificationContent.title = dashxData.title
        notificationContent.body = dashxData.body
        notificationContent.userInfo = userInfo
        notificationContent.categoryIdentifier = Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER

        let notificationCategories = UNNotificationCategory(
            identifier: Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([notificationCategories])

        if let imagePath = dashxData.image,
           let imageURL = URL(string: imagePath)
        {
            createNotificationWithImage(id: dashxData.id, imageURL: imageURL, content: notificationContent)
        } else {
            createNotification(id: dashxData.id, content: notificationContent)
        }

        completionHandler(.newData)
    }

    // MARK: - Push Notifications handlers

    open func notificationDeliveredInForeground(message: [AnyHashable: Any]) -> UNNotificationPresentationOptions { return [] }

    open func notificationClicked(message: [AnyHashable: Any]) {}

    open func handleLink(url: URL) {}
}

extension DashXAppDelegate {
    private func createNotification(id: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DashXLog.d(tag: #function, "Failed to schedule notification request: \(error.localizedDescription)")
            } else {
                DashXLog.d(tag: #function, "Notification request added successfully.")
            }
        }
    }

    private func createNotificationWithImage(id: String,
                                             imageURL: URL,
                                             content: UNMutableNotificationContent)
    {
        let task = URLSession.shared.downloadTask(with: imageURL) { location, _, error in
            guard let location = location, error == nil else {
                return
            }

            // Create a temporary file URL to save the downloaded image
            let tmpDirectoryURL = FileManager.default.temporaryDirectory
            let uuid = UUID().uuidString
            let tmpFileURL = tmpDirectoryURL.appendingPathComponent(uuid + ".png")

            do {
                // Move the downloaded file to the temporary file URL
                try FileManager.default.moveItem(at: location, to: tmpFileURL)

                // Create the notification attachment from the temporary file URL
                let attachment = try UNNotificationAttachment(identifier: "\(id)-attachment", url: tmpFileURL, options: nil)
                content.attachments = [attachment]
                self.createNotification(id: id, content: content)
            } catch {
                DashXLog.d(tag: #function, "Error moving file: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
