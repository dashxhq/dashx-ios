// @generated
// This file was automatically generated and should not be edited.

@_implementationOnly import ApolloAPI

extension DashXGql {
  struct SystemContextCampaignInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
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

    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var source: String {
      get { __data["source"] }
      set { __data["source"] = newValue }
    }

    var medium: String {
      get { __data["medium"] }
      set { __data["medium"] = newValue }
    }

    var term: String {
      get { __data["term"] }
      set { __data["term"] = newValue }
    }

    var content: String {
      get { __data["content"] }
      set { __data["content"] = newValue }
    }
  }

}