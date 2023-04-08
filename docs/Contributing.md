# Contributing

## Obtaining GraphQL schema and generating GraphQL operation

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
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="Graphql/*.graphql" --passthroughCustomScalars Sources/DashX/API.swift
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
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="Graphql/*.graphql" --passthroughCustomScalars Sources/DashX/API.swift
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

To restrict the compilation to only one platform, either set the destination in Xcode to `Any iOS Device` or use the following command
```sh
$ xcodebuild -scheme DashX -destination 'generic/platform=iOS'
```
instead of
```sh
$ swift build
```
