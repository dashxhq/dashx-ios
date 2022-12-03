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

- Make sure to install Apollo CLI via npm:

```sh
$ npm i -g apollo
```

- In order to generate code, Apollo requires local copy of Graphql schema, to download that:

```sh
$ apollo schema:download --endpoint="https://api.dashx.com/graphql" schema.json
```

This will save a `schama.json` file in your ios directory.

- Add Graphql request in `graphql` dir.

- Regenerate `API.swift` using:

```sh
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="graphql/*.graphql" --passthroughCustomScalars API.swift
```

For example, if you want to generate code for `FetchContent`.

- Download schema

```sh
$ apollo schema:download --endpoint="https://api.dashx.com/graphql" schema.json
```

- Add request in `graphql` dir with following contents:

```graphql
query FetchContent($input: FetchContentInput!) {
  fetchContent(input: $input)
}
```

- Re-generate API.swift so it includes the `FetchContent` operation

```sh
$ apollo client:codegen --target=swift --namespace=DashXGql --localSchemaFile=schema.json --includes="graphql/*.graphql" --passthroughCustomScalars API.swift
```

- Now you can use FetchContent operation like so:

```swift
let fetchContentInput  = DashXGql.FetchContentInput( // Note the DashXGql namespace
    contentType: contentType,
    content: content,
    preview: preview,
    language: language,
    fields: fields,
    include: include,
    exclude: exclude
)

DashXLog.d(tag: #function, "Calling fetchContent with \(fetchContentInput)")

let fetchContentQuery = DashXGql.FetchContentQuery(input: fetchContentInput)

Network.shared.apollo.fetch(query: fetchContentQuery, cachePolicy: .returnCacheDataElseFetch) { result in
  switch result {
  case .success(let graphQLResult):
    DashXLog.d(tag: #function, "Sent fetchContent with \(String(describing: graphQLResult))")
    let content = graphQLResult.data?.fetchContent
    resolve(content)
  case .failure(let error):
    DashXLog.d(tag: #function, "Encountered an error during fetchContent(): \(error)")
    reject("", error.localizedDescription, error)
  }

```

### Publishing

1. Bump up the version number in `DashX.podspec` and `DashX\Constants.swift`
2. Commit the version bump: `Bump version to x.x.x`
3. Create a tag: `git tag 'x.x.x'`
4. Push the tag: `git push origin --tags`

The GitHub Workflow will take care of the rest.
