// `@_implementationOnly` keeps Apollo out of DashX's public `.swiftinterface`,
// which is critical for the CocoaPods binary distribution: Apollo is baked
// into `DashX.xcframework` statically, so consumers must never see Apollo
// names in the interface (they wouldn't have Apollo available as a module).
// Safe because no public DashX API exposes Apollo types (DashXGql is
// `internal`).
@_implementationOnly import Apollo
#if canImport(ApolloAPI)
@_implementationOnly import ApolloAPI
#endif
import AppTrackingTransparency
// Under SPM, DashXCore is a separate target we re-export so integrators see
// its models via `import DashX`. Under the xcodegen build path that drives
// the CocoaPods binary release, DashXCore's sources are compiled into this
// same DashX module, so the import doesn't apply (and would fail — no such
// module). See project.yml for why Core is baked into each target.
#if canImport(DashXCore)
@_exported import DashXCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif
import Foundation
import UIKit

@available(*, deprecated, message: "Use Result-based or async/await overloads instead")
public typealias SuccessCallback = (Any?) -> ()

@available(*, deprecated, message: "Use Result-based or async/await overloads instead")
public typealias FailureCallback = (Error) -> ()

public enum DashXClientError: Error, LocalizedError {
    case noArgsInIdentify
    case assetIsNotReady
    case assetIsNotUploaded
    /// The SDK operation requires an identified user but none is set.
    case notIdentified
    /// One or more GraphQL errors were returned by the server.
    case graphQLErrors([String])
    /// A network-level failure (DNS, TLS, timeout, etc.).
    case networkError(underlying: Error)
    case customError(message: String)

    public var errorDescription: String? {
        switch self {
        case .noArgsInIdentify:
            return "identify() was called without any options."
        case .assetIsNotReady:
            return "The asset is not ready for use yet."
        case .assetIsNotUploaded:
            return "The asset could not be uploaded."
        case .notIdentified:
            return "No identified user. Call setIdentity() before this operation."
        case .graphQLErrors(let messages):
            return "GraphQL errors: \(messages.joined(separator: "; "))"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .customError(let message):
            return message
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noArgsInIdentify:
            return "Pass a dictionary with at least one user attribute (e.g. email, uid)."
        case .assetIsNotReady:
            return "Wait and retry fetching the asset, or increase the polling timeout."
        case .assetIsNotUploaded:
            return "Check that the file exists, is readable, and that your network connection is stable."
        case .notIdentified:
            return "Call DashXClient.instance.setIdentity(uid:token:) before performing this operation."
        case .graphQLErrors:
            return "Check the error messages for details. This may indicate invalid input or a server-side issue."
        case .networkError:
            return "Check your network connection and try again."
        case .customError:
            return nil
        }
    }

    /// Whether this error is transient and the operation may succeed on retry.
    public var isRetryable: Bool {
        switch self {
        case .networkError: return true
        case .assetIsNotReady: return true
        default: return false
        }
    }
}

public enum LocationPermissionType {
    case always
    case whenInUse
    case current
}

// Shared instance to be used by the SDK users
public let DashX = DashXClient.instance

public class DashXClient {
    public static let instance = DashXClient()

    /// Background queue for asset readiness polling (avoids tying retries to the main run loop).
    private static let assetPollQueue = DispatchQueue(label: "com.dashx.ios.assetPoll")

    // Single lock protecting all mutable identity / token state below.
    // Using NSLock (non-recursive) is safe here because no getter or setter
    // calls another guarded property while the lock is held.
    private let stateLock = NSLock()

