import Foundation

/**
 A type-erased `Encodable` value.

 The `StringEncodable` type forwards encoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode mixed-type values in dictionaries
 and other collections that require `Encodable` conformance
 by declaring their contained type to be `StringEncodable`:

     let dictionary: [String: StringEncodable] = [
         "boolean": true,
         "integer": 1,
         "double": 3.14159265358979323846,
         "string": "string",
         "array": [1, 2, 3],
         "nested": [
             "a": "alpha",
             "b": "bravo",
             "c": "charlie"
         ]
     ]

     let encoder = JSONEncoder()
     let json = try! encoder.encode(dictionary)
 */
public struct StringEncodable: Encodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

#if swift(>=4.2)
@usableFromInline
protocol _StringEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _StringEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension StringEncodable: _StringEncodable {}

// MARK: - Encodable

extension _StringEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull, is Void:
            try container.encodeNil()
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { StringCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { StringCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "StringCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

extension StringEncodable: Equatable {
    public static func == (lhs: StringEncodable, rhs: StringEncodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: StringEncodable], rhs as [String: StringEncodable]):
            return lhs == rhs
        case let (lhs as [StringEncodable], rhs as [StringEncodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension StringEncodable: CustomStringConvertible {
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

extension StringEncodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "StringEncodable(\(value.debugDescription))"
        default:
            return "StringEncodable(\(description))"
        }
    }
}

extension StringEncodable: ExpressibleByNilLiteral {}
extension StringEncodable: ExpressibleByStringLiteral {}
extension StringEncodable: ExpressibleByArrayLiteral {}
extension StringEncodable: ExpressibleByDictionaryLiteral {}

extension _StringEncodable {
    public init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { first, _ in first }))
    }
}
