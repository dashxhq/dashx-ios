import Foundation
import GraphQL
import SwiftGraphQL

extension FetchContentModel {
    static func input(
        contentId: String? = nil,
        contentType: String? = nil,
        content: String? = nil,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [String]? = nil,
        include: [String]? = nil,
        exclude: [String]? = nil
    ) -> InputObjects.FetchContentInput {
        let contentId = OptionalArgument(present: contentId)
        let contentType = OptionalArgument(present: contentType)
        let content = OptionalArgument(present: content)
        let preview = OptionalArgument(present: preview)
        let language = OptionalArgument(present: language)
        let fields = OptionalArgument(present: fields)
        let include = OptionalArgument(present: include)
        let exclude = OptionalArgument(present: exclude)
        
        return InputObjects.FetchContentInput(
            contentId: contentId,
            contentType: contentType,
            content: content,
            preview: preview,
            language: language,
            fields: fields,
            include: include,
            exclude: exclude
        )
    }
    
    // No Selection
    
    // No Query
}
