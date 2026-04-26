// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct SystemContextLocationInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var latitude: GraphQLNullable<Decimal> {
      get { __data["latitude"] }
      set { __data["latitude"] = newValue }
    }

    var longitude: GraphQLNullable<Decimal> {
      get { __data["longitude"] }
      set { __data["longitude"] = newValue }
    }

    var city: GraphQLNullable<String> {
      get { __data["city"] }
      set { __data["city"] = newValue }
    }

    var country: GraphQLNullable<String> {
      get { __data["country"] }
      set { __data["country"] = newValue }
    }

    var speed: GraphQLNullable<Decimal> {
      get { __data["speed"] }
      set { __data["speed"] = newValue }
    }
  }

}