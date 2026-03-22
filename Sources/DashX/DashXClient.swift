import Apollo
#if canImport(ApolloAPI)
import ApolloAPI
#endif
import AppTrackingTransparency
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif
import Foundation
import UIKit

@available(*, deprecated, message: "Use Result-based or async/await overloads instead")
public typealias SuccessCallback = (Any?) -> ()

@available(*, deprecated, message: "Use Result-based or async/await overloads instead")
public typealias FailureCallback = (Error) -> ()

public enum DashXClientError: Error {
    case noArgsInIdentify
    case assetIsNotReady
    case assetIsNotUploaded
    case customError(message: String)
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

    private var _shouldRequestIDFAPermissions: Bool = false
    internal var shouldRequestIDFAPermissions: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _shouldRequestIDFAPermissions }
        set { stateLock.lock(); defer { stateLock.unlock() }; _shouldRequestIDFAPermissions = newValue }
    }

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

        EventQueue.shared.flush()
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
        self.shouldRequestIDFAPermissions = true
    }

    // MARK: - User Management

    private func loadIdentity() {
        let preferences = UserDefaults.standard

        self.accountUid = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        self.accountAnonymousUid = self.generateAnonymousUid()

        // Not setting this for now.
        // ConfigInterceptor.shared.identityToken = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
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

    public func setIdentity(uid: String, token: String) {
        let preferences = UserDefaults.standard

        self.accountUid = uid
        preferences.set(self.accountUid, forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)

        // Not setting this for now.
        // ConfigInterceptor.shared.identityToken = token
        // preferences.set(token, forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
    }

    @available(*, deprecated, message: "Use identify(options:) instead")
    public func identify(withOptions: NSDictionary?) throws {
        guard let dict = withOptions as? [String: String] else {
            throw DashXClientError.noArgsInIdentify
        }
        identify(options: dict)
    }

    public func identify(options: [String: String]) {
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
                DashXLog.d(tag: #function, "Sent identify with \(String(describing: graphQLResult))")
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during identify(): \(error)")
            }
        }
    }

    public func reset() {
        let preferences = UserDefaults.standard

        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)

        self.accountUid = nil
        self.accountAnonymousUid = self.generateAnonymousUid(withRegenerate: true)
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
            completion: nil
        )
    }

    /// - Parameters:
    ///   - queuedAccountUid: Identity captured when the event was queued; use for replay so changing `setIdentity` mid-queue does not corrupt payloads.
    ///   - completion: Called on the main queue with `true` when the server accepted the mutation (no GraphQL errors, non-nil data).
    internal func track(
        _ event: String,
        withData: [String: Any]?,
        queuedAccountUid: String?,
        queuedAccountAnonymousUid: String?,
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
            dataJSON = .some(DashXGql.JSON(dict))
        } else {
            dataJSON = .null
        }
        let trackEventInput = DashXGql.TrackEventInput(
            event: event,
            accountUid: (effectiveAccountUid != nil) ? .some(effectiveAccountUid!) : .null,
            accountAnonymousUid: (effectiveAnonymousUid != nil) ? .some(effectiveAnonymousUid!) : .null,
            data: dataJSON,
            systemContext: (systemContext != nil) ? .some(systemContext!) : .null
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

    private func trackMessage(_ id: String, _ messageStatus: DashXGql.TrackMessageStatus, _ timeStamp: String) {
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
                } else {
                    DashXLog.d(tag: #function, "Sent track Message with \(String(describing: graphQLResult.data))")
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during trackMessage(): \(error)")
            }
        }
    }

    public func screen(_ screenName: String, withData: [String: Any]? = nil) {
        var properties = withData ?? [:]
        properties["name"] = screenName
        self.track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties)
    }

    // MARK: - Contact Management

    public func subscribe() {
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
            return
        }

        let subscribeContactInput = DashXGql.SubscribeContactInput(
            accountUid: (self.accountUid != nil) ? .some(self.accountUid!) : .null,
            accountAnonymousUid: .some(anonymousUid),
            name: .some(UIDevice.current.model),
            kind: GraphQLEnum<DashXGql.ContactKind>(.ios),
            value: fcmToken,
            osName: .some(UIDevice.current.systemName),
            osVersion: .some(UIDevice.current.systemVersion),
            deviceModel: .some(self.getDeviceModel()),
            deviceManufacturer: .some("Apple")
        )

        DashXLog.d(tag: #function, "Calling subscribe with \(subscribeContactInput)")

        let subscribeContactMutation = DashXGql.SubscribeContactMutation(input: subscribeContactInput)

        Network.shared.apollo.perform(mutation: subscribeContactMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if graphQLResult.errors != nil {
                    DashXLog.e(tag: #function, "Encountered GraphQL errors during subscribe(): \(String(describing: graphQLResult.errors))")
                }

                if graphQLResult.data != nil {
                    preferences.set(graphQLResult.data?.subscribeContact.value, forKey: fcmTokenKey)
                    DashXLog.d(tag: #function, "Sent subscribe with \(String(describing: graphQLResult))")
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during subscribe(): \(error)")
            }
        }
    }

    public func unsubscribe() {
        let preferences = UserDefaults.standard
        let fcmTokenKey = Constants.USER_PREFERENCES_KEY_FCM_TOKEN
        let savedToken = preferences.string(forKey: fcmTokenKey)

        guard let token = savedToken else {
            DashXLog.d(tag: #function, "unsubscribe() called without subscribing first")
            return
        }

        guard let anonymousUid = self.accountAnonymousUid else {
            DashXLog.d(tag: #function, "'unsubscribe' called without accountAnonymousUid; returning...")
            return
        }

        let performUnsubscribe = {
            let unsubscribeContactInput = DashXGql.UnsubscribeContactInput(
                accountUid: (self.accountUid != nil) ? .some(self.accountUid!) : .null,
                accountAnonymousUid: .some(anonymousUid),
                value: token
            )

            DashXLog.d(tag: #function, "Calling unsubscribe with \(unsubscribeContactInput)")

            let unsubscribeContactMutation = DashXGql.UnsubscribeContactMutation(input: unsubscribeContactInput)

            Network.shared.apollo.perform(mutation: unsubscribeContactMutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.errors != nil {
                        DashXLog.e(tag: #function, "Encountered GraphQL errors during unsubscribe(): \(String(describing: graphQLResult.errors))")
                    }

                    if graphQLResult.data != nil {
                        preferences.set(graphQLResult.data?.unsubscribeContact.value, forKey: fcmTokenKey)
                        DashXLog.d(tag: #function, "Sent unsubscribe with \(String(describing: graphQLResult))")
                    }
                case .failure(let error):
                    DashXLog.e(tag: #function, "Encountered an error during unsubscribe(): \(error)")
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
            completion(.failure(DashXClientError.customError(message: "No account UID set")))
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
                    completion(.failure(DashXClientError.customError(message: "Unable to fetch stored preferences")))
                    return
                }

                if let data = graphQLResult.data {
                    let json = data.fetchStoredPreferences.preferenceData
                    DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(String(describing: json))")
                    completion(.success(json.value))
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
            completion(.failure(DashXClientError.customError(message: "No account UID set")))
            return
        }

        let saveStoredPreferencesInput = DashXGql.SaveStoredPreferencesInput(
            accountUid: uid,
            preferenceData: DashXGql.JSON(preferenceData)
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
                        self.pollTillAssetIsReady(triesLeft: 5, assetId: assetId, completion: completion)
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
                if let gqlResult = gqlResult, let jsonDictionary = gqlResult.resultMap as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary)
                        let data = try JSONDecoder().decode(PrepareAssetResponse.self, from: jsonData)
                        completion(.success(data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                }
            case .failure(let error):
                DashXLog.e(tag: #function, "Encountered an error during prepareAsset(): \(error)")
                completion(.failure(error))
            }
        }
    }

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
                    Self.assetPollQueue.asyncAfter(deadline: .now() + 3) {
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
                if let gqlResult = gqlResult, let jsonDictionary = gqlResult.resultMap as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary)
                        var data = try JSONDecoder().decode(AssetResponse.self, from: jsonData)
                        if var assetData = data.data?.assetData,
                           assetData.url == nil,
                           let id = assetData.playbackIds?.first?.id
                        {
                            assetData.url = generateMuxVideoUrl(playbackId: id)
                            data.data?.assetData = assetData
                        }
                        completion(.success(data))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(DashXClientError.assetIsNotUploaded))
                }
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

    public func trackMessage(message: DashXNotificationMessage, event: DashXGql.TrackMessageStatus) {
        if let id = message.dashxNotificationId() {
            self.trackMessage(id, event, ISO8601DateFormatter.timeStamp)
        }
    }

    // MARK: - Link Handling

    public var linkHandler: ((URL) -> Void)?

    public func handleUserActivity(userActivity: NSUserActivity?) {
        guard userActivity?.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity?.webpageURL else {
            return
        }
        linkHandler?(url)
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
}
