import Apollo
#if canImport(ApolloAPI)
import ApolloAPI
#endif

// Apollo iOS pods installed via CocoaPods may not expose a separate `ApolloAPI`
// Swift module. DashX's generated GraphQL code expects `ApolloAPI.*` symbols,
// so we provide a small namespace shim mapping them to the `Apollo` module types.
#if !canImport(ApolloAPI)
public enum ApolloAPI {
    public typealias SchemaMetadata = Apollo.SchemaMetadata
    public typealias SchemaConfiguration = Apollo.SchemaConfiguration
    public typealias Object = Apollo.Object
    public typealias ObjectData = Apollo.ObjectData
    public typealias JSONValue = Apollo.JSONValue
    public typealias OperationDocument = Apollo.OperationDocument
    public typealias ParentType = Apollo.ParentType
    public typealias Selection = Apollo.Selection
}
#endif

