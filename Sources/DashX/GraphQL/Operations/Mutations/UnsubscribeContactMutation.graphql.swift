// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class UnsubscribeContactMutation: GraphQLMutation {
    static let operationName: String = "UnsubscribeContact"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UnsubscribeContact($input: UnsubscribeContactInput!) { unsubscribeContact(input: $input) { __typename id value } }"#
      ))

    public var input: UnsubscribeContactInput

    public init(input: UnsubscribeContactInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("unsubscribeContact", UnsubscribeContact.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnsubscribeContactMutation.Data.self
      ] }

      var unsubscribeContact: UnsubscribeContact { __data["unsubscribeContact"] }

      init(
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
      struct UnsubscribeContact: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Contact }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
          .field("value", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UnsubscribeContactMutation.Data.UnsubscribeContact.self
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