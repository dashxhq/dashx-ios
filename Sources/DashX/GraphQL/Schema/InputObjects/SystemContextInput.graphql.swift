// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension DashXGql {
  struct SystemContextInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      ipV4: String,
      ipV6: GraphQLNullable<String> = nil,
      locale: String,
      timeZone: String,
      userAgent: String,
      app: GraphQLNullable<SystemContextAppInput> = nil,
      device: GraphQLNullable<SystemContextDeviceInput> = nil,
      os: GraphQLNullable<SystemContextOsInput> = nil,
      library: GraphQLNullable<SystemContextLibraryInput> = nil,
      network: GraphQLNullable<SystemContextNetworkInput> = nil,
      screen: GraphQLNullable<SystemContextScreenInput> = nil,
      campaign: GraphQLNullable<SystemContextCampaignInput> = nil,
      location: GraphQLNullable<SystemContextLocationInput> = nil
    ) {
      __data = InputDict([
        "ipV4": ipV4,
        "ipV6": ipV6,
        "locale": locale,
        "timeZone": timeZone,
        "userAgent": userAgent,
        "app": app,
        "device": device,
        "os": os,
        "library": library,
        "network": network,
        "screen": screen,
        "campaign": campaign,
        "location": location
      ])
    }

    var ipV4: String {
      get { __data["ipV4"] }
      set { __data["ipV4"] = newValue }
    }

    var ipV6: GraphQLNullable<String> {
      get { __data["ipV6"] }
      set { __data["ipV6"] = newValue }
    }

    var locale: String {
      get { __data["locale"] }
      set { __data["locale"] = newValue }
    }

    var timeZone: String {
      get { __data["timeZone"] }
      set { __data["timeZone"] = newValue }
    }

    var userAgent: String {
      get { __data["userAgent"] }
      set { __data["userAgent"] = newValue }
    }

    var app: GraphQLNullable<SystemContextAppInput> {
      get { __data["app"] }
      set { __data["app"] = newValue }
    }

    var device: GraphQLNullable<SystemContextDeviceInput> {
      get { __data["device"] }
      set { __data["device"] = newValue }
    }

    var os: GraphQLNullable<SystemContextOsInput> {
      get { __data["os"] }
      set { __data["os"] = newValue }
    }

    var library: GraphQLNullable<SystemContextLibraryInput> {
      get { __data["library"] }
      set { __data["library"] = newValue }
    }

    var network: GraphQLNullable<SystemContextNetworkInput> {
      get { __data["network"] }
      set { __data["network"] = newValue }
    }

    var screen: GraphQLNullable<SystemContextScreenInput> {
      get { __data["screen"] }
      set { __data["screen"] = newValue }
    }

    var campaign: GraphQLNullable<SystemContextCampaignInput> {
      get { __data["campaign"] }
      set { __data["campaign"] = newValue }
    }

    var location: GraphQLNullable<SystemContextLocationInput> {
      get { __data["location"] }
      set { __data["location"] = newValue }
    }
  }

}