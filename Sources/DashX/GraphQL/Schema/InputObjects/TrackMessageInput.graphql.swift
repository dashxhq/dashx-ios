// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct TrackMessageInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      id: UUID,
      status: GraphQLEnum<TrackMessageStatus>,
      timestamp: Timestamp
    ) {
      __data = InputDict([
        "id": id,
        "status": status,
        "timestamp": timestamp
      ])
    }

    public var id: UUID {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    public var status: GraphQLEnum<TrackMessageStatus> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    public var timestamp: Timestamp {
      get { __data["timestamp"] }
      set { __data["timestamp"] = newValue }
    }
  }

}