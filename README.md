<p align="center">
    <br />
    <a href="https://dashx.com"><img src="https://raw.githubusercontent.com/dashxhq/brand-book/master/assets/logo-black-text-color-icon@2x.png" alt="DashX" height="40" /></a>
    <br />
    <br />
    <strong>Your All-in-One Product Stack</strong>
</p>

<div align="center">
  <h4>
    <a href="https://dashx.com">Website</a>
    <span> | </span>
    <a href="https://dashxdemo.com">Demos</a>
    <span> | </span>
    <a href="https://docs.dashx.com/developer">Documentation</a>
  </h4>
</div>

<br />

# dashx-ios

_DashX SDK for iOS_

## Install

**CocoaPods**

Specify the dependency in your `Podfile`:

```
pod 'DashX'
```

Run the following command:

```sh
pod install
```

**Carthage**

Specify the dependency in your `Cartfile`:

```
github "dashxhq/dashx-ios"
```

Run the following command:

```sh
carthage update
```

**Swift Package Manager**

Add the following to your `Package.swift`:

```
dependencies: [
    .package(url: "https://github.com/dashxhq/dashx-ios.git", .upToNextMajor(from: "1.0.0"))
]
```

## Usage

For detailed usage, refer to the [documentation](https://docs.dashx.com/developer).

## Contributing

### Obtaining GraphQL schema and generating GraphQL operation

- Make sure to install Apollo CLI and GraphQL.js via npm:

```sh
$ npm i -g apollo
$ npm i -g graphql
```

- In order to generate code, Apollo requires local copy of Graphql schema, to download that:

```sh
$ apollo schema:download --endpoint="https://api.dashx-staging.com/graphql" schema.json
```

This will save a `schema.json` file in your ios directory.

- Add Graphql request in `graphql` dir.

- Regenerate `API.swift` using:

```sh
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="graphql/*.graphql" --passthroughCustomScalars Sources/DashX/API.swift
```

For example, if you want to generate code for `FetchCart`.

- Download schema

```sh
$ apollo schema:download --endpoint="https://api.dashx-staging.com/graphql" schema.json
```

- Add request in `graphql` dir with following contents:

```graphql
query FetchCart($input: FetchCartInput!) {
  fetchCart(input: $input) {
    id
    // ... other fields
  }
}
```

- Re-generate API.swift so it includes the `FetchCart` operation

```sh
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="graphql/*.graphql" --passthroughCustomScalars API.swift
```

- Now you can use FetchCart operation like so:

```swift
let fetchCartInput  = DashXGql.FetchCartInput( // Note the DashXGql namespace
    accountUid: self.accountUid,
    accountAnonymousUid: self.accountAnonymousUid
)

DashXLog.d(tag: #function, "Calling fetchCart with \(fetchCartInput)")

let fetchCartQuery = DashXGql.FetchCartQuery(input: fetchCartInput)

Network.shared.apollo.fetch(query: fetchCartQuery) { result in
  switch result {
  case .success(let graphQLResult):
    let json = graphQLResult.data?.fetchCart
    DashXLog.i(tag: #function, "Sent fetchCart with \(String(describing: json))")
    successCallback(json?.resultMap)
  case .failure(let error):
    DashXLog.e(tag: #function, "Encountered an error during fetchCart(): \(error)")
    failureCallback(error)
  }
}
```

- Compile package

**NOTE**: `platforms` key in `Package.swift` only specifies the minimum supported version for ex: `.iOS(...)`.

To restrict the compilation to only one platform, use the following command
```
$ xcodebuild -scheme DashX -destination 'generic/platform=iOS'
```
instead of
```
swift build
```

### Publishing

1. Bump up the version number in `DashX.podspec` and `Sources/DashX/Constants.swift`
2. Commit the version bump: `Bump version to x.x.x`
3. Create a tag: `git tag 'x.x.x'`
4. Push the tag: `git push origin --tags`

The GitHub Workflow will take care of the rest.
