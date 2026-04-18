// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class IdentifyAccountMutation: GraphQLMutation {
    public static let operationName: String = "IdentifyAccount"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation IdentifyAccount($input: IdentifyAccountInput!) { identifyAccount(input: $input) { __typename id } }"#
      ))

    public var input: IdentifyAccountInput

    public init(input: IdentifyAccountInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("identifyAccount", IdentifyAccount.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        IdentifyAccountMutation.Data.self
      ] }

      public var identifyAccount: IdentifyAccount { __data["identifyAccount"] }

      public init(
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
      public struct IdentifyAccount: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Account }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DashXGql.UUID.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          IdentifyAccountMutation.Data.IdentifyAccount.self
        ] }

        public var id: DashXGql.UUID { __data["id"] }

        public init(
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