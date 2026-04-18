// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class UnsubscribeContactMutation: GraphQLMutation {
    public static let operationName: String = "UnsubscribeContact"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UnsubscribeContact($input: UnsubscribeContactInput!) { unsubscribeContact(input: $input) { __typename id value } }"#
      ))

    public var input: UnsubscribeContactInput

    public init(input: UnsubscribeContactInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("unsubscribeContact", UnsubscribeContact.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnsubscribeContactMutation.Data.self
      ] }

      public var unsubscribeContact: UnsubscribeContact { __data["unsubscribeContact"] }

      public init(
        unsubscribeContact: UnsubscribeContact
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "unsubscribeContact": unsubscribeContact._fieldData,
        ])
      }

      /// UnsubscribeContact
      ///
      /// Parent Type: `Contact`
      public struct UnsubscribeContact: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Contact }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("value", String.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UnsubscribeContactMutation.Data.UnsubscribeContact.self
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