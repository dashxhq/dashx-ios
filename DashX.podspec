Pod::Spec.new do |spec|

  spec.name         = "DashX"
  spec.module_name  = "DashX"
  spec.version      = "1.0.21"
  spec.summary      = "DashX SDK for iOS"

  spec.description  = <<-DESC
    DashX is an all-in-one Product Stack which includes the following features: Content Management, Notifications System, Billing System, Feature Flags, Analytics, Business Intelligence and more!
  DESC

  spec.homepage     = "https://dashx.com"
  spec.license      = "MIT"
  spec.author       = { "Team DashX" => "dev@dashx.com" }

  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.9"

  spec.source       = { :git => "https://github.com/dashxhq/dashx-ios.git", :tag => "#{spec.version}" }

  spec.framework    = "UIKit"

  spec.default_subspec = 'Core'

  spec.subspec 'Core' do |core|
    core.source_files = "Sources/DashX/**/*.{h,m,swift}"
    core.resource_bundles = {
      "DashX_Privacy" => ["Sources/DashX/Resources/PrivacyInfo.xcprivacy"]
    }
    core.dependency 'Apollo', '~> 1.15'
  end

  spec.subspec 'Firebase' do |firebase|
    firebase.source_files = "Sources/DashXFirebase/**/*.{h,m,swift}"
    firebase.dependency 'DashX/Core'
    firebase.dependency 'FirebaseMessaging', '~> 10.5.0'
  end

end
