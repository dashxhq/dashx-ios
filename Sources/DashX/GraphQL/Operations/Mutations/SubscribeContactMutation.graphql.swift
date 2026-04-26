// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension DashXGql {
  class SubscribeContactMutation: GraphQLMutation {
    static let operationName: String = "SubscribeContact"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SubscribeContact($input: SubscribeContactInput!) { subscribeContact(input: $input) { __typename id value } }"#
      ))

    public var input: SubscribeContactInput

    public init(input: SubscribeContactInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("subscribeContact", SubscribeContact.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SubscribeContactMutation.Data.self
      ] }

      var subscribeContact: SubscribeContact { __data["subscribeContact"] }

      init(
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
      struct SubscribeContact: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Contact }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("value", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SubscribeContactMutation.Data.SubscribeContact.self
        ] }

        var id: DashXGql.UUID { __data["id"] }
        var value: String { __data["value"] }

        init(
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