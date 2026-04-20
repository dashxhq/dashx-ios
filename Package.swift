// swift-tools-version:5.9

import PackageDescription

// DashX SPM: binary distribution via committed XCFrameworks.
//
// - `DashX.xcframework` carries the main SDK with Apollo + DashXCore
//   statically baked in. Apollo is hidden behind `@_implementationOnly import`
//   in the generated GraphQL code, so Apollo's types do not appear in DashX's
//   public `.swiftinterface`. Consumers with their own Apollo version in
//   their SPM graph will not collide — our copy is an internal implementation
//   detail of the xcframework.
// - `DashXNotificationServiceExtension.xcframework` carries the NSE base
//   class with DashXCore baked in (shipped as a static `.framework` inside
//   the xcframework so it links straight into the consumer's NSE target
//   without a runtime `@rpath` hop).
// - `DashXFirebase` stays a source target because `FirebaseMessaging` is a
//   shared runtime dependency (singletons for `FirebaseApp`, `Messaging.delegate`,
//   APNs token registration). The consumer's Firebase has to be the one in
//   use — we can't bake our own copy in.
//
// Tests live in the `build-project/DashX.xcodeproj` generated from
// `build-project/project.yml`, not in a `.testTarget` here. Binary targets
// can't satisfy `@testable import`, so the test suite runs against the same
// xcodeproj we use to build the xcframeworks (with `ENABLE_TESTABILITY=YES`
// in Debug).
//
// Xcframeworks are produced by `scripts/build_xcframeworks.sh` and committed
// under `xcframeworks/`. See CONTRIBUTING.md → "Cutting a release".

let package = Package(
    name: "DashX",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "DashX",
            targets: ["DashX"]
        ),
        .library(
            name: "DashXFirebase",
            targets: ["DashXFirebase"]
        ),
        .library(
            name: "DashXNotificationServiceExtension",
            targets: ["DashXNotificationServiceExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.9.0")),
    ],
    targets: [
        .binaryTarget(
            name: "DashX",
            path: "xcframeworks/DashX.xcframework"
        ),
        .binaryTarget(
            name: "DashXNotificationServiceExtension",
            path: "xcframeworks/DashXNotificationServiceExtension.xcframework"
        ),
        .target(
            name: "DashXFirebase",
            dependencies: [
                "DashX",
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        ),
    ]
)
