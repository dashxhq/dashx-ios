import Foundation
import Apollo

enum DashXClientError: Error {
    case noArgsInIdentify
}

class DashXClient {
    private var anonymousUid: String?
    private var uid: String?
    private var deviceToken: String?
    private var accountType: String?

    init(withPublicKey: String, withAccountType: String? = nil, withBaseUri: String? = nil, withTargetInstallation: String? = nil, withTargetEnvironment: String? = nil) {
        if let targetEnvironment = withTargetEnvironment {
            ConfigInterceptor.shared.targetEnvironment = targetEnvironment
        }

        if let targetInstallation = withTargetInstallation {
            ConfigInterceptor.shared.targetInstallation = targetInstallation
        }

        if let accountType = withAccountType {
            self.accountType = accountType
        }

        if let uri = withBaseUri {
            Network.shared.setBaseUri(to: uri)
        }

        generateAnonymousUid()
    }

    func setDeviceToken(to: String) {
        self.deviceToken = to
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

    func identify(_ uid: String?, withOptions: NSDictionary?) throws {
        if uid != nil {
            self.uid = uid
            return
        }

        if withOptions == nil {
            throw DashXClientError.noArgsInIdentify
        }

        let optionsDictionary = withOptions as? [String: String]

        let identifyAccountInput = DashXGql.IdentifyAccountInput(
            accountType: accountType,
            uid: uid,
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

    func track(_ event: String, withData: NSDictionary? = [:]) {
        let trackData: String?

        if withData == nil {
            trackData = nil
        } else if JSONSerialization.isValidJSONObject(withData!) {
            trackData = try? String(
                data: JSONSerialization.data(withJSONObject: withData!),
                encoding: .utf8
            )
        } else {
            DashXLog.d(tag: #function, "Encountered an error while encoding track data")
            return
        }

        let trackEventInput = DashXGql.TrackEventInput(
            accountType: accountType!,
            event: event,
            accountUid: uid,
            accountAnonymousUid: anonymousUid,
            data: trackData
        )

        DashXLog.d(tag: #function, "Calling track with \(trackEventInput)")

        let trackEventMutation = DashXGql.TrackEventMutation(input: trackEventInput)

        Network.shared.apollo.perform(mutation: trackEventMutation) { result in
          switch result {
          case .success(let graphQLResult):
            DashXLog.d(tag: #function, "Sent track with \(String(describing: graphQLResult))")
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during track(): \(error)")
          }
        }
    }

    func screen(_ screenName: String, withData: NSDictionary? = [:]) {
        let properties = withData as? [String: Any]

        track(Constants.INTERNAL_EVENT_APP_SCREEN_VIEWED, withData: properties?.merging([ "name": screenName], uniquingKeysWith: { (_, new) in new }) as NSDictionary?)
    }
    // MARK: -- subscribe

    func subscribe() {
        if deviceToken == nil || ConfigInterceptor.shared.identityToken == nil {
            return
        }

        let deviceKind = "IOS"

        let subscribeContactInput  = DashXGql.SubscribeContactInput(
            uid: uid!,
            name: deviceKind,
            kind: .ios,
            value: deviceToken!
        )

        DashXLog.d(tag: #function, "Calling subscribe with \(subscribeContactInput)")

        let subscribeContactMutation = DashXGql.SubscribeContactMutation(input: subscribeContactInput)

        Network.shared.apollo.perform(mutation: subscribeContactMutation) { result in
          switch result {
          case .success(let graphQLResult):
            DashXLog.d(tag: #function, "Sent subscribe with \(String(describing: graphQLResult))")
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during subscribe(): \(error)")
          }
        }
    }
    // MARK: -- content

    func fetchContent(_ contentUrn: String, preview: Bool? = true, language: String? = nil, fields: [String]? = nil, include: [String]? = nil, exclude: [String]? = nil,  _ resolve: @escaping (String) -> (), _ reject: @escaping (Error) -> ()) {
        let urnArray = contentUrn.split{$0 == "/"}.map(String.init)

        let fetchContentInput  = DashXGql.FetchContentInput(
            contentType: urnArray[0],
            content: urnArray[1],
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )

        DashXLog.d(tag: #function, "Calling fetchContent with \(fetchContentInput)")

        let fetchContentQuery = DashXGql.FetchContentQuery(input: fetchContentInput)

        Network.shared.apollo.fetch(query: fetchContentQuery) { result in
          switch result {
          case .success(let graphQLResult):
            DashXLog.d(tag: #function, "Sent fetchContent with \(String(describing: graphQLResult))")
            let content = graphQLResult.data?.fetchContent
            resolve(content ?? "")
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during fetchContent(): \(error)")
            reject(error)
          }
        }
    }

    func searchContent(_ contentType: String, returnType: String? = "all", filter: NSDictionary? = nil, order: NSDictionary? = nil, limit: Int? = nil, preview: Bool? = true, language: String? = nil, fields: [String]? = nil, include: [String]? = nil, exclude: [String]? = nil, _ resolve: @escaping ([String]) -> (), _ reject: @escaping (Error) -> ()) {
        let filterJson: String?
        let orderJson: String?

        if filter == nil {
            filterJson = nil
        } else if JSONSerialization.isValidJSONObject(filter!) {
            filterJson = try? String(
                data: JSONSerialization.data(withJSONObject: filter!),
                encoding: .utf8
            )
        } else {
            DashXLog.d(tag: #function, "Encountered an error while encoding filter")
            return
        }

        if order == nil {
            orderJson = nil
        } else if JSONSerialization.isValidJSONObject(order!) {
            orderJson = try? String(
                data: JSONSerialization.data(withJSONObject: order!),
                encoding: .utf8
            )
        } else {
            DashXLog.d(tag: #function, "Encountered an error while encoding order")
            return
        }


        let searchContentsInput  = DashXGql.SearchContentInput(
            contentType: contentType,
            returnType: returnType ?? "all",
            filter: filterJson,
            order: orderJson,
            limit: limit,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )

        DashXLog.d(tag: #function, "Calling searchContent with \(searchContentsInput)")

        let searchContentQuery = DashXGql.SearchContentQuery(input: searchContentsInput)

        Network.shared.apollo.fetch(query: searchContentQuery) { result in
          switch result {
          case .success(let graphQLResult):
            let content = graphQLResult.data?.searchContent
            resolve(content ?? [])
          case .failure(let error):
            DashXLog.d(tag: #function, "Encountered an error during searchContent(): \(error)")
            reject(error)
          }
        }
    }
}
