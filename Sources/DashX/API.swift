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
    public init(contentType: String, content: Swift.Optional<String?> = nil, data: JSON) {
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

    public var data: JSON {
      get {
        return graphQLMap["data"] as! JSON
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }
  }

  public struct AddItemToCartInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - itemId
    ///   - pricingId
    ///   - quantity
    ///   - reset
    ///   - custom
    ///   - targetEnvironment
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, itemId: UUID, pricingId: UUID, quantity: Decimal, reset: Bool, custom: Swift.Optional<JSON?> = nil, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "itemId": itemId, "pricingId": pricingId, "quantity": quantity, "reset": reset, "custom": custom, "targetEnvironment": targetEnvironment]
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

    public var itemId: UUID {
      get {
        return graphQLMap["itemId"] as! UUID
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "itemId")
      }
    }

    public var pricingId: UUID {
      get {
        return graphQLMap["pricingId"] as! UUID
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "pricingId")
      }
    }

    public var quantity: Decimal {
      get {
        return graphQLMap["quantity"] as! Decimal
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "quantity")
      }
    }

    public var reset: Bool {
      get {
        return graphQLMap["reset"] as! Bool
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "reset")
      }
    }

    public var custom: Swift.Optional<JSON?> {
      get {
        return graphQLMap["custom"] as? Swift.Optional<JSON?> ?? Swift.Optional<JSON?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "custom")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public enum OrderStatus: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case draft
    case initial
    case checkedOut
    case paid
    case canceled
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "DRAFT": self = .draft
        case "INITIAL": self = .initial
        case "CHECKED_OUT": self = .checkedOut
        case "PAID": self = .paid
        case "CANCELED": self = .canceled
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .draft: return "DRAFT"
        case .initial: return "INITIAL"
        case .checkedOut: return "CHECKED_OUT"
        case .paid: return "PAID"
        case .canceled: return "CANCELED"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
      switch (lhs, rhs) {
        case (.draft, .draft): return true
        case (.initial, .initial): return true
        case (.checkedOut, .checkedOut): return true
        case (.paid, .paid): return true
        case (.canceled, .canceled): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [OrderStatus] {
      return [
        .draft,
        .initial,
        .checkedOut,
        .paid,
        .canceled,
      ]
    }
  }

  public enum CouponDiscountType: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case fixed
    case percentage
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "FIXED": self = .fixed
        case "PERCENTAGE": self = .percentage
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .fixed: return "FIXED"
        case .percentage: return "PERCENTAGE"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: CouponDiscountType, rhs: CouponDiscountType) -> Bool {
      switch (lhs, rhs) {
        case (.fixed, .fixed): return true
        case (.percentage, .percentage): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [CouponDiscountType] {
      return [
        .fixed,
        .percentage,
      ]
    }
  }

  public enum AssetUploadStatus: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case pending
    case uploaded
    case failed
    case canceled
    case timedOut
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "PENDING": self = .pending
        case "UPLOADED": self = .uploaded
        case "FAILED": self = .failed
        case "CANCELED": self = .canceled
        case "TIMED_OUT": self = .timedOut
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .pending: return "PENDING"
        case .uploaded: return "UPLOADED"
        case .failed: return "FAILED"
        case .canceled: return "CANCELED"
        case .timedOut: return "TIMED_OUT"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: AssetUploadStatus, rhs: AssetUploadStatus) -> Bool {
      switch (lhs, rhs) {
        case (.pending, .pending): return true
        case (.uploaded, .uploaded): return true
        case (.failed, .failed): return true
        case (.canceled, .canceled): return true
        case (.timedOut, .timedOut): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [AssetUploadStatus] {
      return [
        .pending,
        .uploaded,
        .failed,
        .canceled,
        .timedOut,
      ]
    }
  }

  public struct EditContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentType
    ///   - content
    ///   - data
    public init(contentType: String, content: String, data: JSON) {
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

    public var data: JSON {
      get {
        return graphQLMap["data"] as! JSON
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }
  }

  public struct FetchCartInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - orderId
    ///   - targetEnvironment
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, orderId: Swift.Optional<UUID?> = nil, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "orderId": orderId, "targetEnvironment": targetEnvironment]
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

    public var orderId: Swift.Optional<UUID?> {
      get {
        return graphQLMap["orderId"] as? Swift.Optional<UUID?> ?? Swift.Optional<UUID?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "orderId")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public struct FetchContentInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - contentId
    ///   - contentType
    ///   - content
    ///   - preview
    ///   - language
    ///   - fields
    ///   - include
    ///   - exclude
    public init(contentId: Swift.Optional<UUID?> = nil, contentType: Swift.Optional<String?> = nil, content: Swift.Optional<String?> = nil, preview: Swift.Optional<Bool?> = nil, language: Swift.Optional<String?> = nil, fields: Swift.Optional<[String]?> = nil, include: Swift.Optional<[String]?> = nil, exclude: Swift.Optional<[String]?> = nil) {
      graphQLMap = ["contentId": contentId, "contentType": contentType, "content": content, "preview": preview, "language": language, "fields": fields, "include": include, "exclude": exclude]
    }

    public var contentId: Swift.Optional<UUID?> {
      get {
        return graphQLMap["contentId"] as? Swift.Optional<UUID?> ?? Swift.Optional<UUID?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "contentId")
      }
    }

    public var contentType: Swift.Optional<String?> {
      get {
        return graphQLMap["contentType"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
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

  public struct FetchStoredPreferencesInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - targetEnvironment
    public init(accountUid: String, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "targetEnvironment": targetEnvironment]
    }

    public var accountUid: String {
      get {
        return graphQLMap["accountUid"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountUid")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public struct IdentifyAccountInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - uid
    ///   - anonymousUid
    ///   - email
    ///   - phone
    ///   - name
    ///   - firstName
    ///   - lastName
    ///   - systemContext
    ///   - targetEnvironment
    public init(uid: Swift.Optional<String?> = nil, anonymousUid: Swift.Optional<String?> = nil, email: Swift.Optional<String?> = nil, phone: Swift.Optional<String?> = nil, name: Swift.Optional<String?> = nil, firstName: Swift.Optional<String?> = nil, lastName: Swift.Optional<String?> = nil, systemContext: Swift.Optional<SystemContextInput?> = nil, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["uid": uid, "anonymousUid": anonymousUid, "email": email, "phone": phone, "name": name, "firstName": firstName, "lastName": lastName, "systemContext": systemContext, "targetEnvironment": targetEnvironment]
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

    public var systemContext: Swift.Optional<SystemContextInput?> {
      get {
        return graphQLMap["systemContext"] as? Swift.Optional<SystemContextInput?> ?? Swift.Optional<SystemContextInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "systemContext")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public struct SystemContextInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - ipV4
    ///   - ipV6
    ///   - locale
    ///   - timeZone
    ///   - userAgent
    ///   - app
    ///   - device
    ///   - os
    ///   - library
    ///   - network
    ///   - screen
    ///   - campaign
    ///   - location
    public init(ipV4: String, ipV6: Swift.Optional<String?> = nil, locale: String, timeZone: String, userAgent: String, app: Swift.Optional<SystemContextAppInput?> = nil, device: Swift.Optional<SystemContextDeviceInput?> = nil, os: Swift.Optional<SystemContextOsInput?> = nil, library: Swift.Optional<SystemContextLibraryInput?> = nil, network: Swift.Optional<SystemContextNetworkInput?> = nil, screen: Swift.Optional<SystemContextScreenInput?> = nil, campaign: Swift.Optional<SystemContextCampaignInput?> = nil, location: Swift.Optional<SystemContextLocationInput?> = nil) {
      graphQLMap = ["ipV4": ipV4, "ipV6": ipV6, "locale": locale, "timeZone": timeZone, "userAgent": userAgent, "app": app, "device": device, "os": os, "library": library, "network": network, "screen": screen, "campaign": campaign, "location": location]
    }

    public var ipV4: String {
      get {
        return graphQLMap["ipV4"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "ipV4")
      }
    }

    public var ipV6: Swift.Optional<String?> {
      get {
        return graphQLMap["ipV6"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "ipV6")
      }
    }

    public var locale: String {
      get {
        return graphQLMap["locale"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "locale")
      }
    }

    public var timeZone: String {
      get {
        return graphQLMap["timeZone"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "timeZone")
      }
    }

    public var userAgent: String {
      get {
        return graphQLMap["userAgent"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "userAgent")
      }
    }

    public var app: Swift.Optional<SystemContextAppInput?> {
      get {
        return graphQLMap["app"] as? Swift.Optional<SystemContextAppInput?> ?? Swift.Optional<SystemContextAppInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "app")
      }
    }

    public var device: Swift.Optional<SystemContextDeviceInput?> {
      get {
        return graphQLMap["device"] as? Swift.Optional<SystemContextDeviceInput?> ?? Swift.Optional<SystemContextDeviceInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "device")
      }
    }

    public var os: Swift.Optional<SystemContextOsInput?> {
      get {
        return graphQLMap["os"] as? Swift.Optional<SystemContextOsInput?> ?? Swift.Optional<SystemContextOsInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "os")
      }
    }

    public var library: Swift.Optional<SystemContextLibraryInput?> {
      get {
        return graphQLMap["library"] as? Swift.Optional<SystemContextLibraryInput?> ?? Swift.Optional<SystemContextLibraryInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "library")
      }
    }

    public var network: Swift.Optional<SystemContextNetworkInput?> {
      get {
        return graphQLMap["network"] as? Swift.Optional<SystemContextNetworkInput?> ?? Swift.Optional<SystemContextNetworkInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "network")
      }
    }

    public var screen: Swift.Optional<SystemContextScreenInput?> {
      get {
        return graphQLMap["screen"] as? Swift.Optional<SystemContextScreenInput?> ?? Swift.Optional<SystemContextScreenInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "screen")
      }
    }

    public var campaign: Swift.Optional<SystemContextCampaignInput?> {
      get {
        return graphQLMap["campaign"] as? Swift.Optional<SystemContextCampaignInput?> ?? Swift.Optional<SystemContextCampaignInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "campaign")
      }
    }

    public var location: Swift.Optional<SystemContextLocationInput?> {
      get {
        return graphQLMap["location"] as? Swift.Optional<SystemContextLocationInput?> ?? Swift.Optional<SystemContextLocationInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "location")
      }
    }
  }

  public struct SystemContextAppInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - name
    ///   - version
    ///   - build
    ///   - namespace
    public init(name: String, version: String, build: String, namespace: String) {
      graphQLMap = ["name": name, "version": version, "build": build, "namespace": namespace]
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var version: String {
      get {
        return graphQLMap["version"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "version")
      }
    }

    public var build: String {
      get {
        return graphQLMap["build"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "build")
      }
    }

    public var namespace: String {
      get {
        return graphQLMap["namespace"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "namespace")
      }
    }
  }

  public struct SystemContextDeviceInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - id
    ///   - advertisingId
    ///   - adTrackingEnabled
    ///   - manufacturer
    ///   - model
    ///   - name
    ///   - kind
    public init(id: String, advertisingId: String, adTrackingEnabled: Bool, manufacturer: String, model: String, name: String, kind: String) {
      graphQLMap = ["id": id, "advertisingId": advertisingId, "adTrackingEnabled": adTrackingEnabled, "manufacturer": manufacturer, "model": model, "name": name, "kind": kind]
    }

    public var id: String {
      get {
        return graphQLMap["id"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "id")
      }
    }

    public var advertisingId: String {
      get {
        return graphQLMap["advertisingId"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "advertisingId")
      }
    }

    public var adTrackingEnabled: Bool {
      get {
        return graphQLMap["adTrackingEnabled"] as! Bool
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "adTrackingEnabled")
      }
    }

    public var manufacturer: String {
      get {
        return graphQLMap["manufacturer"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "manufacturer")
      }
    }

    public var model: String {
      get {
        return graphQLMap["model"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "model")
      }
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var kind: String {
      get {
        return graphQLMap["kind"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "kind")
      }
    }
  }

  public struct SystemContextOsInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - name
    ///   - version
    public init(name: String, version: String) {
      graphQLMap = ["name": name, "version": version]
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var version: String {
      get {
        return graphQLMap["version"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "version")
      }
    }
  }

  public struct SystemContextLibraryInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - name
    ///   - version
    public init(name: String, version: String) {
      graphQLMap = ["name": name, "version": version]
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var version: String {
      get {
        return graphQLMap["version"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "version")
      }
    }
  }

  public struct SystemContextNetworkInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - bluetooth
    ///   - carrier
    ///   - cellular
    ///   - wifi
    public init(bluetooth: Bool, carrier: String, cellular: Bool, wifi: Bool) {
      graphQLMap = ["bluetooth": bluetooth, "carrier": carrier, "cellular": cellular, "wifi": wifi]
    }

    public var bluetooth: Bool {
      get {
        return graphQLMap["bluetooth"] as! Bool
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "bluetooth")
      }
    }

    public var carrier: String {
      get {
        return graphQLMap["carrier"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "carrier")
      }
    }

    public var cellular: Bool {
      get {
        return graphQLMap["cellular"] as! Bool
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "cellular")
      }
    }

    public var wifi: Bool {
      get {
        return graphQLMap["wifi"] as! Bool
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "wifi")
      }
    }
  }

  public struct SystemContextScreenInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - width
    ///   - height
    ///   - density
    public init(width: Int, height: Int, density: Int) {
      graphQLMap = ["width": width, "height": height, "density": density]
    }

    public var width: Int {
      get {
        return graphQLMap["width"] as! Int
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "width")
      }
    }

    public var height: Int {
      get {
        return graphQLMap["height"] as! Int
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "height")
      }
    }

    public var density: Int {
      get {
        return graphQLMap["density"] as! Int
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "density")
      }
    }
  }

  public struct SystemContextCampaignInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - name
    ///   - source
    ///   - medium
    ///   - term
    ///   - content
    public init(name: String, source: String, medium: String, term: String, content: String) {
      graphQLMap = ["name": name, "source": source, "medium": medium, "term": term, "content": content]
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var source: String {
      get {
        return graphQLMap["source"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "source")
      }
    }

    public var medium: String {
      get {
        return graphQLMap["medium"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "medium")
      }
    }

    public var term: String {
      get {
        return graphQLMap["term"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "term")
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
  }

  public struct SystemContextLocationInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - latitude
    ///   - longitude
    ///   - city
    ///   - country
    ///   - speed
    public init(latitude: Swift.Optional<Decimal?> = nil, longitude: Swift.Optional<Decimal?> = nil, city: Swift.Optional<String?> = nil, country: Swift.Optional<String?> = nil, speed: Swift.Optional<Decimal?> = nil) {
      graphQLMap = ["latitude": latitude, "longitude": longitude, "city": city, "country": country, "speed": speed]
    }

    public var latitude: Swift.Optional<Decimal?> {
      get {
        return graphQLMap["latitude"] as? Swift.Optional<Decimal?> ?? Swift.Optional<Decimal?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "latitude")
      }
    }

    public var longitude: Swift.Optional<Decimal?> {
      get {
        return graphQLMap["longitude"] as? Swift.Optional<Decimal?> ?? Swift.Optional<Decimal?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "longitude")
      }
    }

    public var city: Swift.Optional<String?> {
      get {
        return graphQLMap["city"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "city")
      }
    }

    public var country: Swift.Optional<String?> {
      get {
        return graphQLMap["country"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "country")
      }
    }

    public var speed: Swift.Optional<Decimal?> {
      get {
        return graphQLMap["speed"] as? Swift.Optional<Decimal?> ?? Swift.Optional<Decimal?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "speed")
      }
    }
  }

  public struct PrepareAssetInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - resource
    ///   - attribute
    ///   - name
    ///   - size
    ///   - mimeType
    ///   - targetEnvironment
    public init(resource: Swift.Optional<String?> = nil, attribute: Swift.Optional<String?> = nil, name: String, size: Int, mimeType: String, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["resource": resource, "attribute": attribute, "name": name, "size": size, "mimeType": mimeType, "targetEnvironment": targetEnvironment]
    }

    public var resource: Swift.Optional<String?> {
      get {
        return graphQLMap["resource"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "resource")
      }
    }

    public var attribute: Swift.Optional<String?> {
      get {
        return graphQLMap["attribute"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "attribute")
      }
    }

    public var name: String {
      get {
        return graphQLMap["name"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "name")
      }
    }

    public var size: Int {
      get {
        return graphQLMap["size"] as! Int
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "size")
      }
    }

    public var mimeType: String {
      get {
        return graphQLMap["mimeType"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "mimeType")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public struct SaveStoredPreferencesInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - preferenceData
    ///   - targetEnvironment
    public init(accountUid: String, preferenceData: JSON, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "preferenceData": preferenceData, "targetEnvironment": targetEnvironment]
    }

    public var accountUid: String {
      get {
        return graphQLMap["accountUid"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountUid")
      }
    }

    public var preferenceData: JSON {
      get {
        return graphQLMap["preferenceData"] as! JSON
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "preferenceData")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
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
    public init(contentType: String, returnType: String, filter: Swift.Optional<JSON?> = nil, order: Swift.Optional<JSON?> = nil, limit: Swift.Optional<Int?> = nil, preview: Swift.Optional<Bool?> = nil, language: Swift.Optional<String?> = nil, fields: Swift.Optional<[String]?> = nil, include: Swift.Optional<[String]?> = nil, exclude: Swift.Optional<[String]?> = nil) {
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

    public var filter: Swift.Optional<JSON?> {
      get {
        return graphQLMap["filter"] as? Swift.Optional<JSON?> ?? Swift.Optional<JSON?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "filter")
      }
    }

    public var order: Swift.Optional<JSON?> {
      get {
        return graphQLMap["order"] as? Swift.Optional<JSON?> ?? Swift.Optional<JSON?>.none
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
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - name
    ///   - kind
    ///   - value
    ///   - userAgent
    ///   - osName
    ///   - osVersion
    ///   - deviceModel
    ///   - deviceManufacturer
    ///   - deviceUid
    ///   - deviceAdvertisingUid
    ///   - isDeviceAdTrackingEnabled
    ///   - tag
    ///   - targetEnvironment
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, name: Swift.Optional<String?> = nil, kind: ContactKind, value: String, userAgent: Swift.Optional<String?> = nil, osName: Swift.Optional<String?> = nil, osVersion: Swift.Optional<String?> = nil, deviceModel: Swift.Optional<String?> = nil, deviceManufacturer: Swift.Optional<String?> = nil, deviceUid: Swift.Optional<String?> = nil, deviceAdvertisingUid: Swift.Optional<String?> = nil, isDeviceAdTrackingEnabled: Swift.Optional<Bool?> = nil, tag: Swift.Optional<String?> = nil, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "name": name, "kind": kind, "value": value, "userAgent": userAgent, "osName": osName, "osVersion": osVersion, "deviceModel": deviceModel, "deviceManufacturer": deviceManufacturer, "deviceUid": deviceUid, "deviceAdvertisingUid": deviceAdvertisingUid, "isDeviceAdTrackingEnabled": isDeviceAdTrackingEnabled, "tag": tag, "targetEnvironment": targetEnvironment]
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

    public var userAgent: Swift.Optional<String?> {
      get {
        return graphQLMap["userAgent"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "userAgent")
      }
    }

    public var osName: Swift.Optional<String?> {
      get {
        return graphQLMap["osName"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "osName")
      }
    }

    public var osVersion: Swift.Optional<String?> {
      get {
        return graphQLMap["osVersion"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "osVersion")
      }
    }

    public var deviceModel: Swift.Optional<String?> {
      get {
        return graphQLMap["deviceModel"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "deviceModel")
      }
    }

    public var deviceManufacturer: Swift.Optional<String?> {
      get {
        return graphQLMap["deviceManufacturer"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "deviceManufacturer")
      }
    }

    public var deviceUid: Swift.Optional<String?> {
      get {
        return graphQLMap["deviceUid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "deviceUid")
      }
    }

    public var deviceAdvertisingUid: Swift.Optional<String?> {
      get {
        return graphQLMap["deviceAdvertisingUid"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "deviceAdvertisingUid")
      }
    }

    public var isDeviceAdTrackingEnabled: Swift.Optional<Bool?> {
      get {
        return graphQLMap["isDeviceAdTrackingEnabled"] as? Swift.Optional<Bool?> ?? Swift.Optional<Bool?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "isDeviceAdTrackingEnabled")
      }
    }

    public var tag: Swift.Optional<String?> {
      get {
        return graphQLMap["tag"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "tag")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
      }
    }
  }

  public enum ContactKind: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case email
    case phone
    case ios
    case android
    case web
    case whatsapp
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "EMAIL": self = .email
        case "PHONE": self = .phone
        case "IOS": self = .ios
        case "ANDROID": self = .android
        case "WEB": self = .web
        case "WHATSAPP": self = .whatsapp
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .email: return "EMAIL"
        case .phone: return "PHONE"
        case .ios: return "IOS"
        case .android: return "ANDROID"
        case .web: return "WEB"
        case .whatsapp: return "WHATSAPP"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: ContactKind, rhs: ContactKind) -> Bool {
      switch (lhs, rhs) {
        case (.email, .email): return true
        case (.phone, .phone): return true
        case (.ios, .ios): return true
        case (.android, .android): return true
        case (.web, .web): return true
        case (.whatsapp, .whatsapp): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [ContactKind] {
      return [
        .email,
        .phone,
        .ios,
        .android,
        .web,
        .whatsapp,
      ]
    }
  }

  public struct TrackEventInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - event
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - data
    ///   - timestamp
    ///   - systemContext
    public init(event: String, accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, data: Swift.Optional<JSON?> = nil, timestamp: Swift.Optional<Timestamp?> = nil, systemContext: Swift.Optional<SystemContextInput?> = nil) {
      graphQLMap = ["event": event, "accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "data": data, "timestamp": timestamp, "systemContext": systemContext]
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

    public var data: Swift.Optional<JSON?> {
      get {
        return graphQLMap["data"] as? Swift.Optional<JSON?> ?? Swift.Optional<JSON?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "data")
      }
    }

    public var timestamp: Swift.Optional<Timestamp?> {
      get {
        return graphQLMap["timestamp"] as? Swift.Optional<Timestamp?> ?? Swift.Optional<Timestamp?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "timestamp")
      }
    }

    public var systemContext: Swift.Optional<SystemContextInput?> {
      get {
        return graphQLMap["systemContext"] as? Swift.Optional<SystemContextInput?> ?? Swift.Optional<SystemContextInput?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "systemContext")
      }
    }
  }

  public struct TrackNotificationInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - id
    ///   - status
    ///   - timestamp
    public init(id: UUID, status: TrackNotificationStatus, timestamp: Timestamp) {
      graphQLMap = ["id": id, "status": status, "timestamp": timestamp]
    }

    public var id: UUID {
      get {
        return graphQLMap["id"] as! UUID
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "id")
      }
    }

    public var status: TrackNotificationStatus {
      get {
        return graphQLMap["status"] as! TrackNotificationStatus
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "status")
      }
    }

    public var timestamp: Timestamp {
      get {
        return graphQLMap["timestamp"] as! Timestamp
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "timestamp")
      }
    }
  }

  public enum TrackNotificationStatus: RawRepresentable, Equatable, Hashable, CaseIterable, Apollo.JSONDecodable, Apollo.JSONEncodable {
    public typealias RawValue = String
    case delivered
    case opened
    case clicked
    /// Auto generated constant for unknown enum values
    case __unknown(RawValue)

    public init?(rawValue: RawValue) {
      switch rawValue {
        case "DELIVERED": self = .delivered
        case "OPENED": self = .opened
        case "CLICKED": self = .clicked
        default: self = .__unknown(rawValue)
      }
    }

    public var rawValue: RawValue {
      switch self {
        case .delivered: return "DELIVERED"
        case .opened: return "OPENED"
        case .clicked: return "CLICKED"
        case .__unknown(let value): return value
      }
    }

    public static func == (lhs: TrackNotificationStatus, rhs: TrackNotificationStatus) -> Bool {
      switch (lhs, rhs) {
        case (.delivered, .delivered): return true
        case (.opened, .opened): return true
        case (.clicked, .clicked): return true
        case (.__unknown(let lhsValue), .__unknown(let rhsValue)): return lhsValue == rhsValue
        default: return false
      }
    }

    public static var allCases: [TrackNotificationStatus] {
      return [
        .delivered,
        .opened,
        .clicked,
      ]
    }
  }

  public struct UnsubscribeContactInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - accountAnonymousUid
    ///   - value
    ///   - targetEnvironment
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, value: String, targetEnvironment: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "value": value, "targetEnvironment": targetEnvironment]
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

    public var value: String {
      get {
        return graphQLMap["value"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "value")
      }
    }

    public var targetEnvironment: Swift.Optional<String?> {
      get {
        return graphQLMap["targetEnvironment"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "targetEnvironment")
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
        public static let possibleTypes: [String] = ["CustomContent"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("position", type: .nonNull(.scalar(Int.self))),
            GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
            GraphQLField("data", type: .nonNull(.scalar(JSON.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, position: Int, identifier: String, data: JSON) {
          self.init(unsafeResultMap: ["__typename": "CustomContent", "id": id, "position": position, "identifier": identifier, "data": data])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
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

        public var data: JSON {
          get {
            return resultMap["data"]! as! JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }
      }
    }
  }

  public final class AddItemToCartMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation AddItemToCart($input: AddItemToCartInput!) {
        addItemToCart(input: $input) {
          __typename
          id
          status
          subtotal
          discount
          tax
          total
          gatewayMeta
          currencyCode
          orderItems {
            __typename
            id
            quantity
            unitPrice
            subtotal
            discount
            tax
            total
            custom
            currencyCode
          }
          couponRedemptions {
            __typename
            coupon {
              __typename
              name
              identifier
              discountType
              discountAmount
              currencyCode
              expiresAt
            }
          }
        }
      }
      """

    public let operationName: String = "AddItemToCart"

    public var input: AddItemToCartInput

    public init(input: AddItemToCartInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("addItemToCart", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(AddItemToCart.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(addItemToCart: AddItemToCart) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "addItemToCart": addItemToCart.resultMap])
      }

      public var addItemToCart: AddItemToCart {
        get {
          return AddItemToCart(unsafeResultMap: resultMap["addItemToCart"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "addItemToCart")
        }
      }

      public struct AddItemToCart: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Order"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("status", type: .nonNull(.scalar(OrderStatus.self))),
            GraphQLField("subtotal", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("discount", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("tax", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("total", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("gatewayMeta", type: .scalar(JSON.self)),
            GraphQLField("currencyCode", type: .nonNull(.scalar(String.self))),
            GraphQLField("orderItems", type: .nonNull(.list(.nonNull(.object(OrderItem.selections))))),
            GraphQLField("couponRedemptions", type: .nonNull(.list(.nonNull(.object(CouponRedemption.selections))))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, status: OrderStatus, subtotal: Decimal, discount: Decimal, tax: Decimal, total: Decimal, gatewayMeta: JSON? = nil, currencyCode: String, orderItems: [OrderItem], couponRedemptions: [CouponRedemption]) {
          self.init(unsafeResultMap: ["__typename": "Order", "id": id, "status": status, "subtotal": subtotal, "discount": discount, "tax": tax, "total": total, "gatewayMeta": gatewayMeta, "currencyCode": currencyCode, "orderItems": orderItems.map { (value: OrderItem) -> ResultMap in value.resultMap }, "couponRedemptions": couponRedemptions.map { (value: CouponRedemption) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var status: OrderStatus {
          get {
            return resultMap["status"]! as! OrderStatus
          }
          set {
            resultMap.updateValue(newValue, forKey: "status")
          }
        }

        public var subtotal: Decimal {
          get {
            return resultMap["subtotal"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "subtotal")
          }
        }

        public var discount: Decimal {
          get {
            return resultMap["discount"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "discount")
          }
        }

        public var tax: Decimal {
          get {
            return resultMap["tax"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "tax")
          }
        }

        public var total: Decimal {
          get {
            return resultMap["total"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "total")
          }
        }

        public var gatewayMeta: JSON? {
          get {
            return resultMap["gatewayMeta"] as? JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "gatewayMeta")
          }
        }

        public var currencyCode: String {
          get {
            return resultMap["currencyCode"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "currencyCode")
          }
        }

        public var orderItems: [OrderItem] {
          get {
            return (resultMap["orderItems"] as! [ResultMap]).map { (value: ResultMap) -> OrderItem in OrderItem(unsafeResultMap: value) }
          }
          set {
            resultMap.updateValue(newValue.map { (value: OrderItem) -> ResultMap in value.resultMap }, forKey: "orderItems")
          }
        }

        public var couponRedemptions: [CouponRedemption] {
          get {
            return (resultMap["couponRedemptions"] as! [ResultMap]).map { (value: ResultMap) -> CouponRedemption in CouponRedemption(unsafeResultMap: value) }
          }
          set {
            resultMap.updateValue(newValue.map { (value: CouponRedemption) -> ResultMap in value.resultMap }, forKey: "couponRedemptions")
          }
        }

        public struct OrderItem: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["OrderItem"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
              GraphQLField("quantity", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("unitPrice", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("subtotal", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("discount", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("tax", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("total", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("custom", type: .nonNull(.scalar(JSON.self))),
              GraphQLField("currencyCode", type: .nonNull(.scalar(String.self))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: UUID, quantity: Decimal, unitPrice: Decimal, subtotal: Decimal, discount: Decimal, tax: Decimal, total: Decimal, custom: JSON, currencyCode: String) {
            self.init(unsafeResultMap: ["__typename": "OrderItem", "id": id, "quantity": quantity, "unitPrice": unitPrice, "subtotal": subtotal, "discount": discount, "tax": tax, "total": total, "custom": custom, "currencyCode": currencyCode])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: UUID {
            get {
              return resultMap["id"]! as! UUID
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          public var quantity: Decimal {
            get {
              return resultMap["quantity"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "quantity")
            }
          }

          public var unitPrice: Decimal {
            get {
              return resultMap["unitPrice"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "unitPrice")
            }
          }

          public var subtotal: Decimal {
            get {
              return resultMap["subtotal"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "subtotal")
            }
          }

          public var discount: Decimal {
            get {
              return resultMap["discount"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "discount")
            }
          }

          public var tax: Decimal {
            get {
              return resultMap["tax"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "tax")
            }
          }

          public var total: Decimal {
            get {
              return resultMap["total"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "total")
            }
          }

          public var custom: JSON {
            get {
              return resultMap["custom"]! as! JSON
            }
            set {
              resultMap.updateValue(newValue, forKey: "custom")
            }
          }

          public var currencyCode: String {
            get {
              return resultMap["currencyCode"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "currencyCode")
            }
          }
        }

        public struct CouponRedemption: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["CouponRedemption"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("coupon", type: .nonNull(.object(Coupon.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(coupon: Coupon) {
            self.init(unsafeResultMap: ["__typename": "CouponRedemption", "coupon": coupon.resultMap])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var coupon: Coupon {
            get {
              return Coupon(unsafeResultMap: resultMap["coupon"]! as! ResultMap)
            }
            set {
              resultMap.updateValue(newValue.resultMap, forKey: "coupon")
            }
          }

          public struct Coupon: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["Coupon"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("name", type: .nonNull(.scalar(String.self))),
                GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
                GraphQLField("discountType", type: .nonNull(.scalar(CouponDiscountType.self))),
                GraphQLField("discountAmount", type: .nonNull(.scalar(Decimal.self))),
                GraphQLField("currencyCode", type: .scalar(String.self)),
                GraphQLField("expiresAt", type: .scalar(Timestamp.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String, identifier: String, discountType: CouponDiscountType, discountAmount: Decimal, currencyCode: String? = nil, expiresAt: Timestamp? = nil) {
              self.init(unsafeResultMap: ["__typename": "Coupon", "name": name, "identifier": identifier, "discountType": discountType, "discountAmount": discountAmount, "currencyCode": currencyCode, "expiresAt": expiresAt])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            public var name: String {
              get {
                return resultMap["name"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "name")
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

            public var discountType: CouponDiscountType {
              get {
                return resultMap["discountType"]! as! CouponDiscountType
              }
              set {
                resultMap.updateValue(newValue, forKey: "discountType")
              }
            }

            public var discountAmount: Decimal {
              get {
                return resultMap["discountAmount"]! as! Decimal
              }
              set {
                resultMap.updateValue(newValue, forKey: "discountAmount")
              }
            }

            public var currencyCode: String? {
              get {
                return resultMap["currencyCode"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "currencyCode")
              }
            }

            public var expiresAt: Timestamp? {
              get {
                return resultMap["expiresAt"] as? Timestamp
              }
              set {
                resultMap.updateValue(newValue, forKey: "expiresAt")
              }
            }
          }
        }
      }
    }
  }

  public final class AssetQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query Asset($id: UUID!) {
        asset(id: $id) {
          __typename
          id
          resourceId
          attributeId
          uploadStatus
          data
        }
      }
      """

    public let operationName: String = "Asset"

    public var id: UUID

    public init(id: UUID) {
      self.id = id
    }

    public var variables: GraphQLMap? {
      return ["id": id]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("asset", arguments: ["id": GraphQLVariable("id")], type: .nonNull(.object(Asset.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(asset: Asset) {
        self.init(unsafeResultMap: ["__typename": "Query", "asset": asset.resultMap])
      }

      public var asset: Asset {
        get {
          return Asset(unsafeResultMap: resultMap["asset"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "asset")
        }
      }

      public struct Asset: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Asset"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("resourceId", type: .scalar(UUID.self)),
            GraphQLField("attributeId", type: .scalar(UUID.self)),
            GraphQLField("uploadStatus", type: .nonNull(.scalar(AssetUploadStatus.self))),
            GraphQLField("data", type: .nonNull(.scalar(JSON.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, resourceId: UUID? = nil, attributeId: UUID? = nil, uploadStatus: AssetUploadStatus, data: JSON) {
          self.init(unsafeResultMap: ["__typename": "Asset", "id": id, "resourceId": resourceId, "attributeId": attributeId, "uploadStatus": uploadStatus, "data": data])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var resourceId: UUID? {
          get {
            return resultMap["resourceId"] as? UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "resourceId")
          }
        }

        public var attributeId: UUID? {
          get {
            return resultMap["attributeId"] as? UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "attributeId")
          }
        }

        public var uploadStatus: AssetUploadStatus {
          get {
            return resultMap["uploadStatus"]! as! AssetUploadStatus
          }
          set {
            resultMap.updateValue(newValue, forKey: "uploadStatus")
          }
        }

        public var data: JSON {
          get {
            return resultMap["data"]! as! JSON
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
        public static let possibleTypes: [String] = ["CustomContent"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("position", type: .nonNull(.scalar(Int.self))),
            GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
            GraphQLField("data", type: .nonNull(.scalar(JSON.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, position: Int, identifier: String, data: JSON) {
          self.init(unsafeResultMap: ["__typename": "CustomContent", "id": id, "position": position, "identifier": identifier, "data": data])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
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

        public var data: JSON {
          get {
            return resultMap["data"]! as! JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }
      }
    }
  }

  public final class FetchCartQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query FetchCart($input: FetchCartInput!) {
        fetchCart(input: $input) {
          __typename
          id
          status
          subtotal
          discount
          tax
          total
          gatewayMeta
          currencyCode
          orderItems {
            __typename
            id
            quantity
            unitPrice
            subtotal
            discount
            tax
            total
            custom
            currencyCode
          }
          couponRedemptions {
            __typename
            coupon {
              __typename
              name
              identifier
              discountType
              discountAmount
              currencyCode
              expiresAt
            }
          }
        }
      }
      """

    public let operationName: String = "FetchCart"

    public var input: FetchCartInput

    public init(input: FetchCartInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("fetchCart", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(FetchCart.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(fetchCart: FetchCart) {
        self.init(unsafeResultMap: ["__typename": "Query", "fetchCart": fetchCart.resultMap])
      }

      public var fetchCart: FetchCart {
        get {
          return FetchCart(unsafeResultMap: resultMap["fetchCart"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "fetchCart")
        }
      }

      public struct FetchCart: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Order"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("status", type: .nonNull(.scalar(OrderStatus.self))),
            GraphQLField("subtotal", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("discount", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("tax", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("total", type: .nonNull(.scalar(Decimal.self))),
            GraphQLField("gatewayMeta", type: .scalar(JSON.self)),
            GraphQLField("currencyCode", type: .nonNull(.scalar(String.self))),
            GraphQLField("orderItems", type: .nonNull(.list(.nonNull(.object(OrderItem.selections))))),
            GraphQLField("couponRedemptions", type: .nonNull(.list(.nonNull(.object(CouponRedemption.selections))))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, status: OrderStatus, subtotal: Decimal, discount: Decimal, tax: Decimal, total: Decimal, gatewayMeta: JSON? = nil, currencyCode: String, orderItems: [OrderItem], couponRedemptions: [CouponRedemption]) {
          self.init(unsafeResultMap: ["__typename": "Order", "id": id, "status": status, "subtotal": subtotal, "discount": discount, "tax": tax, "total": total, "gatewayMeta": gatewayMeta, "currencyCode": currencyCode, "orderItems": orderItems.map { (value: OrderItem) -> ResultMap in value.resultMap }, "couponRedemptions": couponRedemptions.map { (value: CouponRedemption) -> ResultMap in value.resultMap }])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var status: OrderStatus {
          get {
            return resultMap["status"]! as! OrderStatus
          }
          set {
            resultMap.updateValue(newValue, forKey: "status")
          }
        }

        public var subtotal: Decimal {
          get {
            return resultMap["subtotal"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "subtotal")
          }
        }

        public var discount: Decimal {
          get {
            return resultMap["discount"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "discount")
          }
        }

        public var tax: Decimal {
          get {
            return resultMap["tax"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "tax")
          }
        }

        public var total: Decimal {
          get {
            return resultMap["total"]! as! Decimal
          }
          set {
            resultMap.updateValue(newValue, forKey: "total")
          }
        }

        public var gatewayMeta: JSON? {
          get {
            return resultMap["gatewayMeta"] as? JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "gatewayMeta")
          }
        }

        public var currencyCode: String {
          get {
            return resultMap["currencyCode"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "currencyCode")
          }
        }

        public var orderItems: [OrderItem] {
          get {
            return (resultMap["orderItems"] as! [ResultMap]).map { (value: ResultMap) -> OrderItem in OrderItem(unsafeResultMap: value) }
          }
          set {
            resultMap.updateValue(newValue.map { (value: OrderItem) -> ResultMap in value.resultMap }, forKey: "orderItems")
          }
        }

        public var couponRedemptions: [CouponRedemption] {
          get {
            return (resultMap["couponRedemptions"] as! [ResultMap]).map { (value: ResultMap) -> CouponRedemption in CouponRedemption(unsafeResultMap: value) }
          }
          set {
            resultMap.updateValue(newValue.map { (value: CouponRedemption) -> ResultMap in value.resultMap }, forKey: "couponRedemptions")
          }
        }

        public struct OrderItem: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["OrderItem"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
              GraphQLField("quantity", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("unitPrice", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("subtotal", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("discount", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("tax", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("total", type: .nonNull(.scalar(Decimal.self))),
              GraphQLField("custom", type: .nonNull(.scalar(JSON.self))),
              GraphQLField("currencyCode", type: .nonNull(.scalar(String.self))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: UUID, quantity: Decimal, unitPrice: Decimal, subtotal: Decimal, discount: Decimal, tax: Decimal, total: Decimal, custom: JSON, currencyCode: String) {
            self.init(unsafeResultMap: ["__typename": "OrderItem", "id": id, "quantity": quantity, "unitPrice": unitPrice, "subtotal": subtotal, "discount": discount, "tax": tax, "total": total, "custom": custom, "currencyCode": currencyCode])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: UUID {
            get {
              return resultMap["id"]! as! UUID
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          public var quantity: Decimal {
            get {
              return resultMap["quantity"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "quantity")
            }
          }

          public var unitPrice: Decimal {
            get {
              return resultMap["unitPrice"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "unitPrice")
            }
          }

          public var subtotal: Decimal {
            get {
              return resultMap["subtotal"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "subtotal")
            }
          }

          public var discount: Decimal {
            get {
              return resultMap["discount"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "discount")
            }
          }

          public var tax: Decimal {
            get {
              return resultMap["tax"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "tax")
            }
          }

          public var total: Decimal {
            get {
              return resultMap["total"]! as! Decimal
            }
            set {
              resultMap.updateValue(newValue, forKey: "total")
            }
          }

          public var custom: JSON {
            get {
              return resultMap["custom"]! as! JSON
            }
            set {
              resultMap.updateValue(newValue, forKey: "custom")
            }
          }

          public var currencyCode: String {
            get {
              return resultMap["currencyCode"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "currencyCode")
            }
          }
        }

        public struct CouponRedemption: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["CouponRedemption"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("coupon", type: .nonNull(.object(Coupon.selections))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(coupon: Coupon) {
            self.init(unsafeResultMap: ["__typename": "CouponRedemption", "coupon": coupon.resultMap])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var coupon: Coupon {
            get {
              return Coupon(unsafeResultMap: resultMap["coupon"]! as! ResultMap)
            }
            set {
              resultMap.updateValue(newValue.resultMap, forKey: "coupon")
            }
          }

          public struct Coupon: GraphQLSelectionSet {
            public static let possibleTypes: [String] = ["Coupon"]

            public static var selections: [GraphQLSelection] {
              return [
                GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                GraphQLField("name", type: .nonNull(.scalar(String.self))),
                GraphQLField("identifier", type: .nonNull(.scalar(String.self))),
                GraphQLField("discountType", type: .nonNull(.scalar(CouponDiscountType.self))),
                GraphQLField("discountAmount", type: .nonNull(.scalar(Decimal.self))),
                GraphQLField("currencyCode", type: .scalar(String.self)),
                GraphQLField("expiresAt", type: .scalar(Timestamp.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String, identifier: String, discountType: CouponDiscountType, discountAmount: Decimal, currencyCode: String? = nil, expiresAt: Timestamp? = nil) {
              self.init(unsafeResultMap: ["__typename": "Coupon", "name": name, "identifier": identifier, "discountType": discountType, "discountAmount": discountAmount, "currencyCode": currencyCode, "expiresAt": expiresAt])
            }

            public var __typename: String {
              get {
                return resultMap["__typename"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "__typename")
              }
            }

            public var name: String {
              get {
                return resultMap["name"]! as! String
              }
              set {
                resultMap.updateValue(newValue, forKey: "name")
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

            public var discountType: CouponDiscountType {
              get {
                return resultMap["discountType"]! as! CouponDiscountType
              }
              set {
                resultMap.updateValue(newValue, forKey: "discountType")
              }
            }

            public var discountAmount: Decimal {
              get {
                return resultMap["discountAmount"]! as! Decimal
              }
              set {
                resultMap.updateValue(newValue, forKey: "discountAmount")
              }
            }

            public var currencyCode: String? {
              get {
                return resultMap["currencyCode"] as? String
              }
              set {
                resultMap.updateValue(newValue, forKey: "currencyCode")
              }
            }

            public var expiresAt: Timestamp? {
              get {
                return resultMap["expiresAt"] as? Timestamp
              }
              set {
                resultMap.updateValue(newValue, forKey: "expiresAt")
              }
            }
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
          GraphQLField("fetchContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.scalar(JSON.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(fetchContent: JSON) {
        self.init(unsafeResultMap: ["__typename": "Query", "fetchContent": fetchContent])
      }

      public var fetchContent: JSON {
        get {
          return resultMap["fetchContent"]! as! JSON
        }
        set {
          resultMap.updateValue(newValue, forKey: "fetchContent")
        }
      }
    }
  }

  public final class FetchStoredPreferencesQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query FetchStoredPreferences($input: FetchStoredPreferencesInput!) {
        fetchStoredPreferences(input: $input) {
          __typename
          preferenceData
        }
      }
      """

    public let operationName: String = "FetchStoredPreferences"

    public var input: FetchStoredPreferencesInput

    public init(input: FetchStoredPreferencesInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Query"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("fetchStoredPreferences", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(FetchStoredPreference.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(fetchStoredPreferences: FetchStoredPreference) {
        self.init(unsafeResultMap: ["__typename": "Query", "fetchStoredPreferences": fetchStoredPreferences.resultMap])
      }

      public var fetchStoredPreferences: FetchStoredPreference {
        get {
          return FetchStoredPreference(unsafeResultMap: resultMap["fetchStoredPreferences"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "fetchStoredPreferences")
        }
      }

      public struct FetchStoredPreference: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["FetchStoredPreferencesResponse"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("preferenceData", type: .nonNull(.scalar(JSON.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(preferenceData: JSON) {
          self.init(unsafeResultMap: ["__typename": "FetchStoredPreferencesResponse", "preferenceData": preferenceData])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var preferenceData: JSON {
          get {
            return resultMap["preferenceData"]! as! JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "preferenceData")
          }
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
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID) {
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

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }

  public final class PrepareAssetMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation PrepareAsset($input: PrepareAssetInput!) {
        prepareAsset(input: $input) {
          __typename
          id
          resourceId
          attributeId
          storageProviderId
          uploadStatus
          data
          createdAt
          updatedAt
        }
      }
      """

    public let operationName: String = "PrepareAsset"

    public var input: PrepareAssetInput

    public init(input: PrepareAssetInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("prepareAsset", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(PrepareAsset.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(prepareAsset: PrepareAsset) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "prepareAsset": prepareAsset.resultMap])
      }

      public var prepareAsset: PrepareAsset {
        get {
          return PrepareAsset(unsafeResultMap: resultMap["prepareAsset"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "prepareAsset")
        }
      }

      public struct PrepareAsset: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Asset"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("resourceId", type: .scalar(UUID.self)),
            GraphQLField("attributeId", type: .scalar(UUID.self)),
            GraphQLField("storageProviderId", type: .scalar(UUID.self)),
            GraphQLField("uploadStatus", type: .nonNull(.scalar(AssetUploadStatus.self))),
            GraphQLField("data", type: .nonNull(.scalar(JSON.self))),
            GraphQLField("createdAt", type: .nonNull(.scalar(Timestamp.self))),
            GraphQLField("updatedAt", type: .nonNull(.scalar(Timestamp.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, resourceId: UUID? = nil, attributeId: UUID? = nil, storageProviderId: UUID? = nil, uploadStatus: AssetUploadStatus, data: JSON, createdAt: Timestamp, updatedAt: Timestamp) {
          self.init(unsafeResultMap: ["__typename": "Asset", "id": id, "resourceId": resourceId, "attributeId": attributeId, "storageProviderId": storageProviderId, "uploadStatus": uploadStatus, "data": data, "createdAt": createdAt, "updatedAt": updatedAt])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var resourceId: UUID? {
          get {
            return resultMap["resourceId"] as? UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "resourceId")
          }
        }

        public var attributeId: UUID? {
          get {
            return resultMap["attributeId"] as? UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "attributeId")
          }
        }

        public var storageProviderId: UUID? {
          get {
            return resultMap["storageProviderId"] as? UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "storageProviderId")
          }
        }

        public var uploadStatus: AssetUploadStatus {
          get {
            return resultMap["uploadStatus"]! as! AssetUploadStatus
          }
          set {
            resultMap.updateValue(newValue, forKey: "uploadStatus")
          }
        }

        public var data: JSON {
          get {
            return resultMap["data"]! as! JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }

        public var createdAt: Timestamp {
          get {
            return resultMap["createdAt"]! as! Timestamp
          }
          set {
            resultMap.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: Timestamp {
          get {
            return resultMap["updatedAt"]! as! Timestamp
          }
          set {
            resultMap.updateValue(newValue, forKey: "updatedAt")
          }
        }
      }
    }
  }

  public final class SaveStoredPreferencesMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation SaveStoredPreferences($input: SaveStoredPreferencesInput!) {
        saveStoredPreferences(input: $input) {
          __typename
          success
        }
      }
      """

    public let operationName: String = "SaveStoredPreferences"

    public var input: SaveStoredPreferencesInput

    public init(input: SaveStoredPreferencesInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("saveStoredPreferences", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(SaveStoredPreference.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(saveStoredPreferences: SaveStoredPreference) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "saveStoredPreferences": saveStoredPreferences.resultMap])
      }

      public var saveStoredPreferences: SaveStoredPreference {
        get {
          return SaveStoredPreference(unsafeResultMap: resultMap["saveStoredPreferences"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "saveStoredPreferences")
        }
      }

      public struct SaveStoredPreference: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["SaveStoredPreferencesResponse"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(success: Bool) {
          self.init(unsafeResultMap: ["__typename": "SaveStoredPreferencesResponse", "success": success])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var success: Bool {
          get {
            return resultMap["success"]! as! Bool
          }
          set {
            resultMap.updateValue(newValue, forKey: "success")
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
          GraphQLField("searchContent", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.list(.nonNull(.scalar(JSON.self))))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(searchContent: [JSON]) {
        self.init(unsafeResultMap: ["__typename": "Query", "searchContent": searchContent])
      }

      public var searchContent: [JSON] {
        get {
          return resultMap["searchContent"]! as! [JSON]
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
          value
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
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("value", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, value: String) {
          self.init(unsafeResultMap: ["__typename": "Contact", "id": id, "value": value])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var value: String {
          get {
            return resultMap["value"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "value")
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
          success
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
        public static let possibleTypes: [String] = ["TrackEventResponse"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(success: Bool) {
          self.init(unsafeResultMap: ["__typename": "TrackEventResponse", "success": success])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var success: Bool {
          get {
            return resultMap["success"]! as! Bool
          }
          set {
            resultMap.updateValue(newValue, forKey: "success")
          }
        }
      }
    }
  }

  public final class TrackNotificationMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation TrackNotification($input: TrackNotificationInput!) {
        trackNotification(input: $input) {
          __typename
          success
        }
      }
      """

    public let operationName: String = "TrackNotification"

    public var input: TrackNotificationInput

    public init(input: TrackNotificationInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("trackNotification", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(TrackNotification.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(trackNotification: TrackNotification) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "trackNotification": trackNotification.resultMap])
      }

      public var trackNotification: TrackNotification {
        get {
          return TrackNotification(unsafeResultMap: resultMap["trackNotification"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "trackNotification")
        }
      }

      public struct TrackNotification: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["TrackNotificationResponse"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("success", type: .nonNull(.scalar(Bool.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(success: Bool) {
          self.init(unsafeResultMap: ["__typename": "TrackNotificationResponse", "success": success])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var success: Bool {
          get {
            return resultMap["success"]! as! Bool
          }
          set {
            resultMap.updateValue(newValue, forKey: "success")
          }
        }
      }
    }
  }

  public final class UnsubscribeContactMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation UnsubscribeContact($input: UnsubscribeContactInput!) {
        unsubscribeContact(input: $input) {
          __typename
          id
          value
        }
      }
      """

    public let operationName: String = "UnsubscribeContact"

    public var input: UnsubscribeContactInput

    public init(input: UnsubscribeContactInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("unsubscribeContact", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(UnsubscribeContact.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(unsubscribeContact: UnsubscribeContact) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "unsubscribeContact": unsubscribeContact.resultMap])
      }

      public var unsubscribeContact: UnsubscribeContact {
        get {
          return UnsubscribeContact(unsafeResultMap: resultMap["unsubscribeContact"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "unsubscribeContact")
        }
      }

      public struct UnsubscribeContact: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["Contact"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("value", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, value: String) {
          self.init(unsafeResultMap: ["__typename": "Contact", "id": id, "value": value])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: UUID {
          get {
            return resultMap["id"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var value: String {
          get {
            return resultMap["value"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "value")
          }
        }
      }
    }
  }
}
