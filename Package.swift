// swift-tools-version:5.9

import PackageDescription

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
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.15.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.9.0")),
    ],
    targets: [
        .target(
            name: "DashX",
            dependencies: [
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
        .testTarget(
            name: "DashXTests",
            dependencies: ["DashX"],
            path: "Tests/SDKTests"
        ),
    ]
)
