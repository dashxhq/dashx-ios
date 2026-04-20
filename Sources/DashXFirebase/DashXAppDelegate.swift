import DashX
import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

@objc(DashXAppDelegate)
open class DashXAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // MARK: Getters

    private var app: UIApplication = .shared

    private var dashXClient: DashXClient { DashXClient.instance }

    // MARK: Init

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self

        dashXClient.linkHandler = { [weak self] url in
            self?.handleLink(url: url)
        }

        app.registerForRemoteNotifications()

        registerDefaultDashXCategory()
    }

    /// Registers a no-actions fallback category at launch so alert pushes that reference
    /// `DASHX_NOTIFICATION_CATEGORY_IDENTIFIER` resolve even when the app was killed
    /// and no previous push has dynamically registered action buttons.
    private func registerDefaultDashXCategory() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories { existing in
            if existing.contains(where: { $0.identifier == Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER }) {
                return
            }
            let category = UNNotificationCategory(
                identifier: Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER,
                actions: [],
                intentIdentifiers: [],
                options: .customDismissAction
            )
            var merged = existing
            merged.insert(category)
            center.setNotificationCategories(merged)
        }
    }

    // MARK: - APNS Token Management

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DashXLog.e(tag: #function, "Unable to register for remote notifications: \(error.localizedDescription)")
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        dashXClient.setAPNSToken(to: deviceToken)
        // Force the APNs environment instead of `.unknown` — auto-detection
        // occasionally mis-tags dev-signed builds as production, producing
        // an FCM token whose pushes silently 410 at APNs.
        #if DEBUG
        Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        #endif
    }

    // MARK: - Push Notifications

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let message = notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)

        dashXClient.trackMessage(message: message, event: .delivered)

        registerDashXNotificationCategoryIfNeeded(from: message)

        let presentationOptions = notificationDeliveredInForeground(message: message)

        completionHandler(presentationOptions)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let message = response.notification.request.content.userInfo

        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(message)

        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            dashXClient.trackMessage(message: message, event: .dismissed)
        } else {
            dashXClient.trackMessage(message: message, event: .clicked)

            let dashxData = message.dashxNotificationData()
            let navigationAction = dashxData?.navigationAction(forActionIdentifier: response.actionIdentifier)

            dashXClient.trackNotificationNavigation(navigationAction, notificationId: dashxData?.id)

            if onNotificationClicked(message: message, action: navigationAction, actionIdentifier: response.actionIdentifier) {
                completionHandler()
                return
            }

            applyDefaultNotificationClickHandling(
                message: message,
                navigationAction: navigationAction,
                actionIdentifier: response.actionIdentifier
            )
        }

        completionHandler()
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Pass notification reciept information to Firebase
        Messaging.messaging().appDidReceiveMessage(userInfo)

        // Alert pushes (aps.alert present) are displayed by iOS directly; a Notification
        // Service Extension handles image attachment and delivered tracking. Skipping the
        // legacy silent-push reconstruction here prevents a duplicate banner.
        if let aps = userInfo["aps"] as? [AnyHashable: Any], aps["alert"] != nil {
            completionHandler(.newData)
            return
        }

        guard let dashxData = userInfo.dashxNotificationData() else {
            DashXLog.e(tag: #function, "Unable to parse DashX notification data")
            completionHandler(.failed)
            return
        }

        let notificationContent = UNMutableNotificationContent()
        notificationContent.sound = UNNotificationSound.default
        notificationContent.title = dashxData.title
        notificationContent.body = dashxData.body
        notificationContent.userInfo = userInfo
        notificationContent.categoryIdentifier = Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER

        if #available(iOS 15.0, *), let level = dashxData.interruptionLevel {
            switch level {
            case "passive":
                notificationContent.interruptionLevel = .passive
            case "active":
                notificationContent.interruptionLevel = .active
            case "timeSensitive":
                notificationContent.interruptionLevel = .timeSensitive
            case "critical":
                notificationContent.interruptionLevel = .critical
            default:
                break
            }
        }

        registerDashXNotificationCategoryIfNeeded(from: userInfo)

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

    /// Return `true` to handle navigation yourself and skip the SDK default behavior (``handleLink(url:)`` and the deprecated ``notificationClicked(message:actionIdentifier:)`` hook).
    open func onNotificationClicked(message: [AnyHashable: Any], action: NavigationAction?, actionIdentifier: String) -> Bool {
        false
    }

    @available(*, deprecated, message: "Use onNotificationClicked(message:action:actionIdentifier:) instead.")
    open func notificationClicked(message: [AnyHashable: Any], actionIdentifier: String) {}

    /// Default behaviour: hands the URL to iOS via `UIApplication.shared.open(_:)`.
    /// - `http` / `https` URLs open in Safari (or a universal-link handler registered
    ///   for the domain — Apple routes that automatically).
    /// - Custom schemes registered by the current app are routed back through the
    ///   scene delegate's `openURLContexts:`, which means `DashXSceneDelegate` (if
    ///   subclassed) picks them up and the app's own URL handling runs.
    /// - Other custom schemes route to whichever app is registered for them.
    ///
    /// Override to route URLs inside the app (push a screen, open a tab, etc.) —
    /// don't call `super` if you want to fully intercept. To keep the default
    /// OS-level open behaviour and also do your own work, call `super.handleLink(url:)`
    /// after your handling.
    open func handleLink(url: URL) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func applyDefaultNotificationClickHandling(
        message: [AnyHashable: Any],
        navigationAction: NavigationAction?,
        actionIdentifier: String
    ) {
        if let navigationAction {
            switch navigationAction {
            case let .deepLink(url):
                dashXClient.processURL(url, source: "notification")
            case let .richLanding(url):
                dashXClient.processURL(url, source: "notification", forwardToLinkHandler: false)
                DashXBrowser.presentRichLanding(url: url)
            case .screen, .clickAction:
                notificationClicked(message: message, actionIdentifier: actionIdentifier)
            }
            return
        }

        if actionIdentifier != UNNotificationDefaultActionIdentifier {
            notificationClicked(message: message, actionIdentifier: actionIdentifier)
            return
        }

        if let url = message.dashxNotificationUrl() {
            dashXClient.processURL(url, source: "notification")
        } else {
            notificationClicked(message: message, actionIdentifier: actionIdentifier)
        }
    }

    /// Registers a ``UNNotificationCategory`` with ``ActionButton`` actions so taps resolve per-button URLs / screen data.
    private func registerDashXNotificationCategoryIfNeeded(from message: [AnyHashable: Any]) {
        guard let dashxData = message.dashxNotificationData() else {
            return
        }

        var notificationActions: [UNNotificationAction] = []

        if let actionButtons = dashxData.actionButtons {
            for button in actionButtons {
                notificationActions.append(
                    UNNotificationAction(
                        identifier: button.identifier,
                        title: button.label,
                        options: [.foreground]
                    )
                )
            }
        }

        let notificationCategory = UNNotificationCategory(
            identifier: Constants.DASHX_NOTIFICATION_CATEGORY_IDENTIFIER,
            actions: notificationActions,
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
    }
}

extension DashXAppDelegate {
    private func createNotification(id: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DashXLog.e(tag: #function, "Failed to schedule notification request: \(error.localizedDescription)")
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
                DashXLog.e(tag: #function, "Error moving file: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
