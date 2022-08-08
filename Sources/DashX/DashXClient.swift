import Foundation
import Apollo
import UIKit

// MARK: Types
public typealias SuccessCallback =  (Any?) -> ()
public typealias FailureCallback = (Error) -> ()

enum DashXClientError: Error {
    case noArgsInIdentify
    case assetIsNotReady
}

// Shared instance to be used by the SDK users
public let DashX = DashXClient.instance

public class DashXClient {
    static let instance = DashXClient()
    private var accountAnonymousUid: String?
    private var accountUid: String?
    private var deviceToken: String?

    private var mustSubscribe: Bool = false;

    private init() {
        loadIdentity()
    }
    
    // Hiding the initialiser from user till multiple dash clients support is in place
    private init(withPublicKey publicKey: String,
                baseURI: String? = nil,
                targetEnvironment: String? = nil
    ) {
        self.setPublicKey(to: publicKey)
        
        if baseURI != nil {
            self.setBaseURI(to: baseURI!)
        }
        
        if targetEnvironment != nil {
            self.setTargetEnvironment(to: targetEnvironment!)
        }
    }
    
    public func setup(_ options: NSDictionary?) {
        ConfigInterceptor.shared.publicKey = options?.value(forKey: "publicKey") as? String

        DashXAppDelegate.swizzleDidReceiveRemoteNotificationFetchCompletionHandler()

        if let baseUri = options?.value(forKey: "baseUri") {
            self.setBaseURI(to: baseUri as! String)
        }

        if let targetEnvironment = options?.value(forKey: "targetEnvironment") {
            self.setTargetEnvironment(to: targetEnvironment as! String)
        }
    }

    func setDeviceToken(to: String) {
        self.deviceToken = to

        if (self.mustSubscribe) {
          self.subscribe()
        }
    }

    public func setPublicKey(to publicKey: String) {
        ConfigInterceptor.shared.publicKey = publicKey
    }
    
    public func setBaseURI(to baseURI: String) {
        Network.shared.setBaseURI(to: baseURI)
    }
    
    public func setTargetEnvironment(to environment: String) {
        ConfigInterceptor.shared.targetEnvironment = environment
    }
    
