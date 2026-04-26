# Changelog

All notable changes to `dashx-ios` are documented in this file. Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [1.5.0] — 2026-04-23

### Breaking

- **`unsubscribe` now reports a `Bool` success status.** Backend mutation `unsubscribeContact` changed its return type from `Contact!` (with `id`, `value`) to `UnsubscribeContactResponse!` (with `success: Boolean!`). The SDK now forwards this value to callers:
  - `public func unsubscribe(completion: ((Result<Void, Error>) -> Void)? = nil)` → `public func unsubscribe(completion: ((Result<Bool, Error>) -> Void)? = nil)`
  - `public func unsubscribe() async throws` → `@discardableResult public func unsubscribe() async throws -> Bool`
  - `success: false` is a non-error outcome meaning "no matching contact found to unsubscribe" — typically happens when the anonymous UID rotated since subscribe, the FCM token is stale, or the contact is already unsubscribed. From the end-user's perspective the state is equivalent in both cases; the boolean is useful for diagnostics and analytics.
- **Call-site migration:**
  - Call sites using `case .success:` without a value binding or `try await DashX.unsubscribe()` without capturing the return compile unchanged (the async overload is `@discardableResult`).
  - Call sites that extracted the old `Void`/`()` value (rare — `.success(let v)` where `v: Void`) now capture a `Bool` instead. Rename or branch accordingly.
- **Early-return paths now call completion.** Previously, calling `unsubscribe(completion:)` when no FCM token was saved locally (or when `accountAnonymousUid` was missing) silently dropped the completion handler. These paths now always fire completion so callers awaiting the result don't hang. Differentiation between the two:
  - **No saved FCM token** (the "user hasn't subscribed in this device session" case) → `completion(.success(false))`. Same semantics as the backend's "no matching contact" outcome.
  - **No `accountAnonymousUid`** (the "`unsubscribe()` called before `configure()`" SDK-misuse case) → `completion(.failure(DashXClientError.customError(message: ...)))`. Distinct from `success: false` so callers can branch — and so the boolean stays a clean signal for legitimate non-error outcomes only.

### Fixed

- **`reset()` no longer races with the in-flight `unsubscribe()` mutation it triggers.** `reset()` calls `unsubscribe()` and then immediately wipes `self.accountUid`. The unsubscribe mutation was reading `self.accountUid` lazily (inside Firebase's `deleteToken` callback that fires after `reset()` has already returned) — so the mutation went to the backend with `accountUid: null` even when the user had a non-null UID at unsubscribe-call time. For contacts created during an identified session, the backend's lookup couldn't match, the mutation silently returned `success: false`, and the contact remained subscribed on the server. `unsubscribe()` now snapshots `self.accountUid` into a local at call-entry alongside the existing `token` and `anonymousUid` snapshots, so the mutation sees the pre-reset identity correctly even when the wipe happens concurrently. `reset()`'s public behavior is unchanged — still synchronous, still wipes state immediately on the calling thread.

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
