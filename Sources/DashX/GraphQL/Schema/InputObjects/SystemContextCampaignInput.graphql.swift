// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension DashXGql {
  struct SystemContextCampaignInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String,
      source: String,
      medium: String,
      term: String,
      content: String
    ) {
      __data = InputDict([
        "name": name,
        "source": source,
        "medium": medium,
        "term": term,
        "content": content
      ])
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var source: String {
      get { __data["source"] }
      set { __data["source"] = newValue }
    }

    public var medium: String {
      get { __data["medium"] }
      set { __data["medium"] = newValue }
    }

    public var term: String {
      get { __data["term"] }
      set { __data["term"] = newValue }
    }

    public var content: String {
      get { __data["content"] }
      set { __data["content"] = newValue }
    }
  }

}