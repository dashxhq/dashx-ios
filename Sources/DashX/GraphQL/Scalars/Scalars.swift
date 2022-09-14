import Foundation
import GraphQL
import SwiftGraphQL

typealias DateScalar     = String
typealias DateTimeScalar = String
typealias DecimalScalar  = String
typealias JSONScalar     = AnyCodable
typealias UUIDScalar     = String
typealias UploadScalar   = String

enum DecodingError: Error {
    case invalidType
    case invalidValue
}
