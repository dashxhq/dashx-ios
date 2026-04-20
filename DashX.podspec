Pod::Spec.new do |s|
  s.name         = "DashX"
  s.version      = "1.4.0"
  s.summary      = "DashX iOS SDK"
  s.homepage     = "https://github.com/dashxhq/dashx-ios"
  s.license      = { :type => "MIT" }
  s.authors      = { "DashX" => "support@dashx.com" }

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/dashxhq/dashx-ios.git", :tag => s.version }
  s.swift_version = "5.9"

  s.default_subspec = "SDK"

  # Binary distribution. The two xcframeworks live under `xcframeworks/` in
  # the repo and are built locally via `scripts/build_xcframeworks.sh` — see
  # CONTRIBUTING.md → "Cutting a release". Each xcframework bundles the
  # shared `DashXCore` sources internally so consumers never have to link a
  # separate Core framework. That keeps SPM's three-target split (DashXCore,
  # DashX, DashXNotificationServiceExtension) independent of how CocoaPods
  # ships the SDK. Apollo is statically baked into DashX.xcframework; no
  # runtime Apollo pod dependency is declared.

  # Main DashX SDK — GraphQL client + runtime + shared models.
  s.subspec "SDK" do |sdk|
    sdk.vendored_frameworks = "xcframeworks/DashX.xcframework"
  end

  # Notification Service Extension base class. Add this subspec to the NSE
  # target in your Xcode project and subclass `DashXNotificationService`.
  # See README for required Info.plist keys (DASHX_BASE_URI, DASHX_PUBLIC_KEY).
  s.subspec "NotificationServiceExtension" do |nse|
    nse.vendored_frameworks = "xcframeworks/DashXNotificationServiceExtension.xcframework"
    nse.frameworks = "UserNotifications"
  end
end
