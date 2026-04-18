// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct TrackEventInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      event: String,
      accountUid: GraphQLNullable<String> = nil,
      accountAnonymousUid: GraphQLNullable<String> = nil,
      data: GraphQLNullable<JSON> = nil,
      timestamp: GraphQLNullable<Timestamp> = nil,
      systemContext: GraphQLNullable<SystemContextInput> = nil
    ) {
      __data = InputDict([
        "event": event,
        "accountUid": accountUid,
        "accountAnonymousUid": accountAnonymousUid,
        "data": data,
        "timestamp": timestamp,
        "systemContext": systemContext
      ])
    }

    public var event: String {
      get { __data["event"] }
      set { __data["event"] = newValue }
    }

    public var accountUid: GraphQLNullable<String> {
      get { __data["accountUid"] }
      set { __data["accountUid"] = newValue }
    }

    public var accountAnonymousUid: GraphQLNullable<String> {
      get { __data["accountAnonymousUid"] }
      set { __data["accountAnonymousUid"] = newValue }
    }

    public var data: GraphQLNullable<JSON> {
      get { __data["data"] }
      set { __data["data"] = newValue }
    }

    public var timestamp: GraphQLNullable<Timestamp> {
      get { __data["timestamp"] }
      set { __data["timestamp"] = newValue }
    }

    public var systemContext: GraphQLNullable<SystemContextInput> {
      get { __data["systemContext"] }
      set { __data["systemContext"] = newValue }
    }
  }

}