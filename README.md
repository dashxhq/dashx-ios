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

## Documentation

Full setup, configuration, push notifications (including Notification Service Extension), deep linking, and API reference live on the docs site:

- [iOS SDK](https://docs.dashx.com/sdks/client-side/ios-sdk)
- [Messaging → Receive Push Notifications](https://docs.dashx.com/apps/messaging/receive-push-notifications)
- [Deep Linking & Push Navigation](https://docs.dashx.com/apps/messaging/deep-linking)

## Install (CocoaPods)

CocoaPods consumers pull a prebuilt XCFramework — source compilation (and any downstream Apollo module surprises) happens on our Mac at release time, not on consumers' machines.

```ruby
pod 'DashX/SDK', '~> 1.3.1'
# For the Notification Service Extension target:
pod 'DashX/NotificationServiceExtension', '~> 1.3.1'
```

Apollo is statically baked into `DashX.xcframework`; no separate `Apollo` pod dependency is declared.

React Native apps consume DashX transparently through `@dashx/react-native` — no Podfile change on their end.

See [CONTRIBUTING.md](./CONTRIBUTING.md) → *Cutting a release* for how the XCFrameworks get built and published.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for GraphQL codegen setup, local build notes, and the release process.
