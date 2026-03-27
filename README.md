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
    <a href="https://docs.dashx.com">Documentation</a>
  </h4>
</div>

<br />

# dashx-ios

_DashX SDK for iOS_

## Install

The minimum supported iOS version is **13.0**. In Xcode, set your app target’s **General** > **Deployment Info** to 13.0 or higher.

### Swift Package Manager

1. In your Xcode project, choose **File** > **Add Package Dependencies…**
2. Enter the repository URL:

```
https://github.com/dashxhq/dashx-ios.git
```

3. Add the **DashX** library to your app target. If you use push notifications / Firebase integration helpers from this SDK, also add **DashXFirebase**.

## Usage

For detailed usage, refer to the [documentation](https://docs.dashx.com).

### Configuration

```swift
import DashX

DashX.configure(withPublicKey: "your-public-key")
```

### Offline Event Queue

When a `track()` call fails or the device is offline, events are automatically persisted to a queue backed by `UserDefaults`. Queued events are retried with exponential backoff (2 s base, capped at 5 minutes, max 10 retries, with jitter). The queue holds up to 1,000 events and flushes automatically when:

- `configure()` is called
- The network becomes available

You can flush manually:

```swift
DashX.flushEventQueue()
```

### Error Handling

All SDK errors are represented by `DashXClientError`, which conforms to `LocalizedError`:

| Error | Description | `isRetryable` |
|-------|-------------|---------------|
| `noArgsInIdentify` | `identify()` called without options | No |
| `notIdentified` | Operation requires an identified user | No |
| `graphQLErrors([String])` | Server returned GraphQL errors | No |
| `networkError(underlying:)` | Network-level failure | Yes |
| `assetIsNotReady` | Asset not yet processed | Yes |
| `assetIsNotUploaded` | Asset upload failed | No |
| `customError(message:)` | Custom error message | No |

Each error provides `errorDescription` and `recoverySuggestion` for user-facing messages:

```swift
DashX.fetchStoredPreferences { result in
    switch result {
    case .success(let prefs):
        print(prefs)
    case .failure(let error):
        print(error.localizedDescription)
        if let dashxError = error as? DashXClientError {
            print(dashxError.recoverySuggestion ?? "")
            if dashxError.isRetryable {
                // retry later
            }
        }
    }
}
```

### Configurable Asset Polling

Asset upload polling uses exponential backoff (2 s base, capped at 60 s). You can configure the polling behavior:

```swift
DashXClient.maxAssetPollRetries = 5       // default: 5
DashXClient.assetPollBaseInterval = 2.0   // default: 2.0 seconds
```

### async/await Support

All completion-based methods have async/await overloads:

```swift
let prefs = try await DashX.fetchStoredPreferences()
let record = try await DashX.fetchRecord(urn: "blog/abc123")
let records = try await DashX.searchRecords(resource: "blog", limit: 10)
try await DashX.identify(options: ["email": "user@example.com"])
```
