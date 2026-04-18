// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import ApolloAPI
import Foundation

public extension DashXGql {
  /// A scalar that can represent any JSON value — object, array, string, number, bool, null.
  ///
  /// Backed by `ApolloAPI.JSONValue` (an `AnyHashable` in Apollo iOS 1.x) so it can
  /// round-trip any shape the server might emit for a `JSON`-typed field. Backend
  /// resolvers that require a specific shape (e.g. `track_event.rs::validate_event_data`
  /// requires `data.is_object()`) are still satisfied — the scalar serializes on the
  /// wire as the underlying JSON value, not a stringified JSON literal.
  ///
  /// Convenience accessors (`asDictionary`, `asArray`, `asString`, ...) return nil when
  /// the underlying value has a different shape; prefer them to raw `value as? T` casts.
  struct JSON: CustomScalarType {
    public let value: JSONValue

    /// Construct from any `Hashable` value — dictionary, array, primitive.
    public init<T: Hashable>(_ value: T) {
      self.value = AnyHashable(value)
    }

    public init(_jsonValue value: JSONValue) throws {
      self.value = value
    }

    public var _jsonValue: JSONValue { value }
  }
}

extension DashXGql.JSON: Hashable {}

public extension DashXGql.JSON {
  /// Unwraps to `[String: AnyHashable]` when the scalar carries a JSON object. Nil otherwise.
  var asDictionary: [String: AnyHashable]? {
    value as? [String: AnyHashable]
  }

  /// Unwraps to `[AnyHashable]` when the scalar carries a JSON array. Nil otherwise.
  var asArray: [AnyHashable]? {
    value as? [AnyHashable]
  }

  var asString: String? { value as? String }
  var asBool: Bool? { value as? Bool }
  var asInt: Int? { value as? Int }
  var asDouble: Double? { value as? Double }
  var isNull: Bool { value.base is NSNull }
}
