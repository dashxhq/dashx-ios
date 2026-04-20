// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension DashXGql {
  class TrackEventMutation: GraphQLMutation {
    static let operationName: String = "TrackEvent"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation TrackEvent($input: TrackEventInput!) { trackEvent(input: $input) { __typename success } }"#
      ))

    public var input: TrackEventInput

    public init(input: TrackEventInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: DashXGql.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("trackEvent", TrackEvent.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        TrackEventMutation.Data.self
      ] }

      var trackEvent: TrackEvent { __data["trackEvent"] }

      init(
        trackEvent: TrackEvent
      ) {
        self.init(unsafelyWithData: [
          "__typename": DashXGql.Objects.Mutation.typename,
          "trackEvent": trackEvent._fieldData,
        ])
      }

      /// TrackEvent
      ///
      /// Parent Type: `TrackEventResponse`
      struct TrackEvent: DashXGql.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.TrackEventResponse }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          TrackEventMutation.Data.TrackEvent.self
        ] }

        var success: Bool { __data["success"] }

        init(
          success: Bool
        ) {
          self.init(unsafelyWithData: [
            "__typename": DashXGql.Objects.TrackEventResponse.typename,
            "success": success,
          ])
        }
      }
    }
  }

}