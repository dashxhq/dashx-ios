// @generated
// This file was manually ported from Apollo 0.51 generated code to Apollo iOS 1.x.
// It contains all schema metadata, custom scalars, input types, enums, and operations.

import Apollo
#if canImport(ApolloAPI)
import ApolloAPI
#endif
import Foundation

// MARK: - DashXGql Namespace

public enum DashXGql {

    // MARK: - Schema Metadata

    enum SchemaMetadata: ApolloAPI.SchemaMetadata {
        static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

        static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
            switch typename {
            case "Query": return Objects.Query
            case "Mutation": return Objects.Mutation
            case "Asset": return Objects.Asset
            case "Account": return Objects.Account
            case "Contact": return Objects.Contact
            case "FetchStoredPreferencesResponse": return Objects.FetchStoredPreferencesResponse
            case "SaveStoredPreferencesResponse": return Objects.SaveStoredPreferencesResponse
            case "TrackEventResponse": return Objects.TrackEventResponse
            case "TrackMessageResponse": return Objects.TrackMessageResponse
            default: return nil
            }
        }
    }

    enum SchemaConfiguration: ApolloAPI.SchemaConfiguration {
        static func cacheKeyInfo(for type: ApolloAPI.Object, object: ApolloAPI.ObjectData) -> CacheKeyInfo? {
            return nil
        }
    }

    enum Objects {
        static let Query = ApolloAPI.Object(typename: "Query", implementedInterfaces: [])
        static let Mutation = ApolloAPI.Object(typename: "Mutation", implementedInterfaces: [])
        static let Asset = ApolloAPI.Object(typename: "Asset", implementedInterfaces: [])
        static let Account = ApolloAPI.Object(typename: "Account", implementedInterfaces: [])
        static let Contact = ApolloAPI.Object(typename: "Contact", implementedInterfaces: [])
        static let FetchStoredPreferencesResponse = ApolloAPI.Object(typename: "FetchStoredPreferencesResponse", implementedInterfaces: [])
        static let SaveStoredPreferencesResponse = ApolloAPI.Object(typename: "SaveStoredPreferencesResponse", implementedInterfaces: [])
        static let TrackEventResponse = ApolloAPI.Object(typename: "TrackEventResponse", implementedInterfaces: [])
        static let TrackMessageResponse = ApolloAPI.Object(typename: "TrackMessageResponse", implementedInterfaces: [])
    }

    // MARK: - Custom Scalars

    public typealias UUID = String
    public typealias Timestamp = String
    public typealias Decimal = String

    public struct JSON: CustomScalarType, Hashable {
        public let value: [String: Any?]

        public init(_ value: [String: Any?]) {
            self.value = value
        }

        public init(_jsonValue value: ApolloAPI.JSONValue) throws {
            if let dict = value as? [String: Any?] {
                self.value = dict
            } else if let base = (value as AnyHashable).base as? [String: Any?] {
                self.value = base
            } else {
                self.value = [:]
            }
        }

        public var _jsonValue: ApolloAPI.JSONValue {
            let dict = value.reduce(into: [String: AnyHashable]()) { result, pair in
                if let val = pair.value {
                    result[pair.key] = val as? AnyHashable
                }
            }
            return dict as AnyHashable
        }

        public static func == (lhs: JSON, rhs: JSON) -> Bool {
            NSDictionary(dictionary: lhs.value.compactMapValues { $0 })
                .isEqual(to: rhs.value.compactMapValues { $0 })
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(value.keys.sorted())
        }
    }

    // MARK: - Enums

    public enum AssetUploadStatus: String, EnumType {
        case pending = "PENDING"
        case uploaded = "UPLOADED"
        case failed = "FAILED"
        case canceled = "CANCELED"
        case timedOut = "TIMED_OUT"
    }

    public enum ContactKind: String, EnumType {
        case email = "EMAIL"
        case phone = "PHONE"
        case ios = "IOS"
        case android = "ANDROID"
        case web = "WEB"
        case whatsapp = "WHATSAPP"
    }

    public enum TrackMessageStatus: String, EnumType {
        case delivered = "DELIVERED"
        case dismissed = "DISMISSED"
        case opened = "OPENED"
        case clicked = "CLICKED"
        case read = "READ"
        case unread = "UNREAD"
    }

    // MARK: - Input Objects

    struct FetchRecordInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) { __data = data }

        init(
            recordId: UUID,
            resource: GraphQLNullable<String> = nil,
            preview: GraphQLNullable<Bool> = nil,
            language: GraphQLNullable<String> = nil,
            fields: GraphQLNullable<[JSON]> = nil,
            include: GraphQLNullable<[JSON]> = nil,
            exclude: GraphQLNullable<[JSON]> = nil
        ) {
            __data = InputDict([
                "recordId": recordId,
                "resource": resource,
                "preview": preview,
                "language": language,
                "fields": fields,
                "include": include,
                "exclude": exclude
            ])
        }

        var recordId: UUID {
            get { __data["recordId"] }
            set { __data["recordId"] = newValue }
        }
    }

    struct FetchStoredPreferencesInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) { __data = data }

        init(accountUid: String, targetEnvironment: GraphQLNullable<String> = nil) {
            __data = InputDict(["accountUid": accountUid, "targetEnvironment": targetEnvironment])
        }

        var accountUid: String {
            get { __data["accountUid"] }
            set { __data["accountUid"] = newValue }
        }
    }

    struct IdentifyAccountInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) { __data = data }

        init(
            uid: GraphQLNullable<String> = nil,
            anonymousUid: GraphQLNullable<String> = nil,
            email: GraphQLNullable<String> = nil,
            phone: GraphQLNullable<String> = nil,
            name: GraphQLNullable<String> = nil,
            firstName: GraphQLNullable<String> = nil,
            lastName: GraphQLNullable<String> = nil,
            systemContext: GraphQLNullable<SystemContextInput> = nil,
            targetEnvironment: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "uid": uid, "anonymousUid": anonymousUid,
                "email": email, "phone": phone,
                "name": name, "firstName": firstName, "lastName": lastName,
                "systemContext": systemContext,
                "targetEnvironment": targetEnvironment
            ])
        }
    }

    struct SystemContextInput: InputObject {
        private(set) var __data: InputDict

        init(_ data: InputDict) { __data = data }

        init(
            ipV4: String,
            ipV6: GraphQLNullable<String> = nil,
            locale: String,
            timeZone: String,
            userAgent: String,
            app: GraphQLNullable<SystemContextAppInput> = nil,
            device: GraphQLNullable<SystemContextDeviceInput> = nil,
            os: GraphQLNullable<SystemContextOsInput> = nil,
            library: GraphQLNullable<SystemContextLibraryInput> = nil,
            network: GraphQLNullable<SystemContextNetworkInput> = nil,
            screen: GraphQLNullable<SystemContextScreenInput> = nil,
            campaign: GraphQLNullable<SystemContextCampaignInput> = nil,
            location: GraphQLNullable<SystemContextLocationInput> = nil
        ) {
            __data = InputDict([
                "ipV4": ipV4, "ipV6": ipV6,
                "locale": locale, "timeZone": timeZone, "userAgent": userAgent,
                "app": app, "device": device, "os": os,
                "library": library, "network": network, "screen": screen,
                "campaign": campaign, "location": location
            ])
        }
    }

    struct SystemContextAppInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(name: String, version: String, build: String, namespace: String) {
            __data = InputDict(["name": name, "version": version, "build": build, "namespace": namespace])
        }

        var name: String { get { __data["name"] } set { __data["name"] = newValue } }
        var version: String { get { __data["version"] } set { __data["version"] = newValue } }
        var build: String { get { __data["build"] } set { __data["build"] = newValue } }
        var namespace: String { get { __data["namespace"] } set { __data["namespace"] = newValue } }
    }

    struct SystemContextDeviceInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(id: String, advertisingId: String, adTrackingEnabled: Bool,
             manufacturer: String, model: String, name: String, kind: String) {
            __data = InputDict([
                "id": id, "advertisingId": advertisingId,
                "adTrackingEnabled": adTrackingEnabled, "manufacturer": manufacturer,
                "model": model, "name": name, "kind": kind
            ])
        }
    }

    struct SystemContextOsInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(name: String, version: String) {
            __data = InputDict(["name": name, "version": version])
        }
        var name: String { get { __data["name"] } set { __data["name"] = newValue } }
        var version: String { get { __data["version"] } set { __data["version"] = newValue } }
    }

    struct SystemContextLibraryInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(name: String, version: String) {
            __data = InputDict(["name": name, "version": version])
        }
        var name: String { get { __data["name"] } set { __data["name"] = newValue } }
        var version: String { get { __data["version"] } set { __data["version"] = newValue } }
    }

    struct SystemContextNetworkInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(bluetooth: Bool, carrier: String, cellular: Bool, wifi: Bool) {
            __data = InputDict(["bluetooth": bluetooth, "carrier": carrier, "cellular": cellular, "wifi": wifi])
        }
    }

    struct SystemContextScreenInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(width: Int, height: Int, density: Int) {
            __data = InputDict(["width": width, "height": height, "density": density])
        }
        var width: Int { get { __data["width"] } set { __data["width"] = newValue } }
        var height: Int { get { __data["height"] } set { __data["height"] = newValue } }
        var density: Int { get { __data["density"] } set { __data["density"] = newValue } }
    }

    struct SystemContextCampaignInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(name: String, source: String, medium: String, term: String, content: String) {
            __data = InputDict(["name": name, "source": source, "medium": medium, "term": term, "content": content])
        }
    }

    struct SystemContextLocationInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }
        init(
            latitude: GraphQLNullable<String> = nil,
            longitude: GraphQLNullable<String> = nil,
            city: GraphQLNullable<String> = nil,
            country: GraphQLNullable<String> = nil,
            speed: GraphQLNullable<String> = nil
        ) {
            __data = InputDict(["latitude": latitude, "longitude": longitude, "city": city, "country": country, "speed": speed])
        }
    }

    struct PrepareAssetInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(
            resource: GraphQLNullable<String> = nil,
            attribute: GraphQLNullable<String> = nil,
            operation: GraphQLNullable<String> = nil,
            parameter: GraphQLNullable<String> = nil,
            name: String, size: Int, mimeType: String,
            width: GraphQLNullable<Int> = nil,
            height: GraphQLNullable<Int> = nil,
            externalUid: GraphQLNullable<String> = nil,
            externalMetadata: GraphQLNullable<JSON> = nil,
            targetEnvironment: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "resource": resource, "attribute": attribute,
                "operation": operation, "parameter": parameter,
                "name": name, "size": size, "mimeType": mimeType,
                "width": width, "height": height,
                "externalUid": externalUid, "externalMetadata": externalMetadata,
                "targetEnvironment": targetEnvironment
            ])
        }
    }

    struct SaveStoredPreferencesInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(accountUid: String, preferenceData: JSON, targetEnvironment: GraphQLNullable<String> = nil) {
            __data = InputDict(["accountUid": accountUid, "preferenceData": preferenceData, "targetEnvironment": targetEnvironment])
        }
    }

    struct SearchRecordsInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(
            resource: String,
            filter: GraphQLNullable<JSON> = nil,
            order: GraphQLNullable<[JSON]> = nil,
            limit: GraphQLNullable<Int> = nil,
            page: GraphQLNullable<Int> = nil,
            preview: GraphQLNullable<Bool> = nil,
            language: GraphQLNullable<String> = nil,
            fields: GraphQLNullable<[JSON]> = nil,
            include: GraphQLNullable<[JSON]> = nil,
            exclude: GraphQLNullable<[JSON]> = nil
        ) {
            __data = InputDict([
                "resource": resource, "filter": filter, "order": order,
                "limit": limit, "page": page, "preview": preview,
                "language": language, "fields": fields,
                "include": include, "exclude": exclude
            ])
        }
    }

    struct SubscribeContactInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(
            accountUid: GraphQLNullable<String> = nil,
            accountAnonymousUid: GraphQLNullable<String> = nil,
            name: GraphQLNullable<String> = nil,
            kind: GraphQLEnum<ContactKind>,
            value: String,
            userAgent: GraphQLNullable<String> = nil,
            osName: GraphQLNullable<String> = nil,
            osVersion: GraphQLNullable<String> = nil,
            deviceModel: GraphQLNullable<String> = nil,
            deviceManufacturer: GraphQLNullable<String> = nil,
            deviceUid: GraphQLNullable<String> = nil,
            deviceAdvertisingUid: GraphQLNullable<String> = nil,
            isDeviceAdTrackingEnabled: GraphQLNullable<Bool> = nil,
            tag: GraphQLNullable<String> = nil,
            targetEnvironment: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid,
                "name": name, "kind": kind, "value": value,
                "userAgent": userAgent, "osName": osName, "osVersion": osVersion,
                "deviceModel": deviceModel, "deviceManufacturer": deviceManufacturer,
                "deviceUid": deviceUid, "deviceAdvertisingUid": deviceAdvertisingUid,
                "isDeviceAdTrackingEnabled": isDeviceAdTrackingEnabled,
                "tag": tag, "targetEnvironment": targetEnvironment
            ])
        }
    }

    struct TrackEventInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(
            event: String,
            accountUid: GraphQLNullable<String> = nil,
            accountAnonymousUid: GraphQLNullable<String> = nil,
            data: GraphQLNullable<JSON> = nil,
            timestamp: GraphQLNullable<String> = nil,
            systemContext: GraphQLNullable<SystemContextInput> = nil
        ) {
            __data = InputDict([
                "event": event, "accountUid": accountUid,
                "accountAnonymousUid": accountAnonymousUid,
                "data": data, "timestamp": timestamp,
                "systemContext": systemContext
            ])
        }
    }

    struct TrackMessageInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(id: UUID, status: GraphQLEnum<TrackMessageStatus>, timestamp: Timestamp) {
            __data = InputDict(["id": id, "status": status, "timestamp": timestamp])
        }
    }

    struct UnsubscribeContactInput: InputObject {
        private(set) var __data: InputDict
        init(_ data: InputDict) { __data = data }

        init(
            accountUid: GraphQLNullable<String> = nil,
            accountAnonymousUid: GraphQLNullable<String> = nil,
            value: String,
            targetEnvironment: GraphQLNullable<String> = nil
        ) {
            __data = InputDict([
                "accountUid": accountUid, "accountAnonymousUid": accountAnonymousUid,
                "value": value, "targetEnvironment": targetEnvironment
            ])
        }
    }

    // MARK: - Queries

    class AssetQuery: GraphQLQuery {
        static let operationName: String = "Asset"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
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
            """))

        var id: UUID
        init(id: UUID) { self.id = id }
        var __variables: Variables? { ["id": id] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Query }
            static var __selections: [ApolloAPI.Selection] { [
                .field("asset", Asset.self, arguments: ["id": .variable("id")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var asset: Asset { __data["asset"] }

            struct Asset: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.Asset }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("id", String.self),
                    .field("resourceId", String?.self),
                    .field("attributeId", String?.self),
                    .field("uploadStatus", GraphQLEnum<AssetUploadStatus>.self),
                    .field("data", JSON.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var id: String { __data["id"] }
                var resourceId: String? { __data["resourceId"] }
                var attributeId: String? { __data["attributeId"] }
                var uploadStatus: GraphQLEnum<AssetUploadStatus> { __data["uploadStatus"] }
                var data: JSON { __data["data"] }

                var resultMap: [String: Any?] {
                    __data._data.reduce(into: [String: Any?]()) { r, e in r[e.key] = e.value }
                }
            }
        }
    }

    class FetchRecordQuery: GraphQLQuery {
        static let operationName: String = "FetchRecord"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            query FetchRecord($input: FetchRecordInput!) {
              fetchRecord(input: $input)
            }
            """))

        var input: FetchRecordInput
        init(input: FetchRecordInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Query }
            static var __selections: [ApolloAPI.Selection] { [
                .field("fetchRecord", JSON.self)
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var fetchRecord: JSON { __data["fetchRecord"] }
        }
    }

    class FetchStoredPreferencesQuery: GraphQLQuery {
        static let operationName: String = "FetchStoredPreferences"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            query FetchStoredPreferences($input: FetchStoredPreferencesInput!) {
              fetchStoredPreferences(input: $input) {
                __typename
                preferenceData
              }
            }
            """))

        var input: FetchStoredPreferencesInput
        init(input: FetchStoredPreferencesInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Query }
            static var __selections: [ApolloAPI.Selection] { [
                .field("fetchStoredPreferences", FetchStoredPreference.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var fetchStoredPreferences: FetchStoredPreference { __data["fetchStoredPreferences"] }

            struct FetchStoredPreference: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.FetchStoredPreferencesResponse }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("preferenceData", JSON.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var preferenceData: JSON { __data["preferenceData"] }
            }
        }
    }

    class SearchRecordsQuery: GraphQLQuery {
        static let operationName: String = "SearchRecords"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            query SearchRecords($input: SearchRecordsInput!) {
              searchRecords(input: $input)
            }
            """))

        var input: SearchRecordsInput
        init(input: SearchRecordsInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Query }
            static var __selections: [ApolloAPI.Selection] { [
                .field("searchRecords", [JSON].self)
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var searchRecords: [JSON] { __data["searchRecords"] }
        }
    }

    // MARK: - Mutations

    class IdentifyAccountMutation: GraphQLMutation {
        static let operationName: String = "IdentifyAccount"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation IdentifyAccount($input: IdentifyAccountInput!) {
              identifyAccount(input: $input) {
                __typename
                id
              }
            }
            """))

        var input: IdentifyAccountInput
        init(input: IdentifyAccountInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("identifyAccount", IdentifyAccount.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var identifyAccount: IdentifyAccount { __data["identifyAccount"] }

            struct IdentifyAccount: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.Account }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("id", String.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var id: String { __data["id"] }
            }
        }
    }

    class PrepareAssetMutation: GraphQLMutation {
        static let operationName: String = "PrepareAsset"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
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
            """))

        var input: PrepareAssetInput
        init(input: PrepareAssetInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("prepareAsset", PrepareAsset.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var prepareAsset: PrepareAsset { __data["prepareAsset"] }

            struct PrepareAsset: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.Asset }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("id", String.self),
                    .field("resourceId", String?.self),
                    .field("attributeId", String?.self),
                    .field("storageProviderId", String?.self),
                    .field("uploadStatus", GraphQLEnum<AssetUploadStatus>.self),
                    .field("data", JSON.self),
                    .field("createdAt", String.self),
                    .field("updatedAt", String.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var id: String { __data["id"] }
                var resourceId: String? { __data["resourceId"] }
                var attributeId: String? { __data["attributeId"] }
                var storageProviderId: String? { __data["storageProviderId"] }
                var uploadStatus: GraphQLEnum<AssetUploadStatus> { __data["uploadStatus"] }
                var data: JSON { __data["data"] }
                var createdAt: String { __data["createdAt"] }
                var updatedAt: String { __data["updatedAt"] }

                var resultMap: [String: Any?] {
                    __data._data.reduce(into: [String: Any?]()) { r, e in r[e.key] = e.value }
                }
            }
        }
    }

    class SaveStoredPreferencesMutation: GraphQLMutation {
        static let operationName: String = "SaveStoredPreferences"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation SaveStoredPreferences($input: SaveStoredPreferencesInput!) {
              saveStoredPreferences(input: $input) {
                __typename
                success
              }
            }
            """))

        var input: SaveStoredPreferencesInput
        init(input: SaveStoredPreferencesInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("saveStoredPreferences", SaveStoredPreference.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var saveStoredPreferences: SaveStoredPreference { __data["saveStoredPreferences"] }

            struct SaveStoredPreference: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.SaveStoredPreferencesResponse }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("success", Bool.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var success: Bool { __data["success"] }
            }
        }
    }

    class SubscribeContactMutation: GraphQLMutation {
        static let operationName: String = "SubscribeContact"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation SubscribeContact($input: SubscribeContactInput!) {
              subscribeContact(input: $input) {
                __typename
                id
                value
              }
            }
            """))

        var input: SubscribeContactInput
        init(input: SubscribeContactInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("subscribeContact", SubscribeContact.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var subscribeContact: SubscribeContact { __data["subscribeContact"] }

            struct SubscribeContact: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.Contact }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("id", String.self),
                    .field("value", String.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var id: String { __data["id"] }
                var value: String { __data["value"] }
            }
        }
    }

    class TrackEventMutation: GraphQLMutation {
        static let operationName: String = "TrackEvent"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation TrackEvent($input: TrackEventInput!) {
              trackEvent(input: $input) {
                __typename
                success
              }
            }
            """))

        var input: TrackEventInput
        init(input: TrackEventInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("trackEvent", TrackEvent.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var trackEvent: TrackEvent { __data["trackEvent"] }

            struct TrackEvent: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.TrackEventResponse }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("success", Bool.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var success: Bool { __data["success"] }
            }
        }
    }

    class TrackMessageMutation: GraphQLMutation {
        static let operationName: String = "TrackMessage"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation TrackMessage($input: TrackMessageInput!) {
              trackMessage(input: $input) {
                __typename
                success
              }
            }
            """))

        var input: TrackMessageInput
        init(input: TrackMessageInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("trackMessage", TrackMessage.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var trackMessage: TrackMessage { __data["trackMessage"] }

            struct TrackMessage: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.TrackMessageResponse }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("success", Bool.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var success: Bool { __data["success"] }
            }
        }
    }

    class UnsubscribeContactMutation: GraphQLMutation {
        static let operationName: String = "UnsubscribeContact"
        static let operationDocument: ApolloAPI.OperationDocument = .init(
            definition: .init("""
            mutation UnsubscribeContact($input: UnsubscribeContactInput!) {
              unsubscribeContact(input: $input) {
                __typename
                id
                value
              }
            }
            """))

        var input: UnsubscribeContactInput
        init(input: UnsubscribeContactInput) { self.input = input }
        var __variables: Variables? { ["input": input] }

        struct Data: RootSelectionSet {
            typealias Schema = SchemaMetadata
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { Objects.Mutation }
            static var __selections: [ApolloAPI.Selection] { [
                .field("unsubscribeContact", UnsubscribeContact.self, arguments: ["input": .variable("input")])
            ] }
            static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

            var unsubscribeContact: UnsubscribeContact { __data["unsubscribeContact"] }

            struct UnsubscribeContact: RootSelectionSet {
                typealias Schema = SchemaMetadata
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                static var __parentType: any ApolloAPI.ParentType { Objects.Contact }
                static var __selections: [ApolloAPI.Selection] { [
                    .field("__typename", String.self),
                    .field("id", String.self),
                    .field("value", String.self)
                ] }
                static var __fulfilledFragments: [any SelectionSet.Type] { [Self.self] }

                var id: String { __data["id"] }
                var value: String { __data["value"] }
            }
        }
    }
}
