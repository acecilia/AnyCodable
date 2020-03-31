import Foundation

/**
 A type-erased `Decodable` value.

 The `StringDecodable` type forwards decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can decode mixed-type values in dictionaries
 and other collections that require `Decodable` conformance
 by declaring their contained type to be `StringDecodable`:

     let json = """
     {
         "boolean": true,
         "integer": 1,
         "double": 3.14159265358979323846,
         "string": "string",
         "array": [1, 2, 3],
         "nested": {
             "a": "alpha",
             "b": "bravo",
             "c": "charlie"
         }
     }
     """.data(using: .utf8)!

     let decoder = JSONDecoder()
     let dictionary = try! decoder.decode([String: StringCodable].self, from: json)
 */
public struct StringDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

#if swift(>=4.2)
@usableFromInline
protocol _StringDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _StringDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension StringDecodable: _StringDecodable {}

extension _StringDecodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.init(NSNull())
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([StringCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: StringCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "StringCodable value cannot be decoded")
        }
    }
}

extension StringDecodable: Equatable {
    public static func == (lhs: StringDecodable, rhs: StringDecodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull), is (Void, Void):
            return true
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: StringDecodable], rhs as [String: StringDecodable]):
            return lhs == rhs
        case let (lhs as [StringDecodable], rhs as [StringDecodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension StringDecodable: CustomStringConvertible {
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

extension StringDecodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "StringDecodable(\(value.debugDescription))"
        default:
            return "StringDecodable(\(description))"
        }
    }
}
