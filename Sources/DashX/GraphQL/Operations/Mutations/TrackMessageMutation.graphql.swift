// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class TrackMessageMutation: GraphQLMutation {
    public static let operationName: String = "TrackMessage"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation TrackMessage($input: TrackMessageInput!) { trackMessage(input: $input) { __typename success } }"#
      ))

    public var input: TrackMessageInput

    public init(input: TrackMessageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("trackMessage", TrackMessage.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        TrackMessageMutation.Data.self
      ] }

      public var trackMessage: TrackMessage { __data["trackMessage"] }

      public init(
        trackMessage: TrackMessage
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "trackMessage": trackMessage._fieldData,
        ])
      }

      /// TrackMessage
      ///
      /// Parent Type: `TrackMessageResponse`
      public struct TrackMessage: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.TrackMessageResponse }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          TrackMessageMutation.Data.TrackMessage.self
        ] }

        public var success: Bool { __data["success"] }

        public init(
          success: Bool
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.TrackMessageResponse.typename,
            "success": success,
          ])
        }
      }
    }
  }

}