    private var _accountAnonymousUid: String?
    private var accountAnonymousUid: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _accountAnonymousUid }
        set { stateLock.lock(); defer { stateLock.unlock() }; _accountAnonymousUid = newValue }
    }

    private var _accountUid: String?
    private var accountUid: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _accountUid }
        set { stateLock.lock(); defer { stateLock.unlock() }; _accountUid = newValue }
    }

    private var _apnsToken: String?
    private var apnsToken: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _apnsToken }
        set { stateLock.lock(); defer { stateLock.unlock() }; _apnsToken = newValue }
    }

    private var _fcmToken: String?
    private var fcmToken: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _fcmToken }
        set { stateLock.lock(); defer { stateLock.unlock() }; _fcmToken = newValue }
    }

    private var _mustSubscribe: Bool = false
    private var mustSubscribe: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _mustSubscribe }
        set { stateLock.lock(); defer { stateLock.unlock() }; _mustSubscribe = newValue }
    }

    private var _isAdTrackingRequested: Bool = false
    /// `true` after `enableAdTracking()` has been called. Read-only for external consumers.
    public private(set) var isAdTrackingRequested: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _isAdTrackingRequested }
        set { stateLock.lock(); defer { stateLock.unlock() }; _isAdTrackingRequested = newValue }
    }

    /// `trackMessage` calls that arrived before `configure(withPublicKey:)` set
    /// up the Apollo interceptor. Without the public-key header the backend
    /// returns "Permission denied" and the event is lost — a real problem for
    /// killed-state push-clicked tracking, where iOS delivers the response to
    /// `didReceive:` immediately on cold launch, often before the integrator's
    /// `configure()` has run. Flushed from `configure()`.
    private struct PendingTrackMessage {
        let id: String
        let status: DashXGql.TrackMessageStatus
        let timestamp: String
    }
    private var _pendingMessageTracking: [PendingTrackMessage] = []

    private init() {
        self.loadIdentity()
    }

    public func setAPNSToken(to: Data) {
        DashXLog.d(tag: #function, "APNS Token is \(to.string)")

        self.apnsToken = to.string
    }

    // https://stackoverflow.com/a/11197770
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    public func configure(
        withPublicKey publicKey: String,
        baseURI: String? = nil,
        targetEnvironment: String? = nil,
        libraryInfo: LibraryInfo? = nil
    ) {
        ConfigInterceptor.shared.publicKey = publicKey

        if let baseURI = baseURI {
            Network.shared.setBaseURI(to: baseURI)
        }

        if let targetEnvironment = targetEnvironment {
            ConfigInterceptor.shared.targetEnvironment = targetEnvironment
        }

        if let libraryInfo = libraryInfo {
            SystemContext.shared.setLibraryInfo(libraryInfo: libraryInfo)
        }

        flushPendingMessageTracking()
        EventQueue.shared.flush()
    }

    /// Drains the pre-configure trackMessage buffer. Called from `configure()`
    /// once `ConfigInterceptor.shared.publicKey` is set. Each buffered event
    /// goes through the normal `trackMessage` path — which now sees the
    /// public key and fires the Apollo request for real.
    private func flushPendingMessageTracking() {
        stateLock.lock()
        let pending = _pendingMessageTracking
        _pendingMessageTracking = []
        stateLock.unlock()
        guard !pending.isEmpty else { return }
        DashXLog.d(tag: #function, "Flushing \(pending.count) buffered trackMessage event(s) after configure()")
        for item in pending {
            trackMessage(item.id, item.status, item.timestamp, completion: nil)
        }
    }

    public func setFCMToken(to: String) {
        DashXLog.d(tag: #function, "FCM Token is \(to)")
        self.fcmToken = to

        if self.mustSubscribe {
            self.subscribe()
        }
    }

    public func enableLifecycleTracking() {
        DashXApplicationLifecycleCallbacks().enable()
    }

    // MARK: - Ad Tracking

    // Ad-tracking affects two keys under the systemContext object of every event:
    //
    // device.adTrackingEnabled
    // device.advertisingId
    // DashX will attempt to request IDFA permissions
    public func enableAdTracking() {
        self.isAdTrackingRequested = true
    }

    // MARK: - User Management

    private func loadIdentity() {
        let preferences = UserDefaults.standard

        self.accountUid = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        self.accountAnonymousUid = self.generateAnonymousUid()

        ConfigInterceptor.shared.identityToken = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
    }

    private func generateAnonymousUid(withRegenerate: Bool = false) -> String? {
        let preferences = UserDefaults.standard
        let anonymousUidKey = Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID
        let storedAnonymousUid = preferences.string(forKey: anonymousUidKey)

        if !withRegenerate, storedAnonymousUid != nil {
            return storedAnonymousUid
        } else {
            let uniqueIdentifier = UUID().uuidString
            preferences.set(uniqueIdentifier, forKey: anonymousUidKey)
            return uniqueIdentifier
        }
    }

    public func setIdentity(uid: String?, token: String?) {
        let preferences = UserDefaults.standard

        self.accountUid = uid
        if let uid = uid {
            preferences.set(uid, forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        } else {
            preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        }

        ConfigInterceptor.shared.identityToken = token
        if let token = token {
            preferences.set(token, forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        } else {
            preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        }
    }

    @available(*, deprecated, message: "Use identify(options:) instead")
    public func identify(withOptions: NSDictionary?) throws {
        guard let dict = withOptions as? [String: String] else {
            throw DashXClientError.noArgsInIdentify
        }
        identify(options: dict)
    }

    public func identify(options: [String: String], completion: ((Result<Void, Error>) -> Void)? = nil) {
        let uid = options[UserAttributes.UID] ?? self.accountUid
        let anonymousUid = options[UserAttributes.ANONYMOUS_UID] ?? self.accountAnonymousUid

        let identifyAccountInput = DashXGql.IdentifyAccountInput(
            uid: uid ?? .null,
            anonymousUid: anonymousUid ?? .null,
            email: options[UserAttributes.EMAIL] ?? .null,
            phone: options[UserAttributes.PHONE] ?? .null,
            name: options[UserAttributes.NAME] ?? .null,
            firstName: options[UserAttributes.FIRST_NAME] ?? .null,
            lastName: options[UserAttributes.LAST_NAME] ?? .null
        )

        let identifyAccountMutation = DashXGql.IdentifyAccountMutation(input: identifyAccountInput)

        Network.shared.apollo.perform(mutation: identifyAccountMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "GraphQL errors during identify(): \(errors)")
                    if let completion {
                        DispatchQueue.main.async { completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" }))) }
                    }
                    return
                }
                DashXLog.d(tag: #function, "Sent identify with \(String(describing: graphQLResult))")
                if let completion {
                    DispatchQueue.main.async { completion(.success(())) }
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during identify(): \(error)")
                if let completion {
                    DispatchQueue.main.async { completion(.failure(DashXClientError.networkError(underlying: error))) }
                }
            }
        }
    }

    public func reset() {
        unsubscribe()

        let preferences = UserDefaults.standard

        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_FCM_TOKEN)

        self.accountUid = nil
        self.accountAnonymousUid = self.generateAnonymousUid(withRegenerate: true)
        self.isAdTrackingRequested = false
        ConfigInterceptor.shared.identityToken = nil
    }

    // MARK: - Analytics

    /// Tracks an analytics event. When offline or on transport/GraphQL failure, the event may be persisted for retry.
    public func track(_ event: String, withData: [String: Any]? = nil) {
        track(
            event,
            withData: withData,
            queuedAccountUid: nil,
            queuedAccountAnonymousUid: nil,
            queuedTimestamp: nil,
            completion: nil
        )
    }

    /// - Parameters:
    ///   - queuedAccountUid: Identity captured when the event was queued; use for replay so changing `setIdentity` mid-queue does not corrupt payloads.
    ///   - queuedTimestamp: Wall-clock time when the event was originally enqueued. Preserves the historical timestamp when the queue flushes later.
    ///   - completion: Called on the main queue with `true` when the server accepted the mutation (no GraphQL errors, non-nil data).
    internal func track(
        _ event: String,
        withData: [String: Any]?,
        queuedAccountUid: String?,
        queuedAccountAnonymousUid: String?,
        queuedTimestamp: Date?,
        completion: ((Bool) -> Void)?
    ) {
        let effectiveAccountUid = queuedAccountUid ?? self.accountUid
        let effectiveAnonymousUid = queuedAccountAnonymousUid ?? self.accountAnonymousUid

        guard case .online = NetworkMonitor.shared.connection else {
            DashXLog.d(tag: #function, "Offline — queueing event '\(event)'")
            // When replaying from the disk queue (`completion != nil`), do not enqueue again.
            if completion == nil {
                EventQueue.shared.enqueue(
                    event: event,
                    data: withData,
                    accountUid: effectiveAccountUid,
                    accountAnonymousUid: effectiveAnonymousUid
                )
            }
            if let completion {
                DispatchQueue.main.async { completion(false) }
            }
            return
        }

        let systemContext = SystemContext.shared.getSystemContextInput()
        let dataJSON: GraphQLNullable<DashXGql.JSON>
        if let dict = withData {
            dataJSON = .some(Self.toJSONScalar(dict))
        } else {
            dataJSON = .null
        }

        // Use the queued event's original enqueue time when replaying, else stamp
        // "now". The server rejects track events without a top-level timestamp
        // (GraphQL `Validation failed`), and queued events should preserve their
        // original occurrence time rather than the flush time.
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: queuedTimestamp ?? Date())

        let trackEventInput = DashXGql.TrackEventInput(
            event: event,
            accountUid: effectiveAccountUid.map { .some($0) } ?? .null,
            accountAnonymousUid: effectiveAnonymousUid.map { .some($0) } ?? .null,
            data: dataJSON,
            timestamp: .some(timestamp),
            systemContext: systemContext.map { .some($0) } ?? .null
        )

        DashXLog.d(tag: #function, "Calling track with \(trackEventInput)")

        let trackEventMutation = DashXGql.TrackEventMutation(input: trackEventInput)

        Network.shared.apollo.perform(mutation: trackEventMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "GraphQL errors during track(): \(errors)")
                    self.handleTrackFailure(
                        event: event,
                        withData: withData,
                        accountUid: effectiveAccountUid,
                        accountAnonymousUid: effectiveAnonymousUid,
                        completion: completion
                    )
                    return
                }
                guard graphQLResult.data != nil else {
                    DashXLog.e(tag: #function, "track() succeeded but response data is nil")
                    self.handleTrackFailure(
                        event: event,
                        withData: withData,
                        accountUid: effectiveAccountUid,
                        accountAnonymousUid: effectiveAnonymousUid,
                        completion: completion
                    )
                    return
                }
                DashXLog.d(tag: #function, "Sent track with \(String(describing: graphQLResult.data))")
                if let completion {
                    DispatchQueue.main.async { completion(true) }
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during track(): \(error)")
                self.handleTrackFailure(
                    event: event,
                    withData: withData,
                    accountUid: effectiveAccountUid,
                    accountAnonymousUid: effectiveAnonymousUid,
                    completion: completion
                )
            }
        }
    }

    private func handleTrackFailure(
        event: String,
        withData: [String: Any]?,
        accountUid: String?,
        accountAnonymousUid: String?,
        completion: ((Bool) -> Void)?
    ) {
        if let completion {
            DispatchQueue.main.async { completion(false) }
        } else {
            EventQueue.shared.enqueue(
                event: event,
                data: withData,
                accountUid: accountUid,
                accountAnonymousUid: accountAnonymousUid
            )
        }
    }

    public func flushEventQueue() {
        EventQueue.shared.flush()
    }

    private func trackMessage(_ id: String, _ messageStatus: DashXGql.TrackMessageStatus, _ timeStamp: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        // If `configure(withPublicKey:)` hasn't run yet, the Apollo request
        // would go out with no `X-PUBLIC-KEY` header and the backend would
        // reject it with "Permission denied". That's the common case for
        // killed-state push `.clicked` / `.dismissed` tracking — iOS fires
        // `didReceive:` as part of the cold-launch before the integrator's
        // `configure()` runs. Buffer in memory and flush in `configure()`.
        if ConfigInterceptor.shared.publicKey == nil {
            stateLock.lock()
            _pendingMessageTracking.append(PendingTrackMessage(id: id, status: messageStatus, timestamp: timeStamp))
            stateLock.unlock()
            DashXLog.d(tag: #function, "Queued trackMessage(\(messageStatus.rawValue)) until configure()")
            // The only existing caller (DashXAppDelegate hooks + the RN
            // bridge's notification handler) passes `completion: nil`, so
            // there's no one waiting on the result. Silently defer.
            return
        }

        let trackMessageInput = DashXGql.TrackMessageInput(id: id,
                                                           status: GraphQLEnum<DashXGql.TrackMessageStatus>(messageStatus),
                                                           timestamp: timeStamp)

        DashXLog.d(tag: #function, "Calling trackMessage with \(trackMessageInput)")

        let trackMessageMutation = DashXGql.TrackMessageMutation(input: trackMessageInput)

        Network.shared.apollo.perform(mutation: trackMessageMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "GraphQL errors during trackMessage(): \(errors)")
                    if let completion {
                        DispatchQueue.main.async { completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" }))) }
                    }
                } else {
                    DashXLog.d(tag: #function, "Sent track Message with \(String(describing: graphQLResult.data))")
                    if let completion {
                        DispatchQueue.main.async { completion(.success(())) }
                    }
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during trackMessage(): \(error)")
                if let completion {
                    DispatchQueue.main.async { completion(.failure(DashXClientError.networkError(underlying: error))) }
                }
            }
        }
    }

    public func screen(_ screenName: String, withData: [String: Any]? = nil) {
        var properties = withData ?? [:]
        properties["name"] = screenName
        self.track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties)
    }

    // MARK: - Contact Management

    public func subscribe(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let fcmToken = self.fcmToken else {
            DashXLog.d(tag: #function, "'subscribe' called without fcmToken; returning...")
            self.mustSubscribe = true
            return
        }

        guard let anonymousUid = self.accountAnonymousUid else {
            DashXLog.d(tag: #function, "'subscribe' called without accountAnonymousUid; returning...")
            return
        }

        self.mustSubscribe = false

        let preferences = UserDefaults.standard
        let fcmTokenKey = Constants.USER_PREFERENCES_KEY_FCM_TOKEN

        if preferences.string(forKey: fcmTokenKey) == self.fcmToken {
            DashXLog.d(tag: #function, "Already subscribed: \(String(describing: self.fcmToken))")
            if let completion {
                DispatchQueue.main.async { completion(.success(())) }
            }
            return
        }

        var appDict: [String: AnyHashable] = [:]
        if let identifier = Bundle.main.bundleIdentifier {
            appDict["identifier"] = identifier
        }
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            appDict["name"] = appName
        }
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            appDict["version"] = appVersion
        }
        let metadata: [String: AnyHashable] = [
            "app": appDict,
            "library": [
                "name": Constants.LIBRARY_NAME,
                "version": Constants.PACKAGE_VERSION,
            ] as [String: AnyHashable],
        ]

        let subscribeContactInput = DashXGql.SubscribeContactInput(
            accountUid: self.accountUid.map { .some($0) } ?? .null,
            accountAnonymousUid: .some(anonymousUid),
            name: .some(UIDevice.current.model),
            kind: GraphQLEnum<DashXGql.ContactKind>(.ios),
            value: fcmToken,
            osName: .some(UIDevice.current.systemName),
            osVersion: .some(UIDevice.current.systemVersion),
            deviceModel: .some(self.getDeviceModel()),
            deviceManufacturer: .some("Apple"),
            metadata: .some(DashXGql.JSON(metadata))
        )

        DashXLog.d(tag: #function, "Calling subscribe with \(subscribeContactInput)")

        let subscribeContactMutation = DashXGql.SubscribeContactMutation(input: subscribeContactInput)

        Network.shared.apollo.perform(mutation: subscribeContactMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "Encountered GraphQL errors during subscribe(): \(errors)")
                    if let completion {
                        DispatchQueue.main.async { completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" }))) }
                    }
                    return
                }
                if graphQLResult.data != nil {
                    preferences.set(graphQLResult.data?.subscribeContact.value, forKey: fcmTokenKey)
                    DashXLog.d(tag: #function, "Sent subscribe with \(String(describing: graphQLResult))")
                    if let completion {
                        DispatchQueue.main.async { completion(.success(())) }
                    }
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during subscribe(): \(error)")
                if let completion {
                    DispatchQueue.main.async { completion(.failure(DashXClientError.networkError(underlying: error))) }
                }
            }
        }
    }

    public func unsubscribe(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        let preferences = UserDefaults.standard
        let fcmTokenKey = Constants.USER_PREFERENCES_KEY_FCM_TOKEN
        let savedToken = preferences.string(forKey: fcmTokenKey)

        guard let token = savedToken else {
            // No FCM token stored locally — nothing to tell the backend about.
            // Surface this as `success: false` (same semantics as the
            // backend's "no matching contact" path) so callers waiting on the
            // completion don't hang. Before this change, completion was
            // silently dropped here.
            DashXLog.d(tag: #function, "unsubscribe() called without subscribing first")
            if let completion {
                DispatchQueue.main.async { completion(.success(false)) }
            }
            return
        }

        guard let anonymousUid = self.accountAnonymousUid else {
            // Distinct from the no-saved-token guard above. Missing
            // `accountAnonymousUid` is a "shouldn't happen after configure()"
            // SDK-state problem — `generateAnonymousUid()` always produces a
            // value during configure() and the property is never written to
            // nil from anywhere else. If we hit this, the SDK was used
            // before `configure()` ran, so surface that as a real error
            // rather than squashing it into `success: false` (which is
            // reserved for the "no matching contact" non-error outcome).
            DashXLog.d(tag: #function, "'unsubscribe' called without accountAnonymousUid; returning...")
            if let completion {
                DispatchQueue.main.async {
                    completion(.failure(DashXClientError.customError(
                        message: "unsubscribe() called before configure() — no anonymous UID available"
                    )))
                }
            }
            return
        }

        // Snapshot the current accountUid alongside `token` and `anonymousUid`
        // so the closure below uses the identity at unsubscribe-call time.
        // Without this snapshot, the mutation reads `self.accountUid` lazily
        // inside the deleteToken callback — and if `reset()` (which calls
        // unsubscribe and then immediately wipes `self.accountUid`) is in
        // flight, the mutation would send `accountUid: null` and the backend
        // would fail to match a contact created during an identified session.
        let uidSnapshot = self.accountUid

        // Clear saved token immediately so subscribe() works on re-login
        // regardless of whether the server call succeeds.
        preferences.removeObject(forKey: fcmTokenKey)

        let performUnsubscribe = {
            let unsubscribeContactInput = DashXGql.UnsubscribeContactInput(
                accountUid: uidSnapshot.map { .some($0) } ?? .null,
                accountAnonymousUid: .some(anonymousUid),
                value: token
            )

            DashXLog.d(tag: #function, "Calling unsubscribe with \(unsubscribeContactInput)")

            let unsubscribeContactMutation = DashXGql.UnsubscribeContactMutation(input: unsubscribeContactInput)

            Network.shared.apollo.perform(mutation: unsubscribeContactMutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        DashXLog.e(tag: #function, "Encountered GraphQL errors during unsubscribe(): \(errors)")
                        if let completion {
                            DispatchQueue.main.async { completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" }))) }
                        }
                        return
                    }
                    // `success: false` is a valid non-error outcome meaning
                    // "no matching contact found to unsubscribe" — surface it
                    // to callers verbatim. Default to `false` if the response
                    // unexpectedly omits the field (shouldn't happen per
                    // schema, defensive).
                    let success = graphQLResult.data?.unsubscribeContact.success ?? false
                    DashXLog.d(tag: #function, "Sent unsubscribe (success=\(success))")
                    if let completion {
                        DispatchQueue.main.async { completion(.success(success)) }
                    }
                case .failure(let error):
                    DashXLog.e(tag: #function, "Encountered an error during unsubscribe(): \(error)")
                    if let completion {
                        DispatchQueue.main.async { completion(.failure(DashXClientError.networkError(underlying: error))) }
                    }
                }
            }
        }

        #if canImport(FirebaseMessaging)
        Messaging.messaging().deleteToken { _ in performUnsubscribe() }
        #else
        performUnsubscribe()
        #endif
    }

    // MARK: - Preferences

    public func fetchStoredPreferences(
        completion: @escaping (Result<[String: Any?], Error>) -> Void
    ) {
        guard let uid = self.accountUid else {
            completion(.failure(DashXClientError.notIdentified))
            return
        }

        let fetchStoredPreferencesInput = DashXGql.FetchStoredPreferencesInput(
            accountUid: uid
        )

        DashXLog.d(tag: #function, "Calling fetchStoredPreferences with \(fetchStoredPreferencesInput)")

        let fetchStoredPreferencesQuery = DashXGql.FetchStoredPreferencesQuery(input: fetchStoredPreferencesInput)

        Network.shared.apollo.fetch(query: fetchStoredPreferencesQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "Encountered GraphQL errors during fetchStoredPreferences(): \(errors)")
                    completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" })))
                    return
                }

                if let data = graphQLResult.data {
                    let jsonDict = data.fetchStoredPreferences.preferenceData
                    DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(jsonDict)")
                    completion(.success(Self.fromJSONScalar(jsonDict)))
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during fetchStoredPreferences(): \(error)")
                completion(.failure(error))
            }
        }
    }

    @available(*, deprecated, message: "Use fetchStoredPreferences(completion:) or async overload instead")
    public func fetchStoredPreferences(
        successCallback: @escaping (Any?) -> Void,
        failureCallback: @escaping (Error) -> Void
    ) {
        fetchStoredPreferences { result in
            switch result {
            case .success(let value): successCallback(value)
            case .failure(let error): failureCallback(error)
            }
        }
    }

    public func saveStoredPreferences(
        preferenceData: [String: Any],
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let uid = self.accountUid else {
            completion(.failure(DashXClientError.notIdentified))
            return
        }

        let saveStoredPreferencesInput = DashXGql.SaveStoredPreferencesInput(
            accountUid: uid,
            preferenceData: Self.toJSONScalar(preferenceData)
        )

        DashXLog.d(tag: #function, "Calling saveStoredPreferences with \(saveStoredPreferencesInput)")

        let saveStoredPreferencesMutation = DashXGql.SaveStoredPreferencesMutation(input: saveStoredPreferencesInput)

        Network.shared.apollo.perform(mutation: saveStoredPreferencesMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let success = graphQLResult.data?.saveStoredPreferences.success ?? false
                DashXLog.d(tag: #function, "Sent saveStoredPreferences with success=\(success)")
                completion(.success(success))
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during saveStoredPreferences(): \(error)")
                completion(.failure(error))
            }
        }
    }

    @available(*, deprecated, message: "Use saveStoredPreferences(preferenceData:completion:) or async overload instead")
    public func saveStoredPreferences(
        preferenceData: NSDictionary?,
        successCallback: @escaping (Any?) -> Void,
        failureCallback: @escaping (Error) -> Void
    ) {
        guard let dict = preferenceData as? [String: Any] else {
            failureCallback(DashXClientError.customError(message: "Invalid preference data"))
            return
        }
        saveStoredPreferences(preferenceData: dict) { result in
            switch result {
            case .success(let value): successCallback(value)
            case .failure(let error): failureCallback(error)
            }
        }
    }

    // MARK: - Records

    public func fetchRecord(
        urn: String,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [[String: Any]]? = nil,
        include: [[String: Any]]? = nil,
        exclude: [[String: Any]]? = nil,
        completion: @escaping (Result<[String: Any?], Error>) -> Void
    ) {
        let parts = urn.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2, UUID(uuidString: parts[1]) != nil else {
            completion(.failure(DashXClientError.customError(message: "URN must be of form: {resource}/{uuid}")))
            return
        }
        let recordId: DashXGql.UUID = parts[1]
        let input = DashXGql.FetchRecordInput(
            recordId: recordId,
            resource: parts[0].isEmpty ? .null : .some(parts[0]),
            preview: preview.map { .some($0) } ?? .null,
            language: language.map { .some($0) } ?? .null,
            fields: fields.map { .some($0.map(Self.toJSONScalar)) } ?? .null,
            include: include.map { .some($0.map(Self.toJSONScalar)) } ?? .null,
            exclude: exclude.map { .some($0.map(Self.toJSONScalar)) } ?? .null
        )
        Network.shared.apollo.fetch(query: DashXGql.FetchRecordQuery(input: input), cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "Encountered GraphQL errors during fetchRecord(): \(errors)")
                    completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" })))
                    return
                }
                if let data = graphQLResult.data {
                    DashXLog.d(tag: #function, "Sent fetchRecord with \(String(describing: data))")
                    completion(.success(Self.fromJSONScalar(data.fetchRecord)))
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during fetchRecord(): \(error)")
                completion(.failure(error))
            }
        }
    }

    public func searchRecords(
        resource: String,
        filter: [String: Any]? = nil,
        order: [[String: Any]]? = nil,
        limit: Int? = nil,
        page: Int? = nil,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [[String: Any]]? = nil,
        include: [[String: Any]]? = nil,
        exclude: [[String: Any]]? = nil,
        completion: @escaping (Result<[[String: Any?]], Error>) -> Void
    ) {
        let input = DashXGql.SearchRecordsInput(
            resource: resource,
            filter: filter.map { .some(Self.toJSONScalar($0)) } ?? .null,
            order: order.map { .some($0.map(Self.toJSONScalar)) } ?? .null,
            limit: limit.map { .some($0) } ?? .null,
            page: page.map { .some($0) } ?? .null,
            preview: preview.map { .some($0) } ?? .null,
            language: language.map { .some($0) } ?? .null,
            fields: fields.map { .some($0.map(Self.toJSONScalar)) } ?? .null,
            include: include.map { .some($0.map(Self.toJSONScalar)) } ?? .null,
            exclude: exclude.map { .some($0.map(Self.toJSONScalar)) } ?? .null
        )
        Network.shared.apollo.fetch(query: DashXGql.SearchRecordsQuery(input: input), cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    DashXLog.e(tag: #function, "Encountered GraphQL errors during searchRecords(): \(errors)")
                    completion(.failure(DashXClientError.graphQLErrors(errors.map { $0.message ?? "" })))
                    return
                }
                if let data = graphQLResult.data {
                    DashXLog.d(tag: #function, "Sent searchRecords with \(String(describing: data))")
                    completion(.success(data.searchRecords.map(Self.fromJSONScalar)))
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during searchRecords(): \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - File Uploads

    public func uploadAsset(
        fileURL: URL,
        resource: String,
        attribute: String,
        completion: @escaping (Result<AssetResponse, Error>) -> Void
    ) {
        self.prepareAsset(fileURL: fileURL, resource: resource, attribute: attribute) { prepareResult in
            switch prepareResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let prepareAssetResponse):
                guard let urlString = prepareAssetResponse.data?.upload?.url,
                      let assetId = prepareAssetResponse.id,
                      let url = URL(string: urlString)
                else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                    return
                }

                var uploadAssetRequest = URLRequest(url: url)
                uploadAssetRequest.httpMethod = HttpMethod.put.rawValue
                uploadAssetRequest.setValue(fileURL.mimeType(), forHTTPHeaderField: Constants.CONTENT_TYPE)
                uploadAssetRequest.setValue(prepareAssetResponse.data?.upload?.headers?[Constants.GCS_ASSET_UPLOAD_HEADER_KEY], forHTTPHeaderField: Constants.GCS_ASSET_UPLOAD_HEADER_KEY)

                do {
                    let fileData = try Data(contentsOf: fileURL)
                    URLSession.shared.uploadTask(with: uploadAssetRequest, from: fileData) { _, response, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                            completion(.failure(DashXClientError.assetIsNotUploaded))
                            return
                        }
                        self.pollTillAssetIsReady(triesLeft: Self.maxAssetPollRetries, assetId: assetId, completion: completion)
                    }.resume()
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    @available(*, deprecated, message: "Use uploadAsset(fileURL:resource:attribute:completion:) or async overload instead")
    public func uploadAsset(
        fileURL: URL,
        resource: String,
        attribute: String,
        successCallback: @escaping (Any?) -> Void,
        failureCallback: @escaping (Error) -> Void
    ) {
        uploadAsset(fileURL: fileURL, resource: resource, attribute: attribute) { result in
            switch result {
            case .success(let value): successCallback(value)
            case .failure(let error): failureCallback(error)
            }
        }
    }

    private func prepareAsset(
        fileURL: URL,
        resource: String,
        attribute: String,
        completion: @escaping (Result<PrepareAssetResponse, Error>) -> Void
    ) {
        let name = fileURL.lastPathComponent
        let mimeType = fileURL.mimeType()
        var size = 0

        do {
            let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            size = resources.fileSize ?? 0
        } catch {
            DashXLog.e(tag: #function, "Unable to get file size \(error)")
        }

        let prepareAssetInput = DashXGql.PrepareAssetInput(
            resource: .some(resource),
            attribute: .some(attribute),
            name: name,
            size: size,
            mimeType: mimeType
        )

        DashXLog.d(tag: #function, "Calling prepareAsset with \(prepareAssetInput)")

        let prepareAssetMutation = DashXGql.PrepareAssetMutation(input: prepareAssetInput)

        Network.shared.apollo.perform(mutation: prepareAssetMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let gqlResult = graphQLResult.data?.prepareAsset
                DashXLog.d(tag: #function, "Sent prepareAsset with \(String(describing: gqlResult))")
                guard let gqlResult else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                    return
                }
                // The `data` field comes back as a JSON object (see JSON.swift); bridge
                // it through JSONSerialization → JSONDecoder to populate ResponseAssetData.
                let responseAssetData: ResponseAssetData? = {
                    let anyDict: [String: Any] = (gqlResult.data.asDictionary ?? [:]).mapValues { $0.base }
                    guard let bytes = try? JSONSerialization.data(withJSONObject: anyDict) else { return nil }
                    return try? JSONDecoder().decode(ResponseAssetData.self, from: bytes)
                }()
                let response = PrepareAssetResponse(data: responseAssetData, id: gqlResult.id)
                completion(.success(response))
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during prepareAsset(): \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Maximum number of asset poll attempts and base interval (seconds) for exponential backoff.
    public static var maxAssetPollRetries: Int = 5
    public static var assetPollBaseInterval: TimeInterval = 2.0

    private func pollTillAssetIsReady(
        triesLeft: Int,
        assetId: String,
        completion: @escaping (Result<AssetResponse, Error>) -> Void
    ) {
        self.fetchAsset(assetId: assetId) { result in
            switch result {
            case .success(let response):
                if response.status == "ready" || triesLeft <= 0 {
                    completion(.success(response))
                } else {
                    let attempt = Self.maxAssetPollRetries - triesLeft
                    let delay = Self.assetPollBaseInterval * pow(2.0, Double(attempt))
                    let jitter = Double.random(in: 0...1)
                    let totalDelay = min(delay + jitter, 60)
                    DashXLog.d(tag: "pollTillAssetIsReady", "Retrying in \(String(format: "%.1f", totalDelay))s (attempt \(attempt + 1))")
                    Self.assetPollQueue.asyncAfter(deadline: .now() + totalDelay) {
                        self.pollTillAssetIsReady(triesLeft: triesLeft - 1, assetId: assetId, completion: completion)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func fetchAsset(
        assetId: String,
        completion: @escaping (Result<AssetResponse, Error>) -> Void
    ) {
        DashXLog.d(tag: #function, "Calling asset with \(assetId)")

        let assetQuery = DashXGql.AssetQuery(id: assetId)

        Network.shared.apollo.fetch(query: assetQuery) { result in
            switch result {
            case .success(let graphQLResult):
                let gqlResult = graphQLResult.data?.asset
                DashXLog.d(tag: #function, "Sent asset with \(String(describing: gqlResult))")
                guard let gqlResult else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                    return
                }
                // `data` arrives as a JSON object with the full AssetResponse payload
                // (status + nested asset object). Decode it, then backfill the mux
                // playback URL when only a `playbackIds` array is present.
                let anyDict: [String: Any] = (gqlResult.data.asDictionary ?? [:]).mapValues { $0.base }
                guard let bytes = try? JSONSerialization.data(withJSONObject: anyDict),
                      var response = try? JSONDecoder().decode(AssetResponse.self, from: bytes)
                else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                    return
                }
                if var assetData = response.data?.assetData,
                   assetData.url == nil,
                   let id = assetData.playbackIds?.first?.id {
                    assetData.url = generateMuxVideoUrl(playbackId: id)
                    response.data?.assetData = assetData
                }
                completion(.success(response))
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during asset(): \(error)")
                completion(.failure(error))
            }
        }
    }

    @available(*, deprecated, renamed: "fetchAsset(assetId:completion:)")
    public func asset(
        assetId: String,
        successCallback: @escaping (Any?) -> Void,
        failureCallback: @escaping (Error) -> Void
    ) {
        fetchAsset(assetId: assetId) { result in
            switch result {
            case .success(let value): successCallback(value)
            case .failure(let error): failureCallback(error)
            }
        }
    }

    // MARK: - Request pemissions for Notifications

    public func requestNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> ()) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { _, _ in

                // Get the full status of the permission (delivered on main queue).
                self.getNotificationPermissionStatus { permission in
                    completion(permission)
                }
            }
        )
    }

    public func getNotificationPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        })
    }

    // MARK: - Track Message

    /// Records a lifecycle event for a DashX-generated push notification.
    /// Takes the public `MessageTrackingEvent` enum rather than the internal
    /// `DashXGql.TrackMessageStatus` so that no Apollo-generated types leak
    /// into the consumer-facing `.swiftinterface`. Called by
    /// `DashXAppDelegate` (delivered / clicked / dismissed) and by the
    /// `@dashx/react-native` bridge for the same purpose.
    public func trackMessage(message: DashXNotificationMessage, event: MessageTrackingEvent, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if let id = message.dashxNotificationId() {
            self.trackMessage(id, event.gqlStatus, ISO8601DateFormatter.timeStamp, completion: completion)
        } else if let completion {
            DispatchQueue.main.async { completion(.failure(DashXClientError.customError(message: "Message does not contain a DashX notification ID"))) }
        }
    }

    // MARK: - Link Handling

    public var linkHandler: ((URL) -> Void)?

    /// Records a `dx_deep_link_opened` analytics event and optionally forwards the URL to ``linkHandler``.
    /// - Parameters:
    ///   - url: The opened deep link.
    ///   - source: Optional attribution (e.g. `universal_link`, `scene_url`, `notification`).
    ///   - forwardToLinkHandler: When `false`, only the analytics event is sent (e.g. rich landing handled separately).
    public func processURL(_ url: URL, source: String? = nil, forwardToLinkHandler: Bool = true) {
        var data: [String: Any] = [
            "url": url.absoluteString,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if let source {
            data["source"] = source
        }
        track(Constants.EVENT_DEEP_LINK_OPENED, withData: data)
        if forwardToLinkHandler {
            linkHandler?(url)
        }
    }

    /// Records a `dx_notification_navigated` event for every notification tap, regardless of navigation type.
    public func trackNotificationNavigation(_ action: NavigationAction?, notificationId: String?) {
        var data: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if let notificationId {
            data["notification_id"] = notificationId
        }
        switch action {
        case let .deepLink(url):
            data["type"] = "deep_link"
            data["url"] = url.absoluteString
        case let .screen(name, screenData):
            data["type"] = "screen"
            data["screen_name"] = name
            if let screenData {
                data["screen_data"] = screenData
            }
        case let .richLanding(url):
            data["type"] = "rich_landing"
            data["url"] = url.absoluteString
        case let .clickAction(action):
            data["type"] = "click_action"
            data["click_action"] = action
        case nil:
            data["type"] = "default"
        }
        track(Constants.EVENT_NOTIFICATION_NAVIGATED, withData: data)
    }

    public func handleUserActivity(userActivity: NSUserActivity?) {
        guard userActivity?.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity?.webpageURL else {
            return
        }
        processURL(url, source: "universal_link")
    }
}

// MARK: - async/await Overloads

extension DashXClient {
    public func fetchStoredPreferences() async throws -> [String: Any?] {
        try await withCheckedThrowingContinuation { continuation in
            fetchStoredPreferences { result in
                continuation.resume(with: result)
            }
        }
    }

    public func saveStoredPreferences(preferenceData: [String: Any]) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            saveStoredPreferences(preferenceData: preferenceData) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func uploadAsset(fileURL: URL, resource: String, attribute: String) async throws -> AssetResponse {
        try await withCheckedThrowingContinuation { continuation in
            uploadAsset(fileURL: fileURL, resource: resource, attribute: attribute) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func fetchAsset(assetId: String) async throws -> AssetResponse {
        try await withCheckedThrowingContinuation { continuation in
            fetchAsset(assetId: assetId) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func requestNotificationPermission() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestNotificationPermission { status in
                continuation.resume(returning: status)
            }
        }
    }

    public func getNotificationPermissionStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            getNotificationPermissionStatus { status in
                continuation.resume(returning: status)
            }
        }
    }

    public func fetchRecord(
        urn: String,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [[String: Any]]? = nil,
        include: [[String: Any]]? = nil,
        exclude: [[String: Any]]? = nil
    ) async throws -> [String: Any?] {
        try await withCheckedThrowingContinuation { continuation in
            fetchRecord(urn: urn, preview: preview, language: language,
                        fields: fields, include: include, exclude: exclude) {
                continuation.resume(with: $0)
            }
        }
    }

    public func searchRecords(
        resource: String,
        filter: [String: Any]? = nil,
        order: [[String: Any]]? = nil,
        limit: Int? = nil,
        page: Int? = nil,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [[String: Any]]? = nil,
        include: [[String: Any]]? = nil,
        exclude: [[String: Any]]? = nil
    ) async throws -> [[String: Any?]] {
        try await withCheckedThrowingContinuation { continuation in
            searchRecords(resource: resource, filter: filter, order: order, limit: limit, page: page,
                          preview: preview, language: language, fields: fields,
                          include: include, exclude: exclude) {
                continuation.resume(with: $0)
            }
        }
    }

    public func identify(options: [String: String]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            identify(options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    public func subscribe() async throws {
        try await withCheckedThrowingContinuation { continuation in
            subscribe { result in
                continuation.resume(with: result)
            }
        }
    }

    @discardableResult
    public func unsubscribe() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            unsubscribe { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - JSON / Dict helpers
    //
    // `DashXGql.JSON` is typealiased to `[String: AnyHashable]` (see
    // Sources/DashX/GraphQL/Schema/CustomScalars/JSON.swift) so the scalar lands
    // on the wire as an actual JSON object — the backend resolver for
    // `track_event` (and other inputs) validates `data.is_object()` and rejects
    // stringified JSON. The helpers below coerce between the caller's looser
    // `[String: Any]` / `[String: Any?]` shapes and the scalar's `AnyHashable`
    // shape, silently dropping values that can't be hashed.

    static func toJSONScalar(_ dict: [String: Any]) -> DashXGql.JSON {
        let hashableDict: [String: AnyHashable] = dict.reduce(into: [:]) { acc, pair in
            if let hashable = pair.value as? AnyHashable {
                acc[pair.key] = hashable
            }
        }
        return DashXGql.JSON(hashableDict)
    }

    static func fromJSONScalar(_ json: DashXGql.JSON) -> [String: Any?] {
        (json.asDictionary ?? [:]).mapValues { $0.base }
    }
}
