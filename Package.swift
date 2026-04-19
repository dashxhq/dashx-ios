// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "DashX",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "DashXCore",
            targets: ["DashXCore"]
        ),
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
        // CocoaPods consumers now receive DashX as a prebuilt XCFramework with
        // Apollo baked in, so we no longer need the SPM pin to match whatever's
        // available on CocoaPods trunk. Bumping is safe as long as the SDK's
        // generated `.graphql.swift` code matches this version's API surface.
        .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "1.25.3"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.9.0")),
    ],
    targets: [
        .target(
            name: "DashXCore"
        ),
        .target(
            name: "DashX",
            dependencies: [
                "DashXCore",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios"),
            ],
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("SafariServices"),
            ]
        ),
        .target(
            name: "DashXFirebase",
            dependencies: [
                "DashX",
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        ),
        .target(
            name: "DashXNotificationServiceExtension",
            dependencies: [
                "DashXCore",
            ]
        ),
        .testTarget(
            name: "DashXTests",
            dependencies: ["DashX", "DashXNotificationServiceExtension"],
            path: "Tests/SDKTests"
        ),
    ]
)
