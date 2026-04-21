# Changelog

All notable changes to `dashx-ios` are documented in this file. Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [1.4.1] — 2026-04-21

### Fixed

- **Main-thread deadlock on cold-launch notification tap.** `SystemContextEnvironment.live`'s static-init path gated off-main `UIScreen` reads through `DispatchQueue.main.sync`. On cold launch, `DashX.configure()`'s `EventQueue.shared.flush()` dispatch made the background serial queue the first thread to touch `SystemContext.shared` — it grabbed the `.live` init lock and began `main.sync`'ing for the screen. Meanwhile iOS delivered `userNotificationCenter(_:didReceive:)` on main, which flowed into `DashXClient.track(...)` and also tried to touch `SystemContext.shared` — blocking on the same Swift static-init lock the background was holding. Main waited on background, background waited on main → app froze with a white screen until the iOS watchdog killed it. Fix drops the `main.sync` hop and reads the screen directly from whatever thread touches `.live` first — restores the pre-1.3.0 behaviour. Bug was introduced in 1.3.0 (silent → alert push migration); 1.3.x and 1.4.0 are all affected. See `Sources/DashX/SystemContext.swift`.

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
