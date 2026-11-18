// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct ChatMessageFragment: DashXGql.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment ChatMessageFragment on Message { __typename id conversationId renderedContent externalUid senderId aiRole turnSeq sentAt createdAt }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Message }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", DashXGql.UUID.self),
      .field("conversationId", DashXGql.UUID?.self),
      .field("renderedContent", DashXGql.JSON.self),
      .field("externalUid", String?.self),
      .field("senderId", DashXGql.UUID?.self),
      .field("aiRole", String?.self),
      .field("turnSeq", Int.self),
      .field("sentAt", DashXGql.Timestamp?.self),
      .field("createdAt", DashXGql.Timestamp.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ChatMessageFragment.self
    ] }

    var id: DashXGql.UUID { __data["id"] }
    var conversationId: DashXGql.UUID? { __data["conversationId"] }
    var renderedContent: DashXGql.JSON { __data["renderedContent"] }
    var externalUid: String? { __data["externalUid"] }
    var senderId: DashXGql.UUID? { __data["senderId"] }
    var aiRole: String? { __data["aiRole"] }
    var turnSeq: Int { __data["turnSeq"] }
    var sentAt: DashXGql.Timestamp? { __data["sentAt"] }
    var createdAt: DashXGql.Timestamp { __data["createdAt"] }

    init(
      id: DashXGql.UUID,
      conversationId: DashXGql.UUID? = nil,
      renderedContent: DashXGql.JSON,
      externalUid: String? = nil,
      senderId: DashXGql.UUID? = nil,
      aiRole: String? = nil,
      turnSeq: Int,
      sentAt: DashXGql.Timestamp? = nil,
      createdAt: DashXGql.Timestamp
    ) {
      self.init(unsafelyWithData: [
        "__typename": DashXGql.Objects.Message.typename,
        "id": id,
        "conversationId": conversationId,
        "renderedContent": renderedContent,
        "externalUid": externalUid,
        "senderId": senderId,
        "aiRole": aiRole,
        "turnSeq": turnSeq,
        "sentAt": sentAt,
        "createdAt": createdAt,
      ])
    }
  }

}