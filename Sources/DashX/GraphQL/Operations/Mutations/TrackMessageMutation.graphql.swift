// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension DashXGql {
  class TrackMessageMutation: GraphQLMutation {
    static let operationName: String = "TrackMessage"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation TrackMessage($input: TrackMessageInput!) { trackMessage(input: $input) { __typename success } }"#
      ))

    public var input: TrackMessageInput

    public init(input: TrackMessageInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("trackMessage", TrackMessage.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        TrackMessageMutation.Data.self
      ] }

      var trackMessage: TrackMessage { __data["trackMessage"] }

      init(
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
      struct TrackMessage: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.TrackMessageResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          TrackMessageMutation.Data.TrackMessage.self
        ] }

        var success: Bool { __data["success"] }

        init(
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