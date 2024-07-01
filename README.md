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
    <a href="https://docs.dashx.com">Documentation</a>
  </h4>
</div>

<br />

# dashx-ios

_DashX SDK for iOS_

## Install

The minimum supported version for iOS is 12.0. To set the Minimum SDK target,
1. Open your iOS project in XCode
2. Select your Target > **General** > **Deployment Info** > Ensure that the version is set to 12.0+

### Using Cocoapods

1. Update your Podfile:

```ruby
platform :ios, '12.0' # must be 12 or higher
# ...
target 'YOUR_TARGET_NAME' do
    # ...
    pod 'DashX'
    # ...
end
```

2. Open Terminal in your project's root directory and run:

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

### Using Swift Package Manager

1. In your Xcode project, go to **File** > **Add Packages**
2. Paste the following URL in "Search or Enter Package URL":

```
https://github.com/dashxhq/dashx-ios.git
```

## Usage

For detailed usage, refer to the [documentation](https://docs.dashx.com).
