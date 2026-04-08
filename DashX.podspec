Pod::Spec.new do |s|
  s.name         = "DashX"
  s.version      = "1.1.9"
  s.summary      = "DashX iOS SDK"
  s.homepage     = "https://github.com/dashxhq/dashx-ios"
  s.license      = { :type => "MIT" }
  s.authors      = { "DashX" => "support@dashx.com" }

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/dashxhq/dashx-ios.git", :tag => s.version }
  s.swift_version = "5.9"

  s.source_files  = "Sources/DashX/*.swift"

  s.resource_bundles = {
    "DashX" => ["Sources/DashX/Resources/**/*"]
  }

  s.dependency "Apollo", "~> 1.15"
end
