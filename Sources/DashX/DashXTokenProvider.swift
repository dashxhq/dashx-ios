import Foundation

/// Receives a `DashXTokenProvider` result; only the first delivery is accepted.
public protocol DashXTokenCallback: AnyObject {
    func onToken(_ token: String)

    /// No valid token is available — the SDK enters `authenticationFailed` rather than retrying at
    /// once. The next chat operation, conversation open or return to the foreground asks again.
    func onUnavailable(_ cause: Error?)
}

/// Supplies identity tokens on demand; registered via `DashXClient.setIdentityTokenProvider(uid:provider:)`.
/// Called off the main thread; deliver exactly once. `forceRefresh` is true after the current token
/// was rejected. Register at launch: the cached token survives process death, the provider does not.
public protocol DashXTokenProvider: AnyObject {
    func loadToken(forceRefresh: Bool, callback: DashXTokenCallback)
}

public final class DashXClosureTokenProvider: DashXTokenProvider {
    public typealias Loader = (_ forceRefresh: Bool, _ callback: DashXTokenCallback) -> Void

    private let loader: Loader

    public init(_ loader: @escaping Loader) {
        self.loader = loader
    }

    public func loadToken(forceRefresh: Bool, callback: DashXTokenCallback) {
        loader(forceRefresh, callback)
    }
}

/// Adapter for an `async` loader: nil or a thrown error reports `onUnavailable`. After
/// `loaderTimeout` the loader's task is cancelled, which ends only a loader that observes
/// cancellation; one that does not (a continuation that never resumes, say) keeps the callback
/// pending. The SDK does not wait on it: a load unanswered after 30 seconds is reported unavailable.
public final class DashXAsyncTokenProvider: DashXTokenProvider {
    public typealias Loader = (_ forceRefresh: Bool) async throws -> String?

    private static let loaderTimeout: TimeInterval = 35

    private let loader: Loader

    public init(_ loader: @escaping Loader) {
        self.loader = loader
    }

    public func loadToken(forceRefresh: Bool, callback: DashXTokenCallback) {
        let loader = self.loader
        Task {
            do {
                let token = try await Self.withTimeout(Self.loaderTimeout) { try await loader(forceRefresh) }
                if let token {
                    callback.onToken(token)
                } else {
                    callback.onUnavailable(nil)
                }
            } catch {
                callback.onUnavailable(error)
            }
        }
    }

    private struct TimeoutError: Error {}

    private static func withTimeout<T>(_ seconds: TimeInterval, _ body: @escaping () async throws -> T?) async throws -> T? {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask { try await body() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            let first = try await group.next()
            group.cancelAll()
            return first ?? nil
        }
    }
}
