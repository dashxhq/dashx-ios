import Foundation
import Combine
import UIKit


// TODO:
// Create input if needed
// Log input if it is present
// Create query or mutation
// Log responses from those calls

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
    
    private var publicKey: String?
    private var baseURI: String?
    private var targetEnvironment: String?

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
        
        self.publicKey = publicKey
        self.baseURI = baseURI
        self.targetEnvironment = targetEnvironment
    }

    public func setIdentity(uid: String, token: String) {
        let preferences = UserDefaults.standard
        
        self.accountUid = uid
        preferences.set(self.accountUid, forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
    }
    
    private func setDeviceToken(to: String) {
        self.deviceToken = to

        if (self.mustSubscribe) {
//          self.subscribe()
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
        // ConfigInterceptor.shared.identityToken = preferences.string(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
    }

    public func reset() {
        let preferences = UserDefaults.standard
        
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID)
        preferences.removeObject(forKey: Constants.USER_PREFERENCES_KEY_IDENTITY_TOKEN)
        
        self.accountUid = nil
        self.accountAnonymousUid = self.generateAnonymousUid(withRegenerate: true)
//        ConfigInterceptor.shared.identityToken = nil
    }
    
    

    public func screen(_ screenName: String, withData: NSDictionary?) {
        let properties = withData as? [String: Any]

//        track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties?.merging([ "name": screenName], uniquingKeysWith: { (_, new) in new }) as NSDictionary?)
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

        
    }
    
    // MARK: -- track

    public func track(_ event: String, withData: NSDictionary? = nil) {
        
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
    }

    public func fetchCart(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        
    }
    
    // MARK: -- StoredPreferences
    
    public func fetchStoredPreferences(
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        guard let uid = self.accountUid else { return }
        
        let fetchStoredPreferencesInput = FetchStoredPreferences.input(uid: uid)
        
        DashXLog.d(tag: #function, "Calling fetchStoredPreferences with \(fetchStoredPreferencesInput)")
        
        let fetchStoredPreferencesQuery = FetchStoredPreferences.query(input: fetchStoredPreferencesInput)
        
        Network.client(publicKey: self.publicKey ?? "", environment: self.targetEnvironment ?? "")
            .query(fetchStoredPreferencesQuery)
            .sink { error in
                // Check whether the error is of type finished or real error
                // failureCallback(error)
                print(error)
            } receiveValue: { data in
                print(data)
                successCallback(data.data.preferenceData)
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
        
        let saveStoredPreferencesInput = SaveStoredPreferences.input(uid: uid, preferenceData: preferenceData)
        
        DashXLog.d(tag: #function, "Calling saveStoredPreferences with \(saveStoredPreferencesInput)")
        
        let saveStoredPreferencesMutation = SaveStoredPreferences.mutation(input: saveStoredPreferencesInput)
        
        Network.client(publicKey: self.publicKey ?? "", environment: self.targetEnvironment ?? "")
            .mutate(saveStoredPreferencesMutation)
            .sink { error in
                print(error)
            } receiveValue: { data in
                print(data)
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
        
    }
    
    private func prepareExternalAsset(
        externalColumnId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        DashXLog.d(tag: #function, "Calling prepareExternalAsset with \(externalColumnId)")
    }
    
    private func pollTillAssetIsReady(
        trysLeft: Int,
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
    }
    
    public func externalAsset(
        assetId: String,
        successCallback: @escaping SuccessCallback,
        failureCallback: @escaping FailureCallback
    ) {
        DashXLog.d(tag: #function, "Calling externalAsset with \(assetId)")
        
    }
}
