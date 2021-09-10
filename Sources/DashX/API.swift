// @generated
//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

/// DashXGql namespace
public enum DashXGql {
  public struct AddContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentType
    ///   - content
    ///   - data
    public init(contentType: String, content: Swift.Optional<String?> = nil, data: String) {
      graphQLMap = ["contentType": contentType, "content": content, "data": data]
    }

    public var contentType: String {
      get {
        return graphQLMap["contentType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "contentType")
      }
    }

    public var content: Swift.Optional<String?> {
      get {
        return graphQLMap["content"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "content")
      }
    }

    public var data: String {
      get {
        return graphQLMap["data"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }
  }

  public struct EditContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentType
    ///   - content
    ///   - data
    public init(contentType: String, content: String, data: String) {
      graphQLMap = ["contentType": contentType, "content": content, "data": data]
    }

    public var contentType: String {
      get {
        return graphQLMap["contentType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "contentType")
      }
    }

    public var content: String {
      get {
        return graphQLMap["content"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "content")
      }
    }

    public var data: String {
      get {
        return graphQLMap["data"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }
  }

  public struct FetchContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentType
    ///   - content
    ///   - preview
    ///   - language
    ///   - fields
    ///   - include
    ///   - exclude
    public init(contentType: String, content: String, preview: Swift.Optional<Bool?> = nil, language: Swift.Optional<String?> = nil, fields: Swift.Optional<[String]?> = nil, include: Swift.Optional<[String]?> = nil, exclude: Swift.Optional<[String]?> = nil) {
      graphQLMap = ["contentType": contentType, "content": content, "preview": preview, "language": language, "fields": fields, "include": include, "exclude": exclude]
    }

    public var contentType: String {
      get {
        return graphQLMap["contentType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "contentType")
      }
    }

    public var content: String {
      get {
        return graphQLMap["content"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "content")
      }
    }

    public var preview: Swift.Optional<Bool?> {
      get {
        return graphQLMap["preview"] as? Swift.Optional<Bool?> ?? Swift.Optional<Bool?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "preview")
      }
    }

    public var language: Swift.Optional<String?> {
      get {
        return graphQLMap["language"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "language")
      }
    }

    public var fields: Swift.Optional<[String]?> {
      get {
        return graphQLMap["fields"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "fields")
      }
    }

    public var include: Swift.Optional<[String]?> {
      get {
        return graphQLMap["include"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "include")
      }
    }

    public var exclude: Swift.Optional<[String]?> {
      get {
        return graphQLMap["exclude"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "exclude")
      }
    }
  }

  public struct IdentifyAccountInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountType
    ///   - uid
    ///   - anonymousUid
    ///   - email
    ///   - phone
    ///   - name
    ///   - firstName
    ///   - lastName
    public init(accountType: Swift.Optional<String?> = nil, uid: Swift.Optional<String?> = nil, anonymousUid: Swift.Optional<String?> = nil, email: Swift.Optional<String?> = nil, phone: Swift.Optional<String?> = nil, name: Swift.Optional<String?> = nil, firstName: Swift.Optional<String?> = nil, lastName: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountType": accountType, "uid": uid, "anonymousUid": anonymousUid, "email": email, "phone": phone, "name": name, "firstName": firstName, "lastName": lastName]
    }

    public var accountType: Swift.Optional<String?> {
      get {
        return graphQLMap["accountType"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountType")
      }
    }

    public var uid: Swift.Optional<String?> {
      get {
        return graphQLMap["uid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "uid")
      }
    }

    public var anonymousUid: Swift.Optional<String?> {
      get {
        return graphQLMap["anonymousUid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "anonymousUid")
      }
    }

    public var email: Swift.Optional<String?> {
      get {
        return graphQLMap["email"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "email")
      }
    }

    public var phone: Swift.Optional<String?> {
      get {
        return graphQLMap["phone"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "phone")
      }
    }

    public var name: Swift.Optional<String?> {
      get {
        return graphQLMap["name"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var firstName: Swift.Optional<String?> {
      get {
        return graphQLMap["firstName"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "firstName")
      }
    }

    public var lastName: Swift.Optional<String?> {
      get {
        return graphQLMap["lastName"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "lastName")
      }
    }
  }

  public struct SearchContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentType
    ///   - returnType
    ///   - filter
    ///   - order
    ///   - limit
    ///   - preview
    ///   - language
    ///   - fields
    ///   - include
    ///   - exclude
    public init(contentType: String, returnType: String, filter: Swift.Optional<String?> = nil, order: Swift.Optional<String?> = nil, limit: Swift.Optional<Int?> = nil, preview: Swift.Optional<Bool?> = nil, language: Swift.Optional<String?> = nil, fields: Swift.Optional<[String]?> = nil, include: Swift.Optional<[String]?> = nil, exclude: Swift.Optional<[String]?> = nil) {
      graphQLMap = ["contentType": contentType, "returnType": returnType, "filter": filter, "order": order, "limit": limit, "preview": preview, "language": language, "fields": fields, "include": include, "exclude": exclude]
    }

    public var contentType: String {
      get {
        return graphQLMap["contentType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "contentType")
      }
    }

    public var returnType: String {
      get {
        return graphQLMap["returnType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "returnType")
      }
    }

    public var filter: Swift.Optional<String?> {
      get {
        return graphQLMap["filter"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "filter")
      }
    }

    public var order: Swift.Optional<String?> {
      get {
        return graphQLMap["order"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "order")
      }
    }

    public var limit: Swift.Optional<Int?> {
      get {
        return graphQLMap["limit"] as? Swift.Optional<Int?> ?? Swift.Optional<Int?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "limit")
      }
    }

    public var preview: Swift.Optional<Bool?> {
      get {
        return graphQLMap["preview"] as? Swift.Optional<Bool?> ?? Swift.Optional<Bool?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "preview")
      }
    }

    public var language: Swift.Optional<String?> {
      get {
        return graphQLMap["language"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "language")
      }
    }

    public var fields: Swift.Optional<[String]?> {
      get {
        return graphQLMap["fields"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "fields")
      }
    }

    public var include: Swift.Optional<[String]?> {
      get {
        return graphQLMap["include"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "include")
      }
    }

    public var exclude: Swift.Optional<[String]?> {
      get {
        return graphQLMap["exclude"] as? Swift.Optional<[String]?> ?? Swift.Optional<[String]?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "exclude")
      }
    }
  }

  public struct SubscribeContactInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - uid
    ///   - name
    ///   - kind
    ///   - value
    public init(uid: String, name: Swift.Optional<String?> = nil, kind: ContactKind, value: String) {
      graphQLMap = ["uid": uid, "name": name, "kind": kind, "value": value]
    }

    public var uid: String {
      get {
        return graphQLMap["uid"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "uid")
      }
    }

    public var name: Swift.Optional<String?> {
      get {
        return graphQLMap["name"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var kind: ContactKind {
      get {
        return graphQLMap["kind"] as! ContactKind
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "kind")
      }
    }

    public var value: String {
      get {
        return graphQLMap["value"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "value")
      }
    }
  }

  public enum ContactKind: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case secondaryEmail
    case secondaryPhone
    case ios
    case android
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "SECONDARY_EMAIL": self = .secondaryEmail
        case "SECONDARY_PHONE": self = .secondaryPhone
        case "IOS": self = .ios
        case "ANDROID": self = .android
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .secondaryEmail: return "SECONDARY_EMAIL"
        case .secondaryPhone: return "SECONDARY_PHONE"
        case .ios: return "IOS"
        case .android: return "ANDROID"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: ContactKind, rhs: ContactKind) -> Bool {
      switch (lhs, rhs) {
        case (.secondaryEmail, .secondaryEmail): return true
        case (.secondaryPhone, .secondaryPhone): return true
        case (.ios, .ios): return true
        case (.android, .android): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [ContactKind] {
      return [
        .secondaryEmail,
        .secondaryPhone,
        .ios,
        .android,
      ]
    }
  }

  public struct TrackEventInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountType
    ///   - event
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - data
    public init(accountType: String, event: String, accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, data: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountType": accountType, "event": event, "accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "data": data]
    }

    public var accountType: String {
      get {
        return graphQLMap["accountType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountType")
      }
    }

    public var event: String {
      get {
        return graphQLMap["event"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "event")
      }
    }

    public var accountUid: Swift.Optional<String?> {
      get {
        return graphQLMap["accountUid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountUid")
      }
    }

    public var accountAnonymousUid: Swift.Optional<String?> {
      get {
        return graphQLMap["accountAnonymousUid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountAnonymousUid")
      }
    }

    public var data: Swift.Optional<String?> {
      get {
        return graphQLMap["data"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }
  }

  public final class AddContentMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation AddContent($input: AddContentInput!) {
        addContent(input: $input) {
          __typename
          id
          position
          identifier
          data
        }
      }
      """

    public let operationName: String = "AddContent"

    public var input: AddContentInput

    public init(input: AddContentInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("addContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(AddContent.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(addContent: AddContent) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "addContent": addContent.resultMap])
      }

      public var addContent: AddContent {
        get {
          return AddContent(unsafeResultMap: resultMap["addContent"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "addContent")
        }
      }

      public struct AddContent: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Content"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("position", type: .nonNull(.scalar(Int.self))),
            GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
            GraphQLField("data", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String, position: Int, identifier: String, data: String) {
          self.init(unsafeResultMap: ["__typename": "Content", "id": id, "position": position, "identifier": identifier, "data": data])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var position: Int {
          get {
            return resultMap["position"]! as! Int
          }
          set {
            resultMap.updateValue(newValue, forKey: "position")
          }
        }

        public var identifier: String {
          get {
            return resultMap["identifier"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "identifier")
          }
        }

        public var data: String {
          get {
            return resultMap["data"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }
      }
    }
  }

  public final class EditContentMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation EditContent($input: EditContentInput!) {
        editContent(input: $input) {
          __typename
          id
          position
          identifier
          data
        }
      }
      """

    public let operationName: String = "EditContent"

    public var input: EditContentInput

    public init(input: EditContentInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("editContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(EditContent.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(editContent: EditContent) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "editContent": editContent.resultMap])
      }

      public var editContent: EditContent {
        get {
          return EditContent(unsafeResultMap: resultMap["editContent"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "editContent")
        }
      }

      public struct EditContent: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Content"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("position", type: .nonNull(.scalar(Int.self))),
            GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
            GraphQLField("data", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String, position: Int, identifier: String, data: String) {
          self.init(unsafeResultMap: ["__typename": "Content", "id": id, "position": position, "identifier": identifier, "data": data])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var position: Int {
          get {
            return resultMap["position"]! as! Int
          }
          set {
            resultMap.updateValue(newValue, forKey: "position")
          }
        }

        public var identifier: String {
          get {
            return resultMap["identifier"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "identifier")
          }
        }

        public var data: String {
          get {
            return resultMap["data"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }
      }
    }
  }

  public final class FetchContentQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query FetchContent($input: FetchContentInput!) {
        fetchContent(input: $input)
      }
      """

    public let operationName: String = "FetchContent"

    public var input: FetchContentInput

    public init(input: FetchContentInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("fetchContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.scalar(String.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(fetchContent: String) {
        self.init(unsafeResultMap: ["__typename": "Query", "fetchContent": fetchContent])
      }

      public var fetchContent: String {
        get {
          return resultMap["fetchContent"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "fetchContent")
        }
      }
    }
  }

  public final class IdentifyAccountMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation IdentifyAccount($input: IdentifyAccountInput!) {
        identifyAccount(input: $input) {
          __typename
          id
        }
      }
      """

    public let operationName: String = "IdentifyAccount"

    public var input: IdentifyAccountInput

    public init(input: IdentifyAccountInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("identifyAccount", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(IdentifyAccount.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(identifyAccount: IdentifyAccount) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "identifyAccount": identifyAccount.resultMap])
      }

      public var identifyAccount: IdentifyAccount {
        get {
          return IdentifyAccount(unsafeResultMap: resultMap["identifyAccount"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "identifyAccount")
        }
      }

      public struct IdentifyAccount: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Account"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String) {
          self.init(unsafeResultMap: ["__typename": "Account", "id": id])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }

  public final class SearchContentQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query SearchContent($input: SearchContentInput!) {
        searchContent(input: $input)
      }
      """

    public let operationName: String = "SearchContent"

    public var input: SearchContentInput

    public init(input: SearchContentInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("searchContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(searchContent: [String]) {
        self.init(unsafeResultMap: ["__typename": "Query", "searchContent": searchContent])
      }

      public var searchContent: [String] {
        get {
          return resultMap["searchContent"]! as! [String]
        }
        set {
          resultMap.updateValue(newValue, forKey: "searchContent")
        }
      }
    }
  }

  public final class SubscribeContactMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation SubscribeContact($input: SubscribeContactInput!) {
        subscribeContact(input: $input) {
          __typename
          id
        }
      }
      """

    public let operationName: String = "SubscribeContact"

    public var input: SubscribeContactInput

    public init(input: SubscribeContactInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("subscribeContact", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(SubscribeContact.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(subscribeContact: SubscribeContact) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "subscribeContact": subscribeContact.resultMap])
      }

      public var subscribeContact: SubscribeContact {
        get {
          return SubscribeContact(unsafeResultMap: resultMap["subscribeContact"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "subscribeContact")
        }
      }

      public struct SubscribeContact: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Contact"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String) {
          self.init(unsafeResultMap: ["__typename": "Contact", "id": id])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }

  public final class TrackEventMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation TrackEvent($input: TrackEventInput!) {
        trackEvent(input: $input) {
          __typename
          id
        }
      }
      """

    public let operationName: String = "TrackEvent"

    public var input: TrackEventInput

    public init(input: TrackEventInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("trackEvent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(TrackEvent.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(trackEvent: TrackEvent) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "trackEvent": trackEvent.resultMap])
      }

      public var trackEvent: TrackEvent {
        get {
          return TrackEvent(unsafeResultMap: resultMap["trackEvent"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "trackEvent")
        }
      }

      public struct TrackEvent: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Event"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String) {
          self.init(unsafeResultMap: ["__typename": "Event", "id": id])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }
}
