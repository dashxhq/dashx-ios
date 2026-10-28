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

## Install (Swift Package Manager)

1. In Xcode: **File** → **Add Package Dependencies…**
2. Enter `https://github.com/dashxhq/dashx-ios.git`
3. Add **DashX** to your app target. For push notifications, add **DashXFirebase** as well, and set up a Notification Service Extension with **DashXNotificationServiceExtension**.

SPM consumers get the same prebuilt XCFrameworks as CocoaPods consumers — `DashX` and `DashXNotificationServiceExtension` are `.binaryTarget` entries in `Package.swift`, with Apollo statically baked into `DashX.xcframework` and hidden behind `@_implementationOnly import`. **Your own Apollo version (if any) won't collide with ours.** `DashXFirebase` stays a source target so your app's `FirebaseMessaging` version is the one DashX talks to at runtime.

## Documentation

Full setup, configuration, push notifications (including Notification Service Extension), deep linking, and API reference live on the docs site:

- [iOS SDK](https://docs.dashx.com/sdks/client-side/ios-sdk)
- [Messaging → Receive Push Notifications](https://docs.dashx.com/apps/messaging/receive-push-notifications)
- [Deep Linking & Push Navigation](https://docs.dashx.com/apps/messaging/deep-linking)

## Automatic events

The SDK can send these events on your behalf:

| Event | When | Data |
|---|---|---|
| `Application Installed` | First launch after install | `version`, `build` |
| `Application Updated` | First launch after an upgrade | `version`, `build`, `previous_build`, `previous_version` |
| `Application Opened` | Every other cold start, and every return from the background | `version`, `build`; `from_background: true` when returning from the background |
| `Application Backgrounded` | App enters the background | `session_length` (seconds in the foreground since the matching open) |
| `Application Crashed` | Uncaught Objective-C exception | `exception` |
| `$screen` | A view controller appears, or you call `DashX.screen(_:withData:)` | `$screen_name` plus any data you pass |
| `Deep Link Opened` | A deep link is processed | `url`, `source`, `timestamp` |
| `Push Notification Tapped` | A DashX notification is tapped | `notification_id`, `type`, `url` / `screen_name` / `screen_data` / `click_action`, `timestamp` |

Lifecycle and automatic screen events are opt-in. Call these once, after `configure()`, typically in `application(_:didFinishLaunchingWithOptions:)`; repeat calls are no-ops:

```swift
DashX.enableLifecycleTracking()
DashX.enableScreenTracking()
```

`enableScreenTracking()` names each screen by the view controller's `title`, then `navigationItem.title`, then its class name. Container controllers (navigation, tab bar, split, page), alerts and system controllers are skipped, and SwiftUI hosting controllers are only reported when they have a title. To name screens yourself, call `DashX.screen("Checkout")` instead. A screen you also report with `DashX.screen(_:withData:)` is sent twice, and child view controllers in your own containers are reported alongside their parent.

A launch in the background (silent push, background fetch) is not reported as an open; the launch event is sent when the app first becomes active.

If your `SceneDelegate` subclasses `DashXSceneDelegate`, mark `window` and the scene methods you implement `@objc` (for example `@objc var window: UIWindow?`). Swift does not expose a subclass's members to UIKit for a protocol its superclass adopts, so without it UIKit never sees the window and the app launches to a black screen.

## Install (CocoaPods)

CocoaPods consumers pull a prebuilt XCFramework — source compilation (and any downstream Apollo module surprises) happens on our Mac at release time, not on consumers' machines. The pod is **not** published to the CocoaPods trunk; reference it from git by tag:

```ruby
pod 'DashX/SDK', :git => 'https://github.com/dashxhq/dashx-ios.git', :tag => '1.4.0'
# For the Notification Service Extension target:
pod 'DashX/NotificationServiceExtension', :git => 'https://github.com/dashxhq/dashx-ios.git', :tag => '1.4.0'
```

Apollo is statically baked into `DashX.xcframework`; no separate `Apollo` pod dependency is declared.

React Native apps consume DashX transparently through `@dashx/react-native` — no Podfile change on their end.

See [CONTRIBUTING.md](./CONTRIBUTING.md) → *Cutting a release* for how the XCFrameworks get built.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for GraphQL codegen setup, local build notes, and the release process.
