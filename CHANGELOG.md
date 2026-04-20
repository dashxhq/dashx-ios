# Changelog

All notable changes to `dashx-ios` are documented in this file. Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [1.4.0] — 2026-04-20

### Breaking

- **SPM now ships binary XCFrameworks instead of compiling from source.** `Package.swift`'s `DashX` and `DashXNotificationServiceExtension` targets are `.binaryTarget` entries pointing at the committed `xcframeworks/` — the same artifacts CocoaPods consumers already link. Apollo is statically baked into `DashX.xcframework` and hidden behind `@_implementationOnly import`, so it no longer appears in the consumer's SPM dependency graph and cannot collide with a host app's own Apollo version. This is the entire motivation for the release — consumers on any Apollo version can now upgrade without hitting SPM resolver conflicts.
- **`DashXCore` is no longer an SPM product.** Its public types (`NavigationAction`, `ActionButton`, `DashXNotificationData`, `DashXNotificationKeys`, `DashXNotificationMessage`, `Constants`, and the `KeyedDecodingContainer` / `Dictionary` extensions) are re-exported through the `DashX` module. Migration: remove any `import DashXCore` from consumer code — `import DashX` already covers them.
- **`apollo-ios` dropped from `Package.swift` dependencies.** If you were importing `Apollo` or `ApolloAPI` transitively through DashX (unsupported — they were flagged `@_implementationOnly`), declare the package explicitly in your own `Package.swift`.

### Added

- `build-project/DashX.xcodeproj` now carries unit-test targets (`DashXTests`, `DashXNotificationServiceExtensionTests`) and an aggregate `DashXTests` scheme. Tests live here rather than in `Package.swift`'s `.testTarget` because binary SPM targets can't satisfy `@testable import`. `project.yml` splits settings per config — Debug builds with `ENABLE_TESTABILITY=YES` for tests, Release builds with `BUILD_LIBRARIES_FOR_DISTRIBUTION=YES` for xcframework archiving.
- `README.md` and `CONTRIBUTING.md` updated to describe the binary-SPM layout and the xcodeproj-based test flow.

### Unchanged

- `DashXFirebase` stays a regular source target with `FirebaseMessaging` as a declared dep. Firebase is a runtime-shared singleton (`FirebaseApp`, `Messaging.delegate`, APNs token registration) and has to be the same instance the host app uses — we can't bake our own copy in.
- CocoaPods path is unchanged. `DashX.podspec` still ships the two `vendored_frameworks` subspecs (`DashX/SDK`, `DashX/NotificationServiceExtension`) from the same `xcframeworks/` directory. Consumer Podfile snippets don't change.

## [1.3.2] — 2026-04-20

Previous releases — see git log.
