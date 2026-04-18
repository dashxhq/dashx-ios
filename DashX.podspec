Pod::Spec.new do |s|
  s.name         = "DashX"
  s.version      = "1.3.0"
  s.summary      = "DashX iOS SDK"
  s.homepage     = "https://github.com/dashxhq/dashx-ios"
  s.license      = { :type => "MIT" }
  s.authors      = { "DashX" => "support@dashx.com" }

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/dashxhq/dashx-ios.git", :tag => s.version }
  s.swift_version = "5.9"

  s.default_subspec = "Core"

  # Shared notification-payload models. Used by the main SDK and the Notification
  # Service Extension. Kept free of Apollo so it can be linked into the NSE target
  # without bloating the extension binary.
  s.subspec "Core" do |core|
    core.source_files = "Sources/DashXCore/*.swift"
  end

  # Main DashX SDK. Depends on Apollo for GraphQL.
  s.subspec "SDK" do |sdk|
    sdk.source_files = "Sources/DashX/*.swift"
    sdk.dependency "DashX/Core"
    sdk.dependency "Apollo", "~> 1.15"
    sdk.resource_bundles = {
      "DashX" => ["Sources/DashX/Resources/**/*"]
    }
  end

  # Notification Service Extension base class. Integrators add a Notification Service
  # Extension target in their Xcode project and add this subspec to it. See README
  # for the required Info.plist keys (DashXBaseURI, DashXPublicKey).
  s.subspec "NotificationServiceExtension" do |nse|
    nse.source_files = "Sources/DashXNotificationServiceExtension/*.swift"
    nse.dependency "DashX/Core"
    nse.frameworks = "UserNotifications"
  end
end
