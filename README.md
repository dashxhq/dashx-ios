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

A [CocoaPods spec](https://github.com/dashxhq/dashx-ios/blob/main/DashX.podspec) publishes the core **DashX** library; the **DashXFirebase** helper is available via Swift Package Manager from the same repository.

## Documentation

For detailed documentation, visit [iOS SDK documentation](https://docs.dashx.com/sdks/client-side/ios-sdk).

## Deep linking and push navigation

The SDK routes notification taps and URLs through a small set of APIs so you can track opens and navigate in your app.

### Subclass `DashXAppDelegate` and `DashXSceneDelegate`

- **`DashXAppDelegate`** wires push permission, delivery/click/dismiss tracking, and sets `DashXClient.instance.linkHandler` to your `handleLink(url:)`. Override **`onNotificationClicked(message:action:actionIdentifier:)`** and return `true` if you handle navigation yourself (the SDK skips default URL / rich-landing / legacy hooks). Return `false` to let the SDK continue with default behavior.
- **`DashXSceneDelegate`** forwards **custom URL schemes** from `scene(_:openURLContexts:)` and **universal links** from `scene(_:continue:)` into `DashXClient.processURL` / `handleUserActivity`. Subclass it and call `super` for those methods if you add your own scene logic.

### URLs and analytics

- **`DashXClient.processURL(_:source:forwardToLinkHandler:)`** records a `dx_deep_link_opened` event and, by default, invokes `linkHandler` so your `handleLink(url:)` runs. Use `forwardToLinkHandler: false` when you only want the event (for example when the SDK presents an in-app browser for rich landing).
- **`DashXClient.handleUserActivity(userActivity:)`** handles `NSUserActivityTypeBrowsingWeb` universal links; call it from the app delegate or scene delegate when you are not using `DashXSceneDelegate`.

### Notification payload (inside `dashx_notification_data`)

Structured fields include: `url`, `screen_name`, `screen_data`, `click_action`, `rich_landing`, and `action_buttons` (each button: `identifier`, `label`, `url`, `screen_name`, `screen_data`, `rich_landing`, etc.). The SDK resolves a **`NavigationAction`** (deep link URL, in-app rich landing, or screen + data) for the main tap or a specific action button.

### Host app configuration

- **Universal Links**: add the Associated Domains capability and host `apple-app-site-association` on your domain; handle continuation in `DashXSceneDelegate` or forward to `handleUserActivity` yourself.
- **Custom URL schemes**: register the scheme in **Info** > **URL Types**; ensure `scene(_:openURLContexts:)` calls through to `DashXSceneDelegate` (or call `processURL` yourself).
