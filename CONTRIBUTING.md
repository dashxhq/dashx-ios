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

2. Run:

   ```sh
   ./apollo-ios-cli generate
   ```

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

`DashXGql.JSON` is a typealias for `String` (the wire format). Convert between Swift dictionaries and the scalar via the helpers on `DashXClient`:

- `DashXClient.encodeDictAsJSONString([String: Any]) -> DashXGql.JSON`
- `DashXClient.decodeJSONStringToDict(DashXGql.JSON) -> [String: Any?]?`

## Compile-check locally

`platforms` in `Package.swift` only specifies the *minimum* supported version (e.g. `.iOS(...)`). To restrict the compilation to a single platform, either set the destination in Xcode to `Any iOS Device` or run:

```sh
xcodebuild -scheme DashX -destination 'generic/platform=iOS'
```

instead of `swift build` (which tries to compile for every platform the package lists).

## Publishing

1. Bump the version in `Sources/DashX/Constants.swift` (`PACKAGE_VERSION`) & `DashX.podspec` (`s.version`).
2. Commit the version bump: `Bump version to x.x.x`.
3. Create a tag: `git tag 'x.x.x'`.
4. Push the tag: `git push origin --tags`.

Apps that depend on this package via Swift Package Manager should pin that tag (or a branch). CI runs `xcodebuild` for the `DashX` and `DashXFirebase` schemes on pushes and pull requests to `main`.
