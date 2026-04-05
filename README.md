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
    <a href="https://docs.dashx.com/developer">Documentation</a>
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
