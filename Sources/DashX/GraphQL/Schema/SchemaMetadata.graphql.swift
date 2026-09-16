// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

protocol DashXGql_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == DashXGql.SchemaMetadata {}

protocol DashXGql_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == DashXGql.SchemaMetadata {}

protocol DashXGql_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == DashXGql.SchemaMetadata {}

protocol DashXGql_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == DashXGql.SchemaMetadata {}

extension DashXGql {
  typealias SelectionSet = DashXGql_SelectionSet

  typealias InlineFragment = DashXGql_InlineFragment

  typealias MutableSelectionSet = DashXGql_MutableSelectionSet

  typealias MutableInlineFragment = DashXGql_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "Account": return DashXGql.Objects.Account
      case "Asset": return DashXGql.Objects.Asset
      case "AssignedGroupSummary": return DashXGql.Objects.AssignedGroupSummary
      case "ChatConversationContext": return DashXGql.Objects.ChatConversationContext
      case "ChatConversationSummary": return DashXGql.Objects.ChatConversationSummary
      case "ChatConversationTopic": return DashXGql.Objects.ChatConversationTopic
      case "Contact": return DashXGql.Objects.Contact
      case "FetchStoredPreferencesResponse": return DashXGql.Objects.FetchStoredPreferencesResponse
      case "MarkInAppChatConversationReadResponse": return DashXGql.Objects.MarkInAppChatConversationReadResponse
      case "Message": return DashXGql.Objects.Message
      case "Mutation": return DashXGql.Objects.Mutation
      case "Query": return DashXGql.Objects.Query
      case "SaveStoredPreferencesResponse": return DashXGql.Objects.SaveStoredPreferencesResponse
      case "SummarizeInAppChatConversationsResponse": return DashXGql.Objects.SummarizeInAppChatConversationsResponse
      case "SummarizeInAppChatMessagesResponse": return DashXGql.Objects.SummarizeInAppChatMessagesResponse
      case "SummarizeInAppChatUnreadResponse": return DashXGql.Objects.SummarizeInAppChatUnreadResponse
      case "TrackEventResponse": return DashXGql.Objects.TrackEventResponse
      case "TrackMessageResponse": return DashXGql.Objects.TrackMessageResponse
      case "UnsubscribeContactResponse": return DashXGql.Objects.UnsubscribeContactResponse
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}