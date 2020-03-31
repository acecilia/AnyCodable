import Foundation

/**
 A type-erased `Codable` value.

 The `StringCodable` type forwards encoding and decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode or decode mixed-type values in dictionaries
 and other collections that require `Encodable` or `Decodable` conformance
 by declaring their contained type to be `StringCodable`.

 - SeeAlso: `StringEncodable`
 - SeeAlso: `StringDecodable`
 */
public struct StringCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension StringCodable: _StringEncodable, _StringDecodable {}

extension StringCodable: Equatable {
    public static func == (lhs: StringCodable, rhs: StringCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: StringCodable], rhs as [String: StringCodable]):
            return lhs == rhs
        case let (lhs as [StringCodable], rhs as [StringCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension StringCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension StringCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "StringCodable(\(value.debugDescription))"
        default:
            return "StringCodable(\(description))"
        }
    }
}

extension StringCodable: ExpressibleByNilLiteral {}
extension StringCodable: ExpressibleByStringLiteral {}
extension StringCodable: ExpressibleByArrayLiteral {}
extension StringCodable: ExpressibleByDictionaryLiteral {}
