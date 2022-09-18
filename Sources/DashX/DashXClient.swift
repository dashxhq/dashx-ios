import Foundation
import Combine
import UIKit

// MARK: Types
public typealias SuccessCallback =  (Any?) -> ()
public typealias FailureCallback = (Error) -> ()

enum DashXClientError: Error {
    case noArgsInIdentify
    case assetIsNotReady
    case assetIsNotUploaded
}

// Shared instance to be used by the SDK users
public let DashX = DashXClient.instance

public class DashXClient {
    static let instance = DashXClient()
    
    private var accountAnonymousUid: String?
    private var accountUid: String?
    private var deviceToken: String?
    
    private var mustSubscribe: Bool = false
    
    private var bag = Set<AnyCancellable>()
    
    private init() {
        loadIdentity()
    }
    
    public func configure(
        withPublicKey publicKey: String,
        baseURI: String? = nil,
        targetEnvironment: String? = nil
    ) {
        DashXAppDelegate.swizzleDidReceiveRemoteNotificationFetchCompletionHandler()
        
        if let urlString = baseURI,
           let baseURL = URL(string: urlString) {
            Network.shared.setBaseURL(to: baseURL)
        }
        
        Network.shared.setPublicKey(to: publicKey)
        
        Network.shared.setTargetEnvironment(to: targetEnvironment)
    }
    
    public func setIdentity(uid: String, token: String) {
        let preferences = UserDefaults.standard
        
        self.accountUid = uid
        preferences.set(self.accountUid, forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        
        // Not setting this for now.
        // Network.shared.setIdentityToken(to: token)
        // preferences.set(token, forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
    }
    
    private func setDeviceToken(to: String) {
        self.deviceToken = to
        
        if (self.mustSubscribe) {
            self.subscribe()
        }
    }
    
    private func generateAnonymousUid(withRegenerate: Bool = false) -> String? {
        let preferences = UserDefaults.standard
        let anonymousUidKey = Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID
        let storedAnonymousUid = preferences.string(forKey: anonymousUidKey)
        
        if !withRegenerate && storedAnonymousUid != nil {
            return storedAnonymousUid
        } else {
            let uniqueIdentifier = UUID().uuidString
            preferences.set(uniqueIdentifier, forKey: anonymousUidKey)
            return uniqueIdentifier
        }
    }
    
    func loadIdentity() {
        let preferences = UserDefaults.standard
        
        self.accountUid = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        self.accountAnonymousUid = generateAnonymousUid()
        
        // Not setting this for now.
        // Network.shared.setIdentityToken(to: preferences.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN))
    }
    
    public func reset() {
        let preferences = UserDefaults.standard
        
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        
        self.accountUid = nil
        self.accountAnonymousUid = self.generateAnonymousUid(withRegenerate: true)
        Network.shared.setIdentityToken(to: nil)
    }
    
    public func screen(_ screenName: String, withData: NSDictionary?) {
        let properties = withData as? [String: Any]
        
        track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties?.merging([ "name": screenName], uniquingKeysWith: { (_, new) in new }) as NSDictionary?)
    }
    
    // https://stackoverflow.com/a/11197770
    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    // MARK: -- identify
    
