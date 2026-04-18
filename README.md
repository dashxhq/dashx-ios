<p align="center">
    <br />
    <a href="https://dashx.com"><img src="https://raw.githubusercontent.com/dashxhq/brand-book/master/assets/logo-black-text-color-icon@2x.png" alt="DashX" height="40" /></a>
    <br />
    <br />
    <strong>Your All-in-One Product Stack</strong>
</p>

<div align="center">
  <h4>
    <a href="https://dashx.com">Website</a>
    <span> | </span>
    <a href="https://docs.dashx.com">Documentation</a>
  </h4>
</div>

<br />

# dashx-ios

_DashX SDK for iOS_

## Install

The minimum supported iOS version is **13.0**. In Xcode, set your app target’s **General** > **Deployment Info** to 13.0 or higher.

### Swift Package Manager

1. In your Xcode project, choose **File** > **Add Package Dependencies…**
2. Enter the repository URL:

```
https://github.com/dashxhq/dashx-ios.git
```

3. Add the **DashX** library to your app target. If you use push notifications / Firebase integration helpers from this SDK, also add **DashXFirebase**.

A [CocoaPods spec](https://github.com/dashxhq/dashx-ios/blob/main/DashX.podspec) publishes the SDK as three subspecs: `DashX/Core` (shared notification models), `DashX/SDK` (default), and `DashX/NotificationServiceExtension`.

## Documentation

For detailed documentation, visit [iOS SDK documentation](https://docs.dashx.com/sdks/client-side/ios-sdk).

## Deep linking and push navigation

See the [Deep Linking & Push Navigation](https://docs.dashx.com/apps/messaging/deep-linking) guide for setup instructions, payload fields, and code examples.

## Notification Service Extension (recommended for push)

DashX 1.3.0+ delivers iOS push notifications as APNs alert pushes instead of the legacy silent-push + local-notification reconstruction pattern. To get image attachments, dynamic action buttons, and reliable delivered-tracking, add a Notification Service Extension target to your app:

1. In Xcode, **File** > **New** > **Target…** > **Notification Service Extension**.
2. Delete the auto-generated `NotificationService.swift`.
3. In your main app target's Package Dependencies, add `DashXNotificationServiceExtension` to the new NSE target (SPM) or add `pod 'DashX/NotificationServiceExtension'` inside the extension target in your Podfile.
4. Create `NotificationService.swift` in the NSE target:

```swift
import DashXNotificationServiceExtension

final class NotificationService: DashXNotificationServiceExtension {}
```

5. Add two keys to the NSE target's `Info.plist` (same values and names as your main app):
   - `DASHX_BASE_URI` — your DashX API base URL
   - `DASHX_PUBLIC_KEY` — your DashX public key

The NSE runs before iOS displays the notification and:
- Downloads and attaches the image from `dashx.image`.
- Registers a `UNNotificationCategory` for `dashx.action_buttons`.
- Fires a `trackNotification(event: delivered)` analytics event — even when your app isn't running.
