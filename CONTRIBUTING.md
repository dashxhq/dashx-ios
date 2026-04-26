# Contributing

## GraphQL codegen

The SDK uses the modern `apollo-ios-cli` (the Swift-based CLI bundled with Apollo iOS 1.x) to generate Swift types from the DashX GraphQL schema. Configuration lives in [`apollo-codegen-config.json`](./apollo-codegen-config.json). Generated code lives under [`Sources/DashX/GraphQL/`](./Sources/DashX/GraphQL/) and **is committed** — regenerate and commit the result whenever the schema or an operation changes.

`schema.json` and `apollo-ios-cli` are both gitignored and fetched per-developer.

### One-time setup

Install `apollo-ios-cli` into the repo via the Apollo SwiftPM plugin, then pull the schema:

```sh
swift package --allow-writing-to-package-directory --allow-network-connections all apollo-cli-install
./apollo-ios-cli fetch-schema
```

The first command drops an `apollo-ios-cli` binary at the repo root — re-run it whenever you upgrade the Apollo version pinned in `Package.swift`. The second writes a fresh `schema.json` at the repo root; it reads `schemaDownload.downloadMethod.introspection.endpointURL` from `apollo-codegen-config.json` (points at `api.dashx-staging.com/graphql` by default). Re-fetch it whenever the backend schema changes.

### Add a new operation

1. Drop your `.graphql` file under `Graphql/` — for example `Graphql/FetchCart.graphql`:

   ```graphql
   query FetchCart($input: FetchCartInput!) {
       fetchCart(input: $input) {
           id
           # ...other fields
       }
   }
   ```

