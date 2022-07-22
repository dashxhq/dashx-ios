import Foundation
import Apollo
import UIKit

// MARK: Types
public typealias SuccessCallback =  (Any?) -> ()
public typealias FailureCallback = (Error) -> ()

enum DashXClientError: Error {
    case noArgsInIdentify
}

// Shared instance to be used by the SDK users
public let DashX = DashXClient.instance

public class DashXClient {
    static let instance = DashXClient()
    private var anonymousUid: String?
    private var uid: String?
    private var deviceToken: String?

    private var mustSubscribe: Bool = false;

    private init() {
        generateAnonymousUid()
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

    func setTargetInstallation(to targetInstallation: String) {
        ConfigInterceptor.shared.targetInstallation = targetInstallation
    }

    public func setIdentityToken(to token: String) {
        ConfigInterceptor.shared.identityToken = token
    }

    private func generateAnonymousUid(withRegenerate: Bool = false) {
        let preferences = UserDefaults.standard
        let anonymousUidKey = Constants.USER_PREFERENCES_KEY_ANONYMOUS_UID

        if !withRegenerate && preferences.object(forKey: anonymousUidKey) != nil {
            self.anonymousUid = preferences.string(forKey: anonymousUidKey) ?? nil
        } else {
            self.anonymousUid = UUID().uuidString
            preferences.set(self.anonymousUid, forKey: anonymousUidKey)
        }
    }
    // MARK: -- identify

    public func identify(_ uid: String?, withOptions: NSDictionary?) throws {
        /* MARK: - Why do we return here
        if uid != nil {
            self.uid = uid
            return
        }
         */
        if withOptions == nil {
            throw DashXClientError.noArgsInIdentify
        }

        let optionsDictionary = withOptions as? [String: String]

        self.uid = optionsDictionary?["uid"]

        let identifyAccountInput = DashXGql.IdentifyAccountInput(
            uid: optionsDictionary?["uid"],
            anonymousUid: anonymousUid,
            email: optionsDictionary?["email"],
            phone: optionsDictionary?["phone"],
            name: optionsDictionary?["name"],
            firstName: optionsDictionary?["firstName"],
            lastName: optionsDictionary?["lastName"]
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

    func reset() {
        self.uid = nil
        self.generateAnonymousUid(withRegenerate: true)
    }
    // MARK: -- track

    public func track(_ event: String, withData: NSDictionary? = nil) {
        let trackEventInput = DashXGql.TrackEventInput(
            event: event,
            accountUid: uid,
            accountAnonymousUid: anonymousUid,
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
            accountUid: uid,
            accountAnonymousUid: anonymousUid!,
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
             accountUid: self.uid, accountAnonymousUid: self.anonymousUid, itemId: itemId, pricingId: pricingId, quantity: quantity, reset: reset, custom: custom as? [String: JSONDecodable?]
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
            accountUid: self.uid, accountAnonymousUid: self.anonymousUid
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
    
    public func fetchStoredPreferences(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.uid else { return }
        
        let fetchStoredPreferencesInput = DashXGql.FetchStoredPreferencesInput(
            accountUid: uid
        )
        
        DashXLog.d(tag: #function, "Calling fetchStoredPreferences with \(fetchStoredPreferencesInput)")
        
        let fetchStoredPreferencesQuery = DashXGql.FetchStoredPreferencesQuery(input: fetchStoredPreferencesInput)
        
        Network.shared.apollo.fetch(query: fetchStoredPreferencesQuery) { result in
            switch result {
            case .success(let graphQLResult):
              let json = graphQLResult.data?.fetchStoredPreferences
              DashXLog.d(tag: #function, "Sent fetchStoredPreferences with \(String(describing: json))")
              successCallback(json?.resultMap)
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
        guard let uid = self.uid else { return }
        
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
}
