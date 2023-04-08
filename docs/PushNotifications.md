# **Push Notifications**

The easiest way to support push notifications in your app.

&emsp;

# Features
| Feature | Description |
| --- | --- |
| Push notification registration | The SDK allows for easy management of push notification device tokens, including registration with Apple Push Notification Service (APNS). |
| Handling incoming push notifications | The SDK provides a simple interface for handling incoming push notifications, including displaying a banner or alert to the user, and providing the notification payload to the app for further processing. |
| Customizable notification presentation | Developers can customize the presentation of push notifications to match the look and feel of their app, including the banner or alert style, sound, and vibration settings. |
| Silent push notifications | The SDK supports silent push notifications, which can wake up the app in the background to perform tasks or fetch new content, without displaying a visible notification to the user. |
| Push notification analytics | The SDK includes built-in analytics to track push notification engagement, including the number of notifications sent, opened, and clicked. |
| Rich media push notifications | The SDK supports rich media push notifications, allowing developers to include images, videos, and other interactive content in their push notifications. |
| Scheduled push notifications | Developers can schedule push notifications to be sent at a specific time or on a recurring basis, such as daily or weekly. |
| Segmented push notifications | The SDK supports segmented push notifications, allowing developers to target specific groups of users based on demographic or behavioral criteria. |

&emsp;

# Requirements

| Requirement | Reason |
| --- | --- |
| [Apple Developer Membership](https://developer.apple.com/account/) | Apple requires all iOS developers to have a membership so you can manage your push notification certificates. |
| A phyical iOS device | Although you can setup the DashX SDK without a device, a physical device is the only way to full ensure push notification tokens and notification delivery is working correctly. Simulators are not reliable. |
| A Configured Integration | DashX needs to know who to route the push notifications to so your users can receive them. |

&emsp;

# Setup

## 1. Setup a Push Notification Integration

Select which push notification integration you would like DashX to route push notifications to.

| Provider                                                      | Token Syncing   | Supported |
|---------------------------------------------------------------|----------------|-----------|
| APNS - Apple Push Notification Service      | Automatic      |     ✅     |
| FCM - Firebase Cloud Messaging     | Automatic |     ✅     |

## 2. Enable the "Push Notifications" capability

1. Select your Xcode project file
2. Click your project Target
3. Click "Signing & Capabilities"
4. Click the small "+" to add a capability
5. Select `Push Notifications` from the list of capabilities
6. Press Enter

## 3. Implement the `DashXAppDelegate`

```swift
import DashX

@main
class AppDelegate: DashXAppDelegate {

    ...

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DashX.configure(
            withPublicKey: '...',
        )

        // Initialize Firebase and FCM
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // Request permission for push notifications and handle the resulting authorization status
        DashX.requestNotificationPermission { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                // User has granted permission for push notifications
            case .denied:
                // User has denied permission for push notifications
            case .notDetermined:
                // User has not yet made a choice about push notifications
            case .provisional:
                // User has granted provisional permission for push notifications (iOS 12+)
            @unknown default:
                // Handle any future authorization status not accounted for in the switch statement
            }
        }

        return true
    }

    override func notificationDeliveredInForeground(message: [AnyHashable: Any]) -> UNNotificationPresentationOptions {
        print("\n=== Notification Delivered In Foreground ===\n")
        print(message)
        print("\n=================================================\n")

        // This is how you want to show your notification in the foreground
        // You can pass "[]" to not show the notification to the user or
        // handle this with your own custom styles
        return [.sound, .alert, .badge]
    }

    override func notificationClicked(message: [AnyHashable: Any]) {
        print("\n=== Notification Clicked ===\n")
        print(message)
        print("\n=================================\n")
    }
}
```

1. In your `AppDelegate`, add `import DashX`
2. Change your `AppDelegate` to extend the `DashXAppDelegate`
    * This adds simple functions to handle push notification delivery and clicks
    * This automatically requests for a registration token
