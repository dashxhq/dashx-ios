import Foundation
import GraphQL
import SwiftGraphQL

extension SearchContentModel {
    static func input(
        contentType: String,
        returnType: String,
        filter: NSDictionary? = nil,
        order: NSDictionary? = nil,
        limit: Int? = nil,
        preview: Bool? = nil,
        language: String? = nil,
        fields: [String]? = nil,
        include: [String]? = nil,
        exclude: [String]? = nil
    ) -> InputObjects.SearchContentInput {
        let filterAsAnyCodable = AnyCodable(filter)
        let filter = OptionalArgument(present: filterAsAnyCodable)
        let orderAsAnyCodable = AnyCodable(order)
        let order = OptionalArgument(present: orderAsAnyCodable)
        let limit = OptionalArgument(present: limit)
        let preview = OptionalArgument(present: preview)
        let language = OptionalArgument(present: language)
        let fields = OptionalArgument(present: fields)
        let include = OptionalArgument(present: include)
        let exclude = OptionalArgument(present: exclude)
        
        return InputObjects.SearchContentInput(
            contentType: contentType,
            returnType: returnType,
            filter: filter,
            order: order,
            limit: limit,
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