2. Run the codegen, then apply the implementation-only-import patch:

   ```sh
   ./apollo-ios-cli generate
   ./scripts/apply_implementation_only_imports.sh
   ```

   The patch rewrites every `@_exported import ApolloAPI` (codegen's default) to
   `@_implementationOnly import ApolloAPI`. Without it, Apollo shows up in the
   xcframework's public `.swiftinterface` and CocoaPods consumers — who link
   the statically-baked xcframework and have no `ApolloAPI` module visible —
   fail to build with `no such module 'ApolloAPI'`. The script is idempotent,
   so re-running it is safe.

3. Use the generated type. Everything is namespaced under `DashXGql`:

   ```swift
   let input = DashXGql.FetchCartInput(
       accountUid: self.accountUid,
       accountAnonymousUid: self.accountAnonymousUid
   )
   Network.shared.apollo.fetch(query: DashXGql.FetchCartQuery(input: input)) { result in
       switch result {
       case .success(let graphQLResult):
           let cart = graphQLResult.data?.fetchCart
           DashXLog.i(tag: #function, "Sent fetchCart with \(String(describing: cart))")
           // Access typed fields directly: cart?.id, cart?.items, ...
       case .failure(let error):
           DashXLog.e(tag: #function, "fetchCart error: \(error)")
       }
   }
   ```

### JSON scalars

`DashXGql.JSON` is a `CustomScalarType` struct wrapping an `ApolloAPI.JSONValue` (an `AnyHashable`). It serializes on the wire as a real JSON value — object, array, primitive — not a stringified JSON literal, so backend resolvers that assert `data.is_object()` (e.g. `track_event.rs::validate_event_data`) accept it.

Construct one from any `Hashable` payload (typically a dictionary):

```swift
let scalar = DashXGql.JSON(["foo": "bar", "n": 42] as [String: AnyHashable])
```

When a caller hands you a looser `[String: Any]`, use the internal helpers on `DashXClient`, which silently drop entries whose values aren't `Hashable`:

- `DashXClient.toJSONScalar([String: Any]) -> DashXGql.JSON`
- `DashXClient.fromJSONScalar(DashXGql.JSON) -> [String: Any?]`

On the read side, `DashXGql.JSON` also exposes typed accessors — `asDictionary`, `asArray`, `asString`, `asBool`, `asInt`, `asDouble`, `isNull` — which return nil when the underlying value has a different shape. Prefer those over raw `value as? T` casts.

## Repo layout (binary SPM)

`Package.swift` ships three products:

- **`DashX`** — a `.binaryTarget` pointing at `xcframeworks/DashX.xcframework`. The main SDK, with Apollo + `DashXCore` statically baked in. Apollo is hidden via `@_implementationOnly import` so its symbols never appear in DashX's public `.swiftinterface` — consumers on any Apollo version don't collide with ours.
- **`DashXNotificationServiceExtension`** — a `.binaryTarget` pointing at `xcframeworks/DashXNotificationServiceExtension.xcframework`. NSE base class, Core baked in, shipped as `MACH_O_TYPE = staticlib` so the consumer's `.appex` links us straight in (no runtime `@rpath` hop).
- **`DashXFirebase`** — a regular source `.target` that depends on binary `DashX` + `FirebaseMessaging`. Kept source on purpose: Firebase is a runtime-shared dep (singleton `FirebaseApp`, `Messaging.delegate`, APNs token registration) and has to be the same instance the host app uses.

`Sources/DashXCore/` and `Sources/DashXNotificationServiceExtension/` still exist in the repo — they're compiled INTO each framework target via `build-project/project.yml`. They're no longer SPM products, so consumers can't `import DashXCore` directly; Core's public API (`NavigationAction`, `ActionButton`, `Constants`, …) is exposed as part of the `DashX` module.

## Compile-check locally

`platforms` in `Package.swift` only specifies the *minimum* supported version (e.g. `.iOS(...)`). To restrict the compilation to a single platform, either set the destination in Xcode to `Any iOS Device` or run:

```sh
xcodebuild -scheme DashX -destination 'generic/platform=iOS'
```

instead of `swift build` (which tries to compile for every platform the package lists).

## Running tests

Tests do not live in `Package.swift`'s `.testTarget` — binary SPM targets can't satisfy `@testable import` (the sealed `.swiftinterface` hides internal symbols). They live in `build-project/DashX.xcodeproj` instead, which compiles the same `Sources/**` with `ENABLE_TESTABILITY = YES` in the Debug config.

```sh
xcodebuild test \
  -project build-project/DashX.xcodeproj \
  -scheme DashXTests \
  -destination 'platform=iOS Simulator,name=iPhone 17e,OS=latest'
```

The `DashXTests` scheme aggregates two bundles that ship as separate test targets — `DashXTests` (linked against `DashX`) and `DashXNotificationServiceExtensionTests` (linked against NSE) — because DashX and NSE each bake in a private copy of `Sources/DashXCore`. A single test target linking both would see every `DashXCore` extension twice (e.g. `Dictionary.dashxNotificationData()`) and fail to disambiguate. Splitting the targets gives each one exactly one Core copy.

If you edit `Tests/SDKTests/**` or `build-project/project.yml`, regenerate the xcodeproj before running tests:

```sh
cd build-project && xcodegen generate
```

## Publishing

The SDK ships two surfaces from the same tag, both binary:

- **Swift Package Manager** — consumers add `.package(url: "https://github.com/dashxhq/dashx-ios.git", from: "x.x.x")`. SPM resolves to the committed `xcframeworks/` via `.binaryTarget(path: ...)`. No Apollo dep surfaces, no version conflicts.
- **CocoaPods** — consumers reference `pod 'DashX/SDK', :git => '…', :tag => 'x.x.x'`. Same xcframeworks, shipped through `DashX.podspec`'s `vendored_frameworks`. Tagging the git ref is the entire release step — consumers point at the tag via `:git` + `:tag`.

### One-time setup

Building the XCFrameworks requires [`xcodegen`](https://github.com/yonaskolb/XcodeGen) to regenerate `build-project/DashX.xcodeproj` from `build-project/project.yml`:

```sh
brew install xcodegen
```

`build-project/DashX.xcodeproj` is committed so PRs touching `project.yml` surface a reviewable pbxproj diff, and so a release can proceed on a machine without xcodegen if the project hasn't drifted. It lives in `build-project/` — not the repo root — so it doesn't shadow `Package.swift` when `xcodebuild -scheme …` runs in CI or locally.

### Cutting a release

1. Bump version in `Sources/DashX/Constants.swift` (`PACKAGE_VERSION`), `DashX.podspec` (`s.version`), and `build-project/project.yml` (`MARKETING_VERSION`).
2. Build the XCFrameworks: `./scripts/build_xcframeworks.sh` (regenerates `build-project/DashX.xcodeproj` if xcodegen is installed).
3. Commit the version bumps + the refreshed xcodeproj + xcframeworks:
   ```sh
   git add Sources/DashX/Constants.swift DashX.podspec build-project/ xcframeworks/
   git commit -m "Bump version to x.x.x"
   ```
4. Tag and push: `git tag x.x.x && git push origin main --tags`

SPM and CocoaPods consumers both pick the new version up from the git tag.

CI runs tests on every push and PR via `xcodebuild test -project build-project/DashX.xcodeproj -scheme DashXTests`, and smoke-builds `DashXFirebase` against the committed xcframework.
