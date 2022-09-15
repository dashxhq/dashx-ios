// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DashX",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DashX",
            targets: ["DashX"]
        ),
    ],
    dependencies: [
        .package(name: "SwiftGraphQL", url: "https://github.com/maticzav/swift-graphql", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DashX",
            dependencies: [
                .product(name: "SwiftGraphQL", package: "SwiftGraphQL"),
                .product(name: "SwiftGraphQLClient", package: "SwiftGraphQL"),
                .product(name: "GraphQL", package: "SwiftGraphQL")
            ],
            path: "Sources/DashX"
        )
    ]
)
