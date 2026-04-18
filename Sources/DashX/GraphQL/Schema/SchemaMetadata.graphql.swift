// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol DashXGql_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == DashXGql.SchemaMetadata {}

public protocol DashXGql_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == DashXGql.SchemaMetadata {}

public protocol DashXGql_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == DashXGql.SchemaMetadata {}

public protocol DashXGql_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == DashXGql.SchemaMetadata {}

public extension DashXGql {
  typealias SelectionSet = DashXGql_SelectionSet

  typealias InlineFragment = DashXGql_InlineFragment

  typealias MutableSelectionSet = DashXGql_MutableSelectionSet

  typealias MutableInlineFragment = DashXGql_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "Account": return DashXGql.Objects.Account
      case "Asset": return DashXGql.Objects.Asset
      case "Contact": return DashXGql.Objects.Contact
      case "FetchStoredPreferencesResponse": return DashXGql.Objects.FetchStoredPreferencesResponse
      case "Mutation": return DashXGql.Objects.Mutation
      case "Query": return DashXGql.Objects.Query
      case "SaveStoredPreferencesResponse": return DashXGql.Objects.SaveStoredPreferencesResponse
      case "TrackEventResponse": return DashXGql.Objects.TrackEventResponse
      case "TrackMessageResponse": return DashXGql.Objects.TrackMessageResponse
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}