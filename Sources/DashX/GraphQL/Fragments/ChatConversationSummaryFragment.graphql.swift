// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct ChatConversationSummaryFragment: DashXGql.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment ChatConversationSummaryFragment on ChatConversationSummary { __typename conversationId category context { __typename kind subtype id reference name } topic { __typename id label } status title lastMessagePreview lastMessageAt lastSenderKind activityAt assignedGroups { __typename id name } unreadCount }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.ChatConversationSummary }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("conversationId", DashXGql.UUID.self),
      .field("category", String.self),
      .field("context", Context?.self),
      .field("topic", Topic?.self),
      .field("status", String.self),
      .field("title", String.self),
      .field("lastMessagePreview", String?.self),
      .field("lastMessageAt", String?.self),
      .field("lastSenderKind", String?.self),
      .field("activityAt", String.self),
      .field("assignedGroups", [AssignedGroup].self),
      .field("unreadCount", Int.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ChatConversationSummaryFragment.self
    ] }

    var conversationId: DashXGql.UUID { __data["conversationId"] }
    var category: String { __data["category"] }
    var context: Context? { __data["context"] }
    var topic: Topic? { __data["topic"] }
    var status: String { __data["status"] }
    var title: String { __data["title"] }
    var lastMessagePreview: String? { __data["lastMessagePreview"] }
    var lastMessageAt: String? { __data["lastMessageAt"] }
    var lastSenderKind: String? { __data["lastSenderKind"] }
    var activityAt: String { __data["activityAt"] }
    var assignedGroups: [AssignedGroup] { __data["assignedGroups"] }
    var unreadCount: Int { __data["unreadCount"] }

    init(
      conversationId: DashXGql.UUID,
      category: String,
      context: Context? = nil,
      topic: Topic? = nil,
      status: String,
      title: String,
      lastMessagePreview: String? = nil,
      lastMessageAt: String? = nil,
      lastSenderKind: String? = nil,
      activityAt: String,
      assignedGroups: [AssignedGroup],
      unreadCount: Int
    ) {
      self.init(unsafelyWithData: [
        "__typename": DashXGql.Objects.ChatConversationSummary.typename,
        "conversationId": conversationId,
        "category": category,
        "context": context._fieldData,
        "topic": topic._fieldData,
        "status": status,
        "title": title,
        "lastMessagePreview": lastMessagePreview,
        "lastMessageAt": lastMessageAt,
        "lastSenderKind": lastSenderKind,
        "activityAt": activityAt,
        "assignedGroups": assignedGroups._fieldData,
        "unreadCount": unreadCount,
      ])
    }

    /// Context
    ///
    /// Parent Type: `ChatConversationContext`
    struct Context: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.ChatConversationContext }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("kind", String.self),
        .field("subtype", String?.self),
        .field("id", String.self),
        .field("reference", String?.self),
        .field("name", String?.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ChatConversationSummaryFragment.Context.self
      ] }

      var kind: String { __data["kind"] }
      var subtype: String? { __data["subtype"] }
      var id: String { __data["id"] }
      var reference: String? { __data["reference"] }
      var name: String? { __data["name"] }

      init(
        kind: String,
        subtype: String? = nil,
        id: String,
        reference: String? = nil,
        name: String? = nil
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.ChatConversationContext.typename,
          "kind": kind,
          "subtype": subtype,
          "id": id,
          "reference": reference,
          "name": name,
        ])
      }
    }

    /// Topic
    ///
    /// Parent Type: `ChatConversationTopic`
    struct Topic: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.ChatConversationTopic }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("label", String.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ChatConversationSummaryFragment.Topic.self
      ] }

      var id: String { __data["id"] }
      var label: String { __data["label"] }

      init(
        id: String,
        label: String
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.ChatConversationTopic.typename,
          "id": id,
          "label": label,
        ])
      }
    }

    /// AssignedGroup
    ///
    /// Parent Type: `AssignedGroupSummary`
    struct AssignedGroup: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.AssignedGroupSummary }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ChatConversationSummaryFragment.AssignedGroup.self
      ] }

      var id: String { __data["id"] }
      var name: String { __data["name"] }

      init(
        id: String,
        name: String
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.AssignedGroupSummary.typename,
          "id": id,
          "name": name,
        ])
      }
    }
  }

}