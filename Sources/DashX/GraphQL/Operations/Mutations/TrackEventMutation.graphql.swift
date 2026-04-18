// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension DashXGql {
  class TrackEventMutation: GraphQLMutation {
    public static let operationName: String = "TrackEvent"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation TrackEvent($input: TrackEventInput!) { trackEvent(input: $input) { __typename success } }"#
      ))

    public var input: TrackEventInput

    public init(input: TrackEventInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: DashXGql.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("trackEvent", TrackEvent.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        TrackEventMutation.Data.self
      ] }

      public var trackEvent: TrackEvent { __data["trackEvent"] }

      public init(
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
      public struct TrackEvent: DashXGql.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DashXGql.Objects.TrackEventResponse }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          TrackEventMutation.Data.TrackEvent.self
        ] }

        public var success: Bool { __data["success"] }

        public init(
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