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
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, itemId: UUID, pricingId: UUID, quantity: Decimal, reset: Bool, custom: Swift.Optional<JSON?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "itemId": itemId, "pricingId": pricingId, "quantity": quantity, "reset": reset, "custom": custom]
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
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, orderId: Swift.Optional<UUID?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "orderId": orderId]
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
    public init(accountUid: String) {
      graphQLMap = ["accountUid": accountUid]
    }

    public var accountUid: String {
      get {
        return graphQLMap["accountUid"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "accountUid")
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
    ///   - scope
    ///   - systemContext
    public init(uid: Swift.Optional<String?> = nil, anonymousUid: Swift.Optional<String?> = nil, email: Swift.Optional<String?> = nil, phone: Swift.Optional<String?> = nil, name: Swift.Optional<String?> = nil, firstName: Swift.Optional<String?> = nil, lastName: Swift.Optional<String?> = nil, scope: Swift.Optional<String?> = nil, systemContext: Swift.Optional<SystemContextInput?> = nil) {
      graphQLMap = ["uid": uid, "anonymousUid": anonymousUid, "email": email, "phone": phone, "name": name, "firstName": firstName, "lastName": lastName, "scope": scope, "systemContext": systemContext]
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

    public var scope: Swift.Optional<String?> {
      get {
        return graphQLMap["scope"] as? Swift.Optional<String?> ?? Swift.Optional<String?>.none
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "scope")
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
    ///   - token
    public init(id: String, advertisingId: String, adTrackingEnabled: String, manufacturer: String, model: String, name: String, kind: String, token: String) {
      graphQLMap = ["id": id, "advertisingId": advertisingId, "adTrackingEnabled": adTrackingEnabled, "manufacturer": manufacturer, "model": model, "name": name, "kind": kind, "token": token]
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

    public var adTrackingEnabled: String {
      get {
        return graphQLMap["adTrackingEnabled"] as! String
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

    public var token: String {
      get {
        return graphQLMap["token"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "token")
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
    ///   - city
    ///   - country
    ///   - latitude
    ///   - longitude
    ///   - speed
    public init(city: String, country: String, latitude: Decimal, longitude: Decimal, speed: Decimal) {
      graphQLMap = ["city": city, "country": country, "latitude": latitude, "longitude": longitude, "speed": speed]
    }

    public var city: String {
      get {
        return graphQLMap["city"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "city")
      }
    }

    public var country: String {
      get {
        return graphQLMap["country"] as! String
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "country")
      }
    }

    public var latitude: Decimal {
      get {
        return graphQLMap["latitude"] as! Decimal
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "latitude")
      }
    }

    public var longitude: Decimal {
      get {
        return graphQLMap["longitude"] as! Decimal
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "longitude")
      }
    }

    public var speed: Decimal {
      get {
        return graphQLMap["speed"] as! Decimal
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "speed")
      }
    }
  }

  public struct PrepareExternalAssetInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - externalColumnId
    public init(externalColumnId: UUID) {
      graphQLMap = ["externalColumnId": externalColumnId]
    }

    public var externalColumnId: UUID {
      get {
        return graphQLMap["externalColumnId"] as! UUID
      }
      set {
        graphQLMap.updateValue(newValue, forKey: "externalColumnId")
      }
    }
  }

  public struct SaveStoredPreferencesInput: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    /// - Parameters:
    ///   - accountUid
    ///   - preferenceData
    public init(accountUid: String, preferenceData: JSON) {
      graphQLMap = ["accountUid": accountUid, "preferenceData": preferenceData]
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
    public init(accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, name: Swift.Optional<String?> = nil, kind: ContactKind, value: String, userAgent: Swift.Optional<String?> = nil, osName: Swift.Optional<String?> = nil, osVersion: Swift.Optional<String?> = nil, deviceModel: Swift.Optional<String?> = nil, deviceManufacturer: Swift.Optional<String?> = nil, deviceUid: Swift.Optional<String?> = nil, deviceAdvertisingUid: Swift.Optional<String?> = nil, isDeviceAdTrackingEnabled: Swift.Optional<Bool?> = nil, tag: Swift.Optional<String?> = nil) {
      graphQLMap = ["accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid, "name": name, "kind": kind, "value": value, "userAgent": userAgent, "osName": osName, "osVersion": osVersion, "deviceModel": deviceModel, "deviceManufacturer": deviceManufacturer, "deviceUid": deviceUid, "deviceAdvertisingUid": deviceAdvertisingUid, "isDeviceAdTrackingEnabled": isDeviceAdTrackingEnabled, "tag": tag]
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
    public init(event: String, accountUid: Swift.Optional<String?> = nil, accountAnonymousUid: Swift.Optional<String?> = nil, data: Swift.Optional<JSON?> = nil, timestamp: Swift.Optional<DateTime?> = nil, systemContext: Swift.Optional<SystemContextInput?> = nil) {
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

    public var timestamp: Swift.Optional<DateTime?> {
      get {
        return graphQLMap["timestamp"] as? Swift.Optional<DateTime?> ?? Swift.Optional<DateTime?>.none
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
                GraphQLField("expiresAt", type: .scalar(DateTime.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String, identifier: String, discountType: CouponDiscountType, discountAmount: Decimal, currencyCode: String? = nil, expiresAt: DateTime? = nil) {
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

            public var expiresAt: DateTime? {
              get {
                return resultMap["expiresAt"] as? DateTime
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

  public final class ExternalAssetQuery: GraphQLQuery {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      query ExternalAsset($id: UUID!) {
        externalAsset(id: $id) {
          __typename
          id
          externalColumnId
          status
          data
        }
      }
      """

    public let operationName: String = "ExternalAsset"

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
          GraphQLField("externalAsset", arguments: ["id": GraphQLVariable("id")], type: .nonNull(.object(ExternalAsset.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(externalAsset: ExternalAsset) {
        self.init(unsafeResultMap: ["__typename": "Query", "externalAsset": externalAsset.resultMap])
      }

      public var externalAsset: ExternalAsset {
        get {
          return ExternalAsset(unsafeResultMap: resultMap["externalAsset"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "externalAsset")
        }
      }

      public struct ExternalAsset: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["ExternalAsset"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("externalColumnId", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("status", type: .scalar(String.self)),
            GraphQLField("data", type: .scalar(JSON.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, externalColumnId: UUID, status: String? = nil, data: JSON? = nil) {
          self.init(unsafeResultMap: ["__typename": "ExternalAsset", "id": id, "externalColumnId": externalColumnId, "status": status, "data": data])
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

        public var externalColumnId: UUID {
          get {
            return resultMap["externalColumnId"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "externalColumnId")
          }
        }

        public var status: String? {
          get {
            return resultMap["status"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "status")
          }
        }

        public var data: JSON? {
          get {
            return resultMap["data"] as? JSON
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
                GraphQLField("expiresAt", type: .scalar(DateTime.self)),
              ]
            }

            public private(set) var resultMap: ResultMap

            public init(unsafeResultMap: ResultMap) {
              self.resultMap = unsafeResultMap
            }

            public init(name: String, identifier: String, discountType: CouponDiscountType, discountAmount: Decimal, currencyCode: String? = nil, expiresAt: DateTime? = nil) {
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

            public var expiresAt: DateTime? {
              get {
                return resultMap["expiresAt"] as? DateTime
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

  public final class PrepareExternalAssetMutation: GraphQLMutation {
    /// The raw GraphQL definition of this operation.
    public let operationDefinition: String =
      """
      mutation PrepareExternalAsset($input: PrepareExternalAssetInput!) {
        prepareExternalAsset(input: $input) {
          __typename
          id
          installationId
          externalColumnId
          storageProviderId
          status
          data
          createdAt
          updatedAt
        }
      }
      """

    public let operationName: String = "PrepareExternalAsset"

    public var input: PrepareExternalAssetInput

    public init(input: PrepareExternalAssetInput) {
      self.input = input
    }

    public var variables: GraphQLMap? {
      return ["input": input]
    }

    public struct Data: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Mutation"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("prepareExternalAsset", arguments: ["input": GraphQLVariable("input")], type: .nonNull(.object(PrepareExternalAsset.selections))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(prepareExternalAsset: PrepareExternalAsset) {
        self.init(unsafeResultMap: ["__typename": "Mutation", "prepareExternalAsset": prepareExternalAsset.resultMap])
      }

      public var prepareExternalAsset: PrepareExternalAsset {
        get {
          return PrepareExternalAsset(unsafeResultMap: resultMap["prepareExternalAsset"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "prepareExternalAsset")
        }
      }

      public struct PrepareExternalAsset: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["ExternalAsset"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("installationId", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("externalColumnId", type: .nonNull(.scalar(UUID.self))),
            GraphQLField("storageProviderId", type: .scalar(UUID.self)),
            GraphQLField("status", type: .scalar(String.self)),
            GraphQLField("data", type: .scalar(JSON.self)),
            GraphQLField("createdAt", type: .nonNull(.scalar(DateTime.self))),
            GraphQLField("updatedAt", type: .nonNull(.scalar(DateTime.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: UUID, installationId: UUID, externalColumnId: UUID, storageProviderId: UUID? = nil, status: String? = nil, data: JSON? = nil, createdAt: DateTime, updatedAt: DateTime) {
          self.init(unsafeResultMap: ["__typename": "ExternalAsset", "id": id, "installationId": installationId, "externalColumnId": externalColumnId, "storageProviderId": storageProviderId, "status": status, "data": data, "createdAt": createdAt, "updatedAt": updatedAt])
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

        public var installationId: UUID {
          get {
            return resultMap["installationId"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "installationId")
          }
        }

        public var externalColumnId: UUID {
          get {
            return resultMap["externalColumnId"]! as! UUID
          }
          set {
            resultMap.updateValue(newValue, forKey: "externalColumnId")
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

        public var status: String? {
          get {
            return resultMap["status"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "status")
          }
        }

        public var data: JSON? {
          get {
            return resultMap["data"] as? JSON
          }
          set {
            resultMap.updateValue(newValue, forKey: "data")
          }
        }

        public var createdAt: DateTime {
          get {
            return resultMap["createdAt"]! as! DateTime
          }
          set {
            resultMap.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: DateTime {
          get {
            return resultMap["updatedAt"]! as! DateTime
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
}
