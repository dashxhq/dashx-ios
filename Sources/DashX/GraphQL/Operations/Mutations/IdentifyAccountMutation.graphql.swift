// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  class IdentifyAccountMutation: GraphQLMutation {
    static let operationName: String = "IdentifyAccount"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation IdentifyAccount($input: IdentifyAccountInput!) { identifyAccount(input: $input) { __typename id } }"#
      ))

    public var input: IdentifyAccountInput

    public init(input: IdentifyAccountInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("identifyAccount", IdentifyAccount.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        IdentifyAccountMutation.Data.self
      ] }

      var identifyAccount: IdentifyAccount { __data["identifyAccount"] }

      init(
        identifyAccount: IdentifyAccount
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "identifyAccount": identifyAccount._fieldData,
        ])
      }

      /// IdentifyAccount
      ///
      /// Parent Type: `Account`
      struct IdentifyAccount: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Account }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          IdentifyAccountMutation.Data.IdentifyAccount.self
        ] }

        var id: DashXGql.UUID { __data["id"] }

        init(
          id: DashXGql.UUID
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.Account.typename,
            "id": id,
          ])
        }
      }
    }
  }

}