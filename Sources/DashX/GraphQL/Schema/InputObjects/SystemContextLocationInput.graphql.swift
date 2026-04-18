// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextLocationInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      latitude: GraphQLNullable<Decimal> = nil,
      longitude: GraphQLNullable<Decimal> = nil,
      city: GraphQLNullable<String> = nil,
      country: GraphQLNullable<String> = nil,
      speed: GraphQLNullable<Decimal> = nil
    ) {
      __data = InputDict([
        "latitude": latitude,
        "longitude": longitude,
        "city": city,
        "country": country,
        "speed": speed
      ])
    }

    public var latitude: GraphQLNullable<Decimal> {
      get { __data["latitude"] }
      set { __data["latitude"] = newValue }
    }

    public var longitude: GraphQLNullable<Decimal> {
      get { __data["longitude"] }
      set { __data["longitude"] = newValue }
    }

    public var city: GraphQLNullable<String> {
      get { __data["city"] }
      set { __data["city"] = newValue }
    }

    public var country: GraphQLNullable<String> {
      get { __data["country"] }
      set { __data["country"] = newValue }
    }

    public var speed: GraphQLNullable<Decimal> {
      get { __data["speed"] }
      set { __data["speed"] = newValue }
    }
  }

}