    public func setIdentity(uid: String? = nil, token: String? = nil) {
        self.accountUid = uid
        ConfigInterceptor.shared.identityToken = token
        
        let preferences = UserDefaults.standard
        
        preferences.set(self.accountUid, forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.set(token, forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
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
    // MARK: -- identify

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
    
    func loadIdentity() {
        let preferences = UserDefaults.standard
        
        self.accountUid = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        self.accountAnonymousUid = generateAnonymousUid()
        ConfigInterceptor.shared.identityToken = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
    }

    func reset() {
        let preferences = UserDefaults.standard
        
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        
        self.accountUid = nil
        self.accountAnonymousUid = self.generateAnonymousUid(withRegenerate: true)
        ConfigInterceptor.shared.identityToken = nil
    }
    // MARK: -- track

    public func track(_ event: String, withData: NSDictionary? = nil) {
        let trackEventInput = DashXGql.TrackEventInput(
            event: event,
            accountUid: accountUid,
            accountAnonymousUid: accountAnonymousUid,
            data: withData as? [String: JSONDecodable?]
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

    func screen(_ screenName: String, withData: NSDictionary?) {
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

    // MARK: -- subscribe

    func subscribe() {
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
        
        let subscribeContactInput  = DashXGql.SubscribeContactInput(
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

        let subscribeContactMutation = DashXGql.SubscribeContactMutation(input: subscribeContactInput)

        Network.shared.apollo.perform(mutation: subscribeContactMutation) { result in
          switch result {
          case .success(let graphQLResult):
              if graphQLResult.data != nil {
                    preferences.set(graphQLResult.data?.subscribeContact.value, forKey: deviceTokenKey)
                    DashXLog.d(tag: #function, "Sent subscribe with \(String(describing: graphQLResult))")
              }
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during subscribe(): \(error)")
          }
        }
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
        let fetchContentInput  = DashXGql.FetchContentInput(
            contentType: contentType,
            content: content,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )

        DashXLog.d(tag: #function, "Calling fetchContent with \(fetchContentInput)")

        let findContentQuery = DashXGql.FetchContentQuery(input: fetchContentInput)

        Network.shared.apollo.fetch(query: findContentQuery, cachePolicy: .returnCacheDataElseFetch) { result in
          switch result {
          case .success(let graphQLResult):
            DashXLog.d(tag: #function, "Sent findContent with \(String(describing: graphQLResult))")
            let content = graphQLResult.data?.fetchContent
            successCallback(content)
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during fetchContent(): \(error)")
              failureCallback(error)
          }
        }
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
        let searchContentsInput  = DashXGql.SearchContentInput(
            contentType: contentType,
            returnType: returnType,
            filter: filter as? [String: Any],
            order: order as? [String: Any],
            limit: limit,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )

        DashXLog.d(tag: #function, "Calling searchContent with \(searchContentsInput)")

        let searchContentQuery = DashXGql.SearchContentQuery(input: searchContentsInput)

        Network.shared.apollo.fetch(query: searchContentQuery, cachePolicy: .returnCacheDataElseFetch) { result in
          switch result {
          case .success(let graphQLResult):
            let json = graphQLResult.data?.searchContent
            DashXLog.d(tag: #function, "Sent searchContents with \(String(describing: json))")
            successCallback(json)
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during searchContent(): \(error)")
            failureCallback(error)
          }
        }
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
        let addItemToCartInput  = DashXGql.AddItemToCartInput(
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
        let fetchCartInput  = DashXGql.FetchCartInput(
            accountUid: self.accountUid, accountAnonymousUid: self.accountAnonymousUid
        )

        DashXLog.d(tag: #function, "Calling fetchCart with \(fetchCartInput)")

        let fetchCartQuery = DashXGql.FetchCartQuery(input: fetchCartInput)

        Network.shared.apollo.fetch(query: fetchCartQuery) { result in
          switch result {
          case .success(let graphQLResult):
            let json = graphQLResult.data?.fetchCart
            DashXLog.d(tag: #function, "Sent fetchCart with \(String(describing: json))")
            successCallback(json?.resultMap)
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during fetchCart(): \(error)")
            failureCallback(error)
          }
        }
    }
    
    // MARK: -- StoredPreferences
    
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
              let json = graphQLResult.data?.fetchStoredPreferences.preferenceData
              DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(String(describing: json))")
              successCallback(json)
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
    
    public func uploadExternalAsset(
        filePath: URL,
        externalColumnId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        self.prepareExternalAsset(externalColumnId: externalColumnId) { response in
            
            if let jsonDictionary = response.jsonValue as? [String: Any],
               let data = jsonDictionary["data"] as? [String: Any],
               let uploadData = data["upload"] as? [String: Any],
               let urlString = uploadData["url"] as? String,
               let url = URL(string: urlString),
               let assetId = jsonDictionary["id"] as? String {
                
                var uploadAssetRequest = URLRequest(url: url)
                uploadAssetRequest.httpMethod = "PUT"
                
                do {
                    let fileData = try Data(contentsOf: filePath)
                    URLSession.shared.uploadTask(with: uploadAssetRequest, from: fileData) { data, response, error in
                        if error != nil {
                            failureCallback(error!)
                        }
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                self.pollTillAssetIsReady(trysLeft: 5, assetId: assetId) { response in
                                    successCallback(response)
                                } failureCallback: { error in
                                    failureCallback(error)
                                }
                            }
                        }
                    }.resume()
                } catch {
                    failureCallback(error)
                }
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
        let prepareExternalAssetInput = DashXGql.PrepareExternalAssetInput(externalColumnId: externalColumnId)
        
        DashXLog.d(tag: #function, "Calling prepareExternalAsset with \(prepareExternalAssetInput)")
        
        let prepareExternalAssetMutation = DashXGql.PrepareExternalAssetMutation(input: prepareExternalAssetInput)
        
        Network.shared.apollo.perform(mutation: prepareExternalAssetMutation) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.prepareExternalAsset
                DashXLog.d(tag: #function, "Sent prepareExternalAsset with \(String(describing: json))")
                successCallback(json?.resultMap)
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during prepareExternalAsset(): \(error)")
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
        self.externalAsset(assetId: assetId) { response in
            if let jsonDictionary = response.jsonValue as? [String: Any],
               let status = jsonDictionary["status"] as? String {
                if status == "ready" {
                    successCallback(response)
                } else {
                    if trysLeft != 0 {
                        _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                            self.pollTillAssetIsReady(trysLeft: trysLeft - 1, assetId: assetId, successCallback: successCallback, failureCallback: failureCallback)
                        }
                    } else {
                        failureCallback(DashXClientError.assetIsNotReady)
                    }
                }
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
        
        let externalAssetQuery = DashXGql.ExternalAssetQuery(id: assetId)
        
        Network.shared.apollo.fetch(query: externalAssetQuery) { result in
            switch result {
            case .success(let graphQLResult):
                let json = graphQLResult.data?.externalAsset
                DashXLog.d(tag: #function, "Sent externalAsset with \(String(describing: json))")
                successCallback(json?.resultMap)
            case .failure(let error):
                DashXLog.d(tag: #function, "Encountered an error during externalAsset(): \(error)")
                failureCallback(error)
            }
        }
    }
}
