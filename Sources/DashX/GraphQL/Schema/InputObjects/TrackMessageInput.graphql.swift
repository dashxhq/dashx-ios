// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct TrackMessageInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var id: UUID {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    var status: GraphQLEnum<TrackMessageStatus> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    var timestamp: Timestamp {
      get { __data["timestamp"] }
      set { __data["timestamp"] = newValue }
    }
  }

}