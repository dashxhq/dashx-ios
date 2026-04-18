// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class SubscribeContactMutation: GraphQLMutation {
    public static let operationName: String = "SubscribeContact"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SubscribeContact($input: SubscribeContactInput!) { subscribeContact(input: $input) { __typename id value } }"#
      ))

    public var input: SubscribeContactInput

    public init(input: SubscribeContactInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("subscribeContact", SubscribeContact.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubscribeContactMutation.Data.self
      ] }

      public var subscribeContact: SubscribeContact { __data["subscribeContact"] }

      public init(
        subscribeContact: SubscribeContact
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "subscribeContact": subscribeContact._fieldData,
        ])
      }

      /// SubscribeContact
      ///
      /// Parent Type: `Contact`
      public struct SubscribeContact: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Contact }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("value", String.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubscribeContactMutation.Data.SubscribeContact.self
        ] }

        public var id: DashXGql.UUID { __data["id"] }
        public var value: String { __data["value"] }

        public init(
          id: DashXGql.UUID,
          value: String
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.Contact.typename,
            "id": id,
            "value": value,
          ])
        }
      }
    }
  }

}