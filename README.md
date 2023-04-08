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
    <a href="https://dashxdemo.com">Demos</a>
    <span> | </span>
    <a href="https://docs.dashx.com/developer">Documentation</a>
  </h4>
</div>

<br />

# dashx-ios

_DashX SDK for iOS_

&emsp;

# Installation

### Using Cocoapods

1. Open your iOS project and increase the min SDK target to iOS 12.0+
2. Update Podfile

```ruby
platform :ios, '12.0'
..
target 'YOUR_TARGET_NAME' do
    ..
    pod 'DashX'
    ..
end
```

3. Open terminal in root directory and run

```sh
pod install
```

### Using Carthage

Specify the dependency in your `Cartfile`:

```
github "dashxhq/dashx-ios"
```

Run the following command:

```sh
carthage update
```

## Using Swift Package Manager

1. Open your iOS project and increase the min SDK target to iOS 12.0+
2. In your Xcode project, go to File > Add Packages
3. Paste the following url in "Search or Enter Package URL"

```
https://github.com/dashxhq/dashx-ios.git
```

&emsp;

# Getting Started

These are all the available features of the SDK.

|   | Feature                                   | Description                                                                                                                |
|---|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| 1 | [`Event Tracking`](/docs/EventTracking.md) | Event Tracking |
| 2 | [`Push Notifications`](/docs/PushNotifications.md) | Automatically manages push notification device tokens and gives convenient functions for handling push notification receiving and clicking. |
| 3 | [`Contact Management`](/docs/ContactManagement.md) | Contact Management|

# Usage

For detailed usage, refer to the [documentation](https://docs.dashx.com/developer).

&emsp;

# [Contributing](/docs/Contributing.md)

&emsp;

# Publishing

1. Bump up the version number in `DashX.podspec` and `Sources/DashX/Constants.swift`
2. Commit the version bump: `Bump version to x.x.x`
3. Create a tag: `git tag 'x.x.x'`
4. Push the tag: `git push origin --tags`

The GitHub Workflow will take care of the rest.
