import Apollo
import CoreLocation
import FirebaseMessaging
import Foundation
import UIKit

public typealias SuccessCallback = (Any?) -> ()
public typealias FailureCallback = (Error) -> ()

enum DashXClientError: Error {
    case noArgsInIdentify
    case assetIsNotReady
    case assetIsNotUploaded
    case customError(message: String)
}

// Shared instance to be used by the SDK users
public let DashX = DashXClient.instance

public class DashXClient {
    static let instance = DashXClient()

    private var accountAnonymousUid: String?
    private var accountUid: String?
    private var deviceToken: String?

    private var mustSubscribe: Bool = false

    private init() {
        self.loadIdentity()
    }

    internal func setDeviceToken(to: String) {
        self.deviceToken = to

        if self.mustSubscribe {
            self.subscribe()
        }
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
    }

    public func enableLifecycleTracking() {
        DashXApplicationLifecycleCallbacks().enable()
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

    public func identify(withOptions: NSDictionary?) throws {
        if withOptions == nil {
            throw DashXClientError.noArgsInIdentify
        }

        let optionsDictionary = withOptions as? [String: String]

        let uid = optionsDictionary?[UserAttributes.UID] ?? self.accountUid

        let anonymousUid = optionsDictionary?[UserAttributes.ANONYMOUS_UID] ?? self.accountAnonymousUid

        let identifyAccountInput = DashXGql.IdentifyAccountInput(
            uid: uid,
            anonymousUid: anonymousUid,
            email: optionsDictionary?[UserAttributes.EMAIL],
            phone: optionsDictionary?[UserAttributes.PHONE],
            name: optionsDictionary?[UserAttributes.NAME],
            firstName: optionsDictionary?[UserAttributes.FIRST_NAME],
            lastName: optionsDictionary?[UserAttributes.LAST_NAME]
        )

        let identifyAccountMutation = DashXGql.IdentifyAccountMutation(input: identifyAccountInput)

        Network.shared.apollo.perform(mutation: identifyAccountMutation) { result in
            switch result {
            case .success(let graphQLResult):
                DashXLog.d(tag: #function, "Sent identify with \(String(describing: graphQLResult))")
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during identify(): \(error)")
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

    public func track(_ event: String, withData: NSDictionary? = nil) {
        let systemContext = SystemContext.shared.getSystemContextInput()
        let trackEventInput = DashXGql.TrackEventInput(
            event: event,
            accountUid: self.accountUid,
            accountAnonymousUid: self.accountAnonymousUid,
            data: withData as? [String: JSONDecodable?],
            systemContext: systemContext
        )

        DashXLog.d(tag: #function, "Calling track with \(trackEventInput)")

        let trackEventMutation = DashXGql.TrackEventMutation(input: trackEventInput)

        Network.shared.apollo.perform(mutation: trackEventMutation) { result in
            switch result {
            case .success(let graphQLResult):
                DashXLog.d(tag: #function, "Sent track with \(String(describing: graphQLResult.data))")
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during track(): \(error)")
            }
        }
    }
    
    public func trackNotification(_ id: String, _ notificationStatus: DashXGql.TrackNotificationStatus, _ timeStamp: String) {
        let trackNotificationInput = DashXGql.TrackNotificationInput(id: id,
                                                                     status: notificationStatus,
                                                                     timestamp: timeStamp)
        
        DashXLog.d(tag: #function, "Calling trackNotification with \(trackNotificationInput)")
        
        let trackNotificationMutation = DashXGql.TrackNotificationMutation(input: trackNotificationInput)
        
        Network.shared.apollo.perform(mutation: trackNotificationMutation) { result in
            switch result {
            case .success(let graphQLResult):
                DashXLog.d(tag: #function, "Sent track Notification with \(String(describing: graphQLResult.data))")
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during trackNotification(): \(error)")
            }
        }
    }

    public func screen(_ screenName: String, withData: NSDictionary?) {
        let properties = withData as? [String: Any]

        self.track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties?.merging(["name": screenName], uniquingKeysWith: { _, new in new }) as NSDictionary?)
    }

    // MARK: - Contact Management

    public func subscribe() {
        if self.deviceToken == nil {
            self.mustSubscribe = true
            return
        }

        self.mustSubscribe = false

        let preferences = UserDefaults.standard
        let deviceTokenKey = Constants.USER_PREFERENCES_KEY_DEVICE_TOKEN

        if preferences.string(forKey: deviceTokenKey) == self.deviceToken {
            DashXLog.d(tag: #function, "Already subscribed: \(String(describing: self.deviceToken))")
            return
        }

        let subscribeContactInput = DashXGql.SubscribeContactInput(
            accountUid: self.accountUid,
            accountAnonymousUid: self.accountAnonymousUid!,
            name: UIDevice.current.model,
            kind: .ios,
            value: self.deviceToken!,
            osName: UIDevice.current.systemName,
            osVersion: UIDevice.current.systemVersion,
            deviceModel: self.getDeviceModel(),
            deviceManufacturer: "Apple"
        )

        DashXLog.d(tag: #function, "Calling subscribe with \(subscribeContactInput)")

        let subscribeContactMutation = DashXGql.SubscribeContactMutation(input: subscribeContactInput)

        Network.shared.apollo.perform(mutation: subscribeContactMutation) { result in
            switch result {
            case .success(let graphQLResult):
                if graphQLResult.errors != nil {
                    DashXLog.d(tag: #function, "Encountered GraphQL errors during subscribe(): \(String(describing: graphQLResult.errors))")
                }

                if graphQLResult.data != nil {
                    preferences.set(graphQLResult.data?.subscribeContact.value, forKey: deviceTokenKey)
                    DashXLog.d(tag: #function, "Sent subscribe with \(String(describing: graphQLResult))")
                }
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during subscribe(): \(error)")
            }
        }
    }

    public func unsubscribe() {
        let preferences = UserDefaults.standard
        let deviceTokenKey = Constants.USER_PREFERENCES_KEY_DEVICE_TOKEN
        let savedToken = preferences.string(forKey: deviceTokenKey)

        if savedToken == nil {
            DashXLog.d(tag: #function, "unsubscribe() called without subscribing first")
            return
        }

        Messaging.messaging().deleteToken { result in
            let unsubscribeContactInput = DashXGql.UnsubscribeContactInput(
                accountUid: self.accountUid,
                accountAnonymousUid: self.accountAnonymousUid!,
                value: self.deviceToken!
            )

            DashXLog.d(tag: #function, "Calling unsubscribe with \(unsubscribeContactInput)")

            let unsubscribeContactMutation = DashXGql.UnsubscribeContactMutation(input: unsubscribeContactInput)

            Network.shared.apollo.perform(mutation: unsubscribeContactMutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.errors != nil {
                        DashXLog.d(tag: #function, "Encountered GraphQL errors during unsubscribe(): \(String(describing: graphQLResult.errors))")
                    }

                    if graphQLResult.data != nil {
                        preferences.set(graphQLResult.data?.unsubscribeContact.value, forKey: deviceTokenKey)
                        DashXLog.d(tag: #function, "Sent unsubscribe with \(String(describing: graphQLResult))")
                    }
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during unsubscribe(): \(error)")
                }
            }
        }
    }

    // MARK: - Preferences

    public func fetchStoredPreferences(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.accountUid else { return }

        let fetchStoredPreferencesInput = DashXGql.FetchStoredPreferencesInput(
            accountUid: uid
        )

        DashXLog.d(tag: #function, "Calling fetchStoredPreferences with \(fetchStoredPreferencesInput)")

        let fetchStoredPreferencesQuery = DashXGql.FetchStoredPreferencesQuery(input: fetchStoredPreferencesInput)

        Network.shared.apollo.fetch(query: fetchStoredPreferencesQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if graphQLResult.errors != nil {
                    DashXLog.d(tag: #function, "Encountered GraphQL errors during fetchStoredPreferences(): \(String(describing: graphQLResult.errors))")
                    failureCallback(DashXClientError.customError(message: "Unable to fetch stored preferences"))
                }

                if graphQLResult.data != nil {
                    let json = graphQLResult.data?.fetchStoredPreferences.preferenceData
                    DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(String(describing: json))")
                    successCallback(json)
                }
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during fetchStoredPreferences(): \(error)")
                failureCallback(error)
            }
        }
    }

    public func saveStoredPreferences(
        preferenceData: NSDictionary?,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.accountUid else { return }

        guard let preferenceData = preferenceData as? [String: Any] else { return }

        let saveStoredPreferencesInput = DashXGql.SaveStoredPreferencesInput(accountUid: uid, preferenceData: preferenceData)

        DashXLog.d(tag: #function, "Calling saveStoredPreferences with \(saveStoredPreferencesInput)")

        let saveStoredPreferencesMutation = DashXGql.SaveStoredPreferencesMutation(input: saveStoredPreferencesInput)

        Network.shared.apollo.perform(mutation: saveStoredPreferencesMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.saveStoredPreferences
                DashXLog.d(tag: #function, "Sent saveStoredPreferences with \(String(describing: json))")
                successCallback(json?.resultMap)
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during saveStoredPreferences(): \(error)")
                failureCallback(error)
            }
        }
    }

    // MARK: - Billing

    public func addItemToCart(
        itemId: String,
        pricingId: String,
        quantity: String,
        reset: Bool,
        custom: NSDictionary?,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let addItemToCartInput = DashXGql.AddItemToCartInput(
            accountUid: self.accountUid, accountAnonymousUid: self.accountAnonymousUid, itemId: itemId, pricingId: pricingId, quantity: quantity, reset: reset, custom: custom as? [String: JSONDecodable?]
        )

        DashXLog.d(tag: #function, "Calling addItemToCart with \(addItemToCartInput)")

        let addItemToCartMutation = DashXGql.AddItemToCartMutation(input: addItemToCartInput)

        Network.shared.apollo.perform(mutation: addItemToCartMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.addItemToCart
                DashXLog.d(tag: #function, "Sent addItemToCart with \(String(describing: json))")
                successCallback(json?.resultMap)
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during addItemToCart(): \(error)")
                failureCallback(error)
            }
        }
    }

    public func fetchCart(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let fetchCartInput = DashXGql.FetchCartInput(
            accountUid: self.accountUid, accountAnonymousUid: self.accountAnonymousUid
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
    }

    // MARK: - File Uploads

    public func uploadAsset(
        fileURL: URL,
        resource: String,
        attribute: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        self.prepareAsset(fileURL: fileURL, resource: resource, attribute: attribute) { response in
            if let prepareAssetResponse = response as? PrepareAssetResponse,
               let urlString = prepareAssetResponse.data?.upload?.url,
               let assetId = prepareAssetResponse.id,
               let url = URL(string: urlString)
            {
                var uploadAssetRequest = URLRequest(url: url)
                uploadAssetRequest.httpMethod = HttpMethod.put.rawValue
                uploadAssetRequest.setValue(fileURL.mimeType(), forHTTPHeaderField: Constants.CONTENT_TYPE)
                uploadAssetRequest.setValue(prepareAssetResponse.data?.upload?.headers?[Constants.GCS_ASSET_UPLOAD_HEADER_KEY], forHTTPHeaderField: Constants.GCS_ASSET_UPLOAD_HEADER_KEY)

                do {
                    let fileData = try Data(contentsOf: fileURL)
                    URLSession.shared.uploadTask(with: uploadAssetRequest, from: fileData) { _, response, error in
                        guard error == nil else {
                            return failureCallback(error!)
                        }
                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                            return failureCallback(DashXClientError.assetIsNotUploaded)
                        }
                        self.pollTillAssetIsReady(trysLeft: 5, assetId: assetId) { response in
                            successCallback(response)
                        } failureCallback: { error in
                            failureCallback(error)
                        }
                    }.resume()
                } catch {
                    failureCallback(error)
                }
            } else {
                failureCallback(DashXClientError.assetIsNotUploaded)
            }
        } failureCallback: { error in
            failureCallback(error)
        }
    }

    private func prepareAsset(
        fileURL: URL,
        resource: String,
        attribute: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let name = fileURL.lastPathComponent
        let mimeType = fileURL.mimeType()
        var size = 0

        do {
            let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            size = resources.fileSize!
        } catch {
            DashXLog.d(tag: #function, "Unable to get file size \(error)")
        }

        let prepareAssetInput = DashXGql.PrepareAssetInput(
            resource: resource,
            attribute: attribute,
            name: name,
            size: size,
            mimeType: mimeType
        )

        DashXLog.d(tag: #function, "Calling prepareAsset with \(prepareAssetInput)")

        let prepareAssetMutation = DashXGql.PrepareAssetMutation(input: prepareAssetInput)

        Network.shared.apollo.perform(mutation: prepareAssetMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.prepareAsset
                DashXLog.d(tag: #function, "Sent prepareAsset with \(String(describing: json))")
                if let jsonDictionary = json?.resultMap.jsonValue as? [String: Any] {
                    do {
                        let json = try JSONSerialization.data(withJSONObject: jsonDictionary)
                        let data = try JSONDecoder().decode(PrepareAssetResponse.self, from: json)
                        successCallback(data)
                    } catch {
                        failureCallback(error)
                    }
                } else {
                    failureCallback(DashXClientError.assetIsNotUploaded)
                }
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during prepareAsset(): \(error)")
                failureCallback(error)
            }
        }
    }

    private func pollTillAssetIsReady(
        trysLeft: Int,
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        self.asset(assetId: assetId) { response in
            if let response = response as? AssetResponse,
               let status = response.status
            {
                if status == "ready" || trysLeft == 0 {
                    successCallback(response)
                } else {
                    _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                        self.pollTillAssetIsReady(trysLeft: trysLeft - 1, assetId: assetId, successCallback: successCallback, failureCallback: failureCallback)
                    }
                }
            }
        } failureCallback: { error in
            failureCallback(error)
        }
    }

    public func asset(
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        DashXLog.d(tag: #function, "Calling asset with \(assetId)")

        let assetQuery = DashXGql.AssetQuery(id: assetId)

        Network.shared.apollo.fetch(query: assetQuery) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.asset
                DashXLog.d(tag: #function, "Sent asset with \(String(describing: json))")
                if let jsonDictionary = json?.resultMap.jsonValue as? [String: Any] {
                    do {
                        let json = try JSONSerialization.data(withJSONObject: jsonDictionary)
                        var data = try JSONDecoder().decode(AssetResponse.self, from: json)
                        if var assetData = data.data?.assetData,
                           assetData.url == nil,
                           let id = assetData.playbackIds?.first?.id
                        {
                            assetData.url = generateMuxVideoUrl(playbackId: id)
                            data.data?.assetData = assetData
                        }
                        successCallback(data)
                    } catch {
                        failureCallback(error)
                    }
                } else {
                    failureCallback(DashXClientError.assetIsNotUploaded)
                }
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during asset(): \(error)")
                failureCallback(error)
            }
        }
    }

    // MARK: - Request pemissions for Notifications

    public func requestNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> ()) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { _, _ in

                // Get the full status of the permission
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

    // MARK: - Request permission for Location

    public func requestLocationPermission() {
        CLLocationManager().requestWhenInUseAuthorization()
    }
    
    // MARK: - Get ID of Notification
    
    public func getNotificationID(_ message: [AnyHashable : Any]) -> String? {
        if let theJSONString = message["dashx"] as? String,
           let theJSONData = theJSONString.convertToDictionary(),
           let id = theJSONData["id"] as? String {
            return id
        }
        return nil
    }
}