    public func identify(withOptions: NSDictionary?) throws {
        if withOptions == nil {
            throw DashXClientError.noArgsInIdentify
        }
        
        let optionsDictionary = withOptions as? [String: String]
        
        let uid = optionsDictionary?[UserAttributes.UID] ?? self.accountUid
        
        let anonymousUid = optionsDictionary?[UserAttributes.ANONYMOUS_UID] ?? self.accountAnonymousUid
        
        let identifyAccountInput = IdentifyAccountModel.input(
            uid: uid,
            anonymousUid: anonymousUid,
            email: optionsDictionary?[UserAttributes.EMAIL],
            phone: optionsDictionary?[UserAttributes.PHONE],
            name: optionsDictionary?[UserAttributes.NAME],
            firstName: optionsDictionary?[UserAttributes.FIRST_NAME],
            lastName: optionsDictionary?[UserAttributes.LAST_NAME]
        )
        
        DashXLog.d(tag: #function, "Calling identifyAccount with \(identifyAccountInput)")
        
        let identifyAccountMutation = IdentifyAccountModel.mutation(input: identifyAccountInput)
        
        Network.shared.client.mutate(identifyAccountMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during identify(): \(error)")
                    break
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent identify with \(value)")
            }
            .store(in: &bag)
        
    }
    
    // MARK: -- track
    
    public func track(_ event: String, withData: NSDictionary? = nil) {
        let trackEventInput = TrackEventModel.input(
            event: event,
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid,
            data: withData
        )
        
        DashXLog.d(tag: #function, "Calling track with \(trackEventInput)")
        
        let trackEventMutation = TrackEventModel.mutation(input: trackEventInput)
        
        Network.shared.client.mutate(trackEventMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during track(): \(error)")
                    break
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent track with \(value)")
            }
            .store(in: &bag)
    }
    
    // MARK: -- subscribe
    
    public func subscribe() {
        if deviceToken == nil {
            self.mustSubscribe = true
            return
        }
        
        self.mustSubscribe = false
        
        let preferences = UserDefaults.standard
        let deviceTokenKey = Constants.USER_PREFERENCES_KEY_DEVICE_TOKEN
        
        if preferences.string(forKey: deviceTokenKey) == deviceToken {
            DashXLog.d(tag: #function, "Already subscribed: \(String(describing: deviceToken))")
            return
        }
        
        let subscribeContactInput = SubscribeContactModel.input(
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid!,
            name: UIDevice.current.model,
            kind: .ios,
            value: deviceToken!,
            osName: UIDevice.current.systemName,
            osVersion: UIDevice.current.systemVersion,
            deviceModel: getDeviceModel(),
            deviceManufacturer: "Apple"
        )
        
        DashXLog.d(tag: #function, "Calling subscribe with \(subscribeContactInput)")
        
        let subscribeContactMutation = SubscribeContactModel.mutation(input: subscribeContactInput)
        
        Network.shared.client.mutate(subscribeContactMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during subscribe(): \(error)")
                    break
                }
            } receiveValue: { value in
                preferences.set(value.data, forKey: deviceTokenKey)
                DashXLog.d(tag: #function, "Sent subscribe with \(value)")
            }
            .store(in: &bag)
    }
    
    // MARK: -- content
    
    public func fetchContent(
        contentType: String,
        content: String,
        preview: Bool? = true,
        language: String?,
        fields: [String]? = [],
        include: [String]? = [],
        exclude: [String]? = [],
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let fetchContentInput = FetchContentModel.input(
            contentType: contentType,
            content: content,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )
        
        DashXLog.d(tag: #function, "Calling fetchContent with \(fetchContentInput)")
        
        // TODO: Add query
        
        // TODO: Add client selection call
    }
    
    public func searchContent(
        contentType: String,
        returnType: String,
        filter: NSDictionary?,
        order: NSDictionary?,
        limit: Int?,
        preview: Bool? = true,
        language: String?,
        fields: [String]? = [],
        include: [String]? = [],
        exclude: [String]? = [],
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let searchContentsInput  = SearchContentModel.input(
            contentType: contentType,
            returnType: returnType,
            filter: filter,
            order: order,
            limit: limit,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )
        
        DashXLog.d(tag: #function, "Calling searchContent with \(searchContentsInput)")
        
        // TODO: Add query
        
        // TODO: Add client selection call
    }
    
    // MARK: -- cart
    
    public func addItemToCart(
        itemId: String,
        pricingId: String,
        quantity: String,
        reset: Bool,
        custom: NSDictionary?,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let addItemToCartInput  = AddItemToCartModel.input(
            uid: self.accountUid,
            anonymousUid: self.accountAnonymousUid,
            itemId: itemId,
            pricingId: pricingId,
            quantity: quantity,
            reset: reset,
            custom: custom
        )
        
        DashXLog.d(tag: #function, "Calling addItemToCart with \(addItemToCartInput)")
        
        let addItemToCartMutation = AddItemToCartModel.mutation(input: addItemToCartInput)
        
        Network.shared.client.mutate(addItemToCartMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during addItemToCart(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent addItemToCart with \(value)")
                successCallback(value.data)
            }
            .store(in: &bag)
    }
    
    public func fetchCart(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        let fetchCartInput  = FetchCartModel.input(uid: self.accountUid, anonymousUid: accountAnonymousUid)
        
        DashXLog.d(tag: #function, "Calling fetchCart with \(fetchCartInput)")
        
        let fetchCartQuery = FetchCartModel.query(input: fetchCartInput)
        
        Network.shared.client.query(fetchCartQuery)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during fetchCart(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent fetchCart with \(value)")
                successCallback(value.data)
            }
            .store(in: &bag)
    }
    
    // MARK: -- StoredPreferences
    
    public func fetchStoredPreferences(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.accountUid else { return }
        
        let fetchStoredPreferencesInput = FetchStoredPreferencesModel.input(uid: uid)
        
        DashXLog.d(tag: #function, "Calling fetchStoredPreferences with \(fetchStoredPreferencesInput)")
        
        let fetchStoredPreferencesQuery = FetchStoredPreferencesModel.query(input: fetchStoredPreferencesInput)
        
        Network.shared.client.query(fetchStoredPreferencesQuery)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during fetchStoredPreferences(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(value)")
                successCallback(value.data.preferenceData)
            }
            .store(in: &bag)
    }
    
    public func saveStoredPreferences(
        preferenceData: NSDictionary?,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.accountUid else { return }
        
        guard let preferenceData = preferenceData as? [String: Any] else { return }
        
        let saveStoredPreferencesInput = SaveStoredPreferencesModel.input(uid: uid, preferenceData: preferenceData)
        
        DashXLog.d(tag: #function, "Calling saveStoredPreferences with \(saveStoredPreferencesInput)")
        
        let saveStoredPreferencesMutation = SaveStoredPreferencesModel.mutation(input: saveStoredPreferencesInput)
        
        Network.shared.client.mutate(saveStoredPreferencesMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during saveStoredPreferences(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent saveStoredPreferences with \(value)")
                successCallback(value.data)
            }
            .store(in: &bag)
    }
    
    // MARK: -- Asset
    
    public func uploadExternalAsset(
        fileURL: URL,
        externalColumnId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        prepareExternalAsset(externalColumnId: externalColumnId) { response in
            
            if let response = response as? PrepareExternalAssetModel,
               let assetId = response.id,
               let urlString = response.upload?.url,
               let url = URL(string: urlString) {
                
                var uploadAssetRequest = URLRequest(url: url)
                uploadAssetRequest.httpMethod = HttpMethod.put.rawValue
                uploadAssetRequest.setValue(fileURL.mimeType(), forHTTPHeaderField: Constants.CONTENT_TYPE)
                uploadAssetRequest.setValue(response.upload?.headers?[Constants.GCS_ASSET_UPLOAD_HEADER_KEY] as? String, forHTTPHeaderField: Constants.GCS_ASSET_UPLOAD_HEADER_KEY)
                
                do {
                    let fileData = try Data(contentsOf: fileURL)
                    
                    URLSession.shared.uploadTask(with: uploadAssetRequest, from: fileData) { data, response, error in
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
    
    private func prepareExternalAsset(
        externalColumnId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        DashXLog.d(tag: #function, "Calling prepareExternalAsset with \(externalColumnId)")
        
        let prepareExternalAssetInput = PrepareExternalAssetModel.input(externalColumnId: externalColumnId)
        
        DashXLog.d(tag: #function, "Calling prepareExternalAsset with \(prepareExternalAssetInput)")
        
        let prepareExternalAssetMutation = PrepareExternalAssetModel.mutation(input: prepareExternalAssetInput)
        
        Network.shared.client.mutate(prepareExternalAssetMutation)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during prepareExternalAsset(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent prepareExternalAsset with \(value)")
                successCallback(value.data)
            }
            .store(in: &bag)
        
    }
    
    private func pollTillAssetIsReady(
        trysLeft: Int,
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        self.externalAsset(assetId: assetId) { response in
            if let response = response as? ExternalAssetModel,
               let status = response.status {
                if status == "ready" || trysLeft == 0 {
                    successCallback(response)
                } else {
                    _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                        self.pollTillAssetIsReady(trysLeft: trysLeft - 1, assetId: assetId, successCallback: successCallback, failureCallback: failureCallback)
                    }
                }
            } else {
                failureCallback(DashXClientError.assetIsNotUploaded)
            }
        } failureCallback: { error in
            failureCallback(error)
        }
    }
    
    public func externalAsset(
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        DashXLog.d(tag: #function, "Calling externalAsset with \(assetId)")
        
        let externalAssetQuery = ExternalAssetModel.query(assetId: assetId)
        
        Network.shared.client.query(externalAssetQuery)
            .sink { error in
                switch error {
                case .finished:
                    break
                case .failure(let error):
                    DashXLog.d(tag: #function, "Encountered an error during externalAsset(): \(error)")
                    failureCallback(error)
                }
            } receiveValue: { value in
                DashXLog.d(tag: #function, "Sent externalAsset with \(value)")
                successCallback(value.data)
            }
            .store(in: &bag)
    }
}
