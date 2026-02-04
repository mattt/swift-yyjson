import Foundation
import Testing

@testable import YYJSON

#if !YYJSON_DISABLE_READER

    // MARK: - Basic Type Decoding Tests

    @Suite("YYJSONDecoder - Basic Types")
    struct DecoderBasicTypesTests {
        @Test func decodeString() throws {
            let json = #""hello world""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(String.self, from: data)
            #expect(result == "hello world")
        }

        @Test func decodeEmptyString() throws {
            let json = #""""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(String.self, from: data)
            #expect(result == "")
        }

        @Test func decodeStringWithUnicode() throws {
            let json = #""Hello 你好 🌍""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(String.self, from: data)
            #expect(result == "Hello 你好 🌍")
        }

        @Test func decodeStringWithEscapes() throws {
            let json = #""line1\nline2\ttab""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(String.self, from: data)
            #expect(result == "line1\nline2\ttab")
        }

        @Test func decodeInt() throws {
            let json = "42"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int.self, from: data)
            #expect(result == 42)
        }

        @Test func decodeNegativeInt() throws {
            let json = "-123"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int.self, from: data)
            #expect(result == -123)
        }

        @Test func decodeZero() throws {
            let json = "0"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int.self, from: data)
            #expect(result == 0)
        }

        @Test func decodeInt8() throws {
            let json = "127"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int8.self, from: data)
            #expect(result == 127)
        }

        @Test func decodeInt16() throws {
            let json = "32767"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int16.self, from: data)
            #expect(result == 32767)
        }

        @Test func decodeInt32() throws {
            let json = "2147483647"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int32.self, from: data)
            #expect(result == 2147483647)
        }

        @Test func decodeInt64() throws {
            let json = "9223372036854775807"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Int64.self, from: data)
            #expect(result == 9223372036854775807)
        }

        @Test func decodeUInt() throws {
            let json = "42"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(UInt.self, from: data)
            #expect(result == 42)
        }

        @Test func decodeUInt8() throws {
            let json = "255"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(UInt8.self, from: data)
            #expect(result == 255)
        }

        @Test func decodeUInt16() throws {
            let json = "65535"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(UInt16.self, from: data)
            #expect(result == 65535)
        }

        @Test func decodeUInt32() throws {
            let json = "4294967295"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(UInt32.self, from: data)
            #expect(result == 4294967295)
        }

        @Test func decodeUInt64() throws {
            let json = "18446744073709551615"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(UInt64.self, from: data)
            #expect(result == 18446744073709551615)
        }

        @Test func decodeDouble() throws {
            let json = "3.14159"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(abs(result - 3.14159) < 0.00001)
        }

        @Test func decodeFloat() throws {
            let json = "3.14"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Float.self, from: data)
            #expect(abs(result - 3.14) < 0.001)
        }

        @Test func decodeNegativeDouble() throws {
            let json = "-2.718"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(abs(result - (-2.718)) < 0.001)
        }

        @Test func decodeScientificNotation() throws {
            let json = "1.23e10"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(abs(result - 1.23e10) < 1e5)
        }

        @Test func decodeBoolTrue() throws {
            let json = "true"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Bool.self, from: data)
            #expect(result == true)
        }

        @Test func decodeBoolFalse() throws {
            let json = "false"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Bool.self, from: data)
            #expect(result == false)
        }

        @Test func decodeNull() throws {
            let json = "null"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(String?.self, from: data)
            #expect(result == nil)
        }
    }

    // MARK: - Collection Decoding Tests

    @Suite("YYJSONDecoder - Collections")
    struct DecoderCollectionTests {
        @Test func decodeEmptyArray() throws {
            let json = "[]"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([Int].self, from: data)
            #expect(result.isEmpty)
        }

        @Test func decodeIntArray() throws {
            let json = "[1, 2, 3, 4, 5]"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([Int].self, from: data)
            #expect(result == [1, 2, 3, 4, 5])
        }

        @Test func decodeStringArray() throws {
            let json = #"["a", "b", "c"]"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([String].self, from: data)
            #expect(result == ["a", "b", "c"])
        }

        @Test func decodeNestedArray() throws {
            let json = "[[1, 2], [3, 4], [5, 6]]"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([[Int]].self, from: data)
            #expect(result == [[1, 2], [3, 4], [5, 6]])
        }

        @Test func decodeEmptyObject() throws {
            let json = "{}"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([String: Int].self, from: data)
            #expect(result.isEmpty)
        }

        @Test func decodeDictionary() throws {
            let json = #"{"a": 1, "b": 2, "c": 3}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([String: Int].self, from: data)
            #expect(result == ["a": 1, "b": 2, "c": 3])
        }

        @Test func decodeNestedDictionary() throws {
            let json = #"{"outer": {"inner": 42}}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([String: [String: Int]].self, from: data)
            #expect(result == ["outer": ["inner": 42]])
        }

        @Test func decodeArrayOfOptionals() throws {
            let json = #"[1, null, 3, null, 5]"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([Int?].self, from: data)
            #expect(result.count == 5)
            #expect(result[0] == 1)
            #expect(result[1] == nil)
            #expect(result[2] == 3)
            #expect(result[3] == nil)
            #expect(result[4] == 5)
        }
    }

    // MARK: - Struct Decoding Tests

    @Suite("YYJSONDecoder - Structs")
    struct DecoderStructTests {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let age: Int
            let active: Bool
        }

        @Test func decodeSimpleStruct() throws {
            let json = #"{"name": "Alice", "age": 30, "active": true}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(SimpleStruct.self, from: data)
            #expect(result == SimpleStruct(name: "Alice", age: 30, active: true))
        }

        struct NestedStruct: Codable, Equatable {
            struct Inner: Codable, Equatable {
                let value: String
            }
            let inner: Inner
        }

        @Test func decodeNestedStruct() throws {
            let json = #"{"inner": {"value": "nested"}}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(NestedStruct.self, from: data)
            #expect(result.inner.value == "nested")
        }

        struct StructWithOptionals: Codable, Equatable {
            let required: String
            let optional: String?
        }

        @Test func decodeStructWithPresentOptional() throws {
            let json = #"{"required": "yes", "optional": "present"}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(StructWithOptionals.self, from: data)
            #expect(result.required == "yes")
            #expect(result.optional == "present")
        }

        @Test func decodeStructWithMissingOptional() throws {
            let json = #"{"required": "yes"}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(StructWithOptionals.self, from: data)
            #expect(result.required == "yes")
            #expect(result.optional == nil)
        }

        @Test func decodeStructWithNullOptional() throws {
            let json = #"{"required": "yes", "optional": null}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(StructWithOptionals.self, from: data)
            #expect(result.required == "yes")
            #expect(result.optional == nil)
        }

        struct StructWithDefaults: Codable {
            let value: Int

            init(value: Int = 42) {
                self.value = value
            }
        }

        struct StructWithArray: Codable, Equatable {
            let items: [String]
        }

        @Test func decodeStructWithArray() throws {
            let json = #"{"items": ["a", "b", "c"]}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(StructWithArray.self, from: data)
            #expect(result.items == ["a", "b", "c"])
        }

        struct AllNumericTypes: Codable, Equatable {
            let int: Int
            let int8: Int8
            let int16: Int16
            let int32: Int32
            let int64: Int64
            let uint: UInt
            let uint8: UInt8
            let uint16: UInt16
            let uint32: UInt32
            let uint64: UInt64
            let float: Float
            let double: Double
        }

        @Test func decodeAllNumericTypes() throws {
            let json = """
                {
                    "int": 1,
                    "int8": 2,
                    "int16": 3,
                    "int32": 4,
                    "int64": 5,
                    "uint": 6,
                    "uint8": 7,
                    "uint16": 8,
                    "uint32": 9,
                    "uint64": 10,
                    "float": 1.5,
                    "double": 2.5
                }
                """
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(AllNumericTypes.self, from: data)
            #expect(result.int == 1)
            #expect(result.int8 == 2)
            #expect(result.int16 == 3)
            #expect(result.int32 == 4)
            #expect(result.int64 == 5)
            #expect(result.uint == 6)
            #expect(result.uint8 == 7)
            #expect(result.uint16 == 8)
            #expect(result.uint32 == 9)
            #expect(result.uint64 == 10)
            #expect(abs(result.float - 1.5) < 0.001)
            #expect(abs(result.double - 2.5) < 0.001)
        }
    }

    // MARK: - Enum Decoding Tests

    @Suite("YYJSONDecoder - Enums")
    struct DecoderEnumTests {
        enum StringEnum: String, Codable {
            case first
            case second
            case third
        }

        @Test func decodeStringEnum() throws {
            let json = #""second""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(StringEnum.self, from: data)
            #expect(result == .second)
        }

        enum IntEnum: Int, Codable {
            case zero = 0
            case one = 1
            case two = 2
        }

        @Test func decodeIntEnum() throws {
            let json = "1"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(IntEnum.self, from: data)
            #expect(result == .one)
        }

        enum EnumWithAssociatedValues: Codable, Equatable {
            case text(String)
            case number(Int)
            case nothing

            private enum CodingKeys: String, CodingKey {
                case type, value
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)
                switch type {
                case "text":
                    self = .text(try container.decode(String.self, forKey: .value))
                case "number":
                    self = .number(try container.decode(Int.self, forKey: .value))
                case "nothing":
                    self = .nothing
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .type,
                        in: container,
                        debugDescription: "Unknown type"
                    )
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .text(let value):
                    try container.encode("text", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .number(let value):
                    try container.encode("number", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .nothing:
                    try container.encode("nothing", forKey: .type)
                }
            }
        }

        @Test func decodeEnumWithAssociatedTextValue() throws {
            let json = #"{"type": "text", "value": "hello"}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(EnumWithAssociatedValues.self, from: data)
            #expect(result == .text("hello"))
        }

        @Test func decodeEnumWithAssociatedNumberValue() throws {
            let json = #"{"type": "number", "value": 42}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(EnumWithAssociatedValues.self, from: data)
            #expect(result == .number(42))
        }
    }

    // MARK: - Key Decoding Strategy Tests

    @Suite("YYJSONDecoder - Key Decoding Strategies")
    struct DecoderKeyStrategyTests {
        struct SnakeCaseStruct: Codable, Equatable {
            let firstName: String
            let lastName: String
            let phoneNumber: String
        }

        @Test func decodeWithSnakeCaseConversion() throws {
            let json = #"{"first_name": "John", "last_name": "Doe", "phone_number": "123-456"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(SnakeCaseStruct.self, from: data)
            #expect(result.firstName == "John")
            #expect(result.lastName == "Doe")
            #expect(result.phoneNumber == "123-456")
        }

        @Test func decodeWithDefaultKeys() throws {
            let json = #"{"firstName": "John", "lastName": "Doe", "phoneNumber": "123-456"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let result = try decoder.decode(SnakeCaseStruct.self, from: data)
            #expect(result.firstName == "John")
        }

        struct CustomKeyStruct: Codable {
            let value: String
        }

        @Test func decodeWithCustomKeyStrategy() throws {
            let json = #"{"VALUE": "test"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.keyDecodingStrategy = .custom { keys in
                let lastKey = keys.last!
                return AnyCodingKey(stringValue: lastKey.stringValue.lowercased())
            }
            let result = try decoder.decode(CustomKeyStruct.self, from: data)
            #expect(result.value == "test")
        }
    }

    // MARK: - Date Decoding Strategy Tests

    @Suite("YYJSONDecoder - Date Decoding Strategies")
    struct DecoderDateStrategyTests {
        struct DateContainer: Codable {
            let date: Date
        }

        @Test func decodeDateAsSecondsSince1970() throws {
            let json = #"{"date": 1609459200.0}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let result = try decoder.decode(DateContainer.self, from: data)
            #expect(result.date.timeIntervalSince1970 > 0)
        }

        @Test func decodeDateAsMillisecondsSince1970() throws {
            let json = #"{"date": 1609459200000.0}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let result = try decoder.decode(DateContainer.self, from: data)
            #expect(result.date.timeIntervalSince1970 > 0)
        }

        @Test func decodeDateAsISO8601() throws {
            let json = #"{"date": "2021-01-01T00:00:00Z"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(DateContainer.self, from: data)
            #expect(result.date.timeIntervalSince1970 == 1609459200)
        }

        @Test func decodeDateAsISO8601WithFractionalSeconds() throws {
            let json = #"{"date": "2021-01-01T00:00:00.123Z"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(DateContainer.self, from: data)
            #expect(abs(result.date.timeIntervalSince1970 - 1609459200.123) < 0.001)
        }

        @Test func decodeDateWithFormatter() throws {
            let json = #"{"date": "01/01/2021"}"#
            let data = json.data(using: .utf8)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            formatter.timeZone = TimeZone(identifier: "UTC")
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .formatted(formatter)
            let result = try decoder.decode(DateContainer.self, from: data)
            let calendar = Calendar(identifier: .gregorian)
            var components = DateComponents()
            components.year = 2021
            components.month = 1
            components.day = 1
            components.timeZone = TimeZone(identifier: "UTC")
            let expected = calendar.date(from: components)!
            #expect(abs(result.date.timeIntervalSince1970 - expected.timeIntervalSince1970) < 1)
        }

        @Test func decodeDateWithCustomStrategy() throws {
            let json = #"{"date": "2021-01-01"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(identifier: "UTC")
                guard let date = formatter.date(from: string) else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date"
                    )
                }
                return date
            }
            let result = try decoder.decode(DateContainer.self, from: data)
            let calendar = Calendar(identifier: .gregorian)
            var components = DateComponents()
            components.year = 2021
            components.month = 1
            components.day = 1
            components.timeZone = TimeZone(identifier: "UTC")
            let expected = calendar.date(from: components)!
            #expect(abs(result.date.timeIntervalSince1970 - expected.timeIntervalSince1970) < 1)
        }
    }

    // MARK: - Data Decoding Strategy Tests

    @Suite("YYJSONDecoder - Data Decoding Strategies")
    struct DecoderDataStrategyTests {
        struct DataContainer: Codable {
            let data: Data
        }

        @Test func decodeDataAsBase64() throws {
            let json = #"{"data": "SGVsbG8gV29ybGQ="}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dataDecodingStrategy = .base64
            let result = try decoder.decode(DataContainer.self, from: data)
            #expect(String(data: result.data, encoding: .utf8) == "Hello World")
        }

        @Test func decodeDataWithCustomStrategy() throws {
            let json = #"{"data": "48656c6c6f"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.dataDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let hexString = try container.decode(String.self)
                var data = Data()
                var hex = hexString
                while hex.count >= 2 {
                    let byte = String(hex.prefix(2))
                    hex = String(hex.dropFirst(2))
                    if let value = UInt8(byte, radix: 16) {
                        data.append(value)
                    }
                }
                return data
            }
            let result = try decoder.decode(DataContainer.self, from: data)
            #expect(String(data: result.data, encoding: .utf8) == "Hello")
        }
    }

    // MARK: - Non-Conforming Float Strategy Tests

    @Suite("YYJSONDecoder - Non-Conforming Float Strategies")
    struct DecoderNonConformingFloatTests {
        struct FloatContainer: Codable {
            let value: Double
        }

        @Test func decodeNonConformingFloatFromString() throws {
            let json = #"{"value": "Infinity"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(
                positiveInfinity: "Infinity",
                negativeInfinity: "-Infinity",
                nan: "NaN"
            )
            let result = try decoder.decode(FloatContainer.self, from: data)
            #expect(result.value.isInfinite)
            #expect(result.value > 0)
        }

        @Test func decodeNegativeInfinityFromString() throws {
            let json = #"{"value": "-Infinity"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(
                positiveInfinity: "Infinity",
                negativeInfinity: "-Infinity",
                nan: "NaN"
            )
            let result = try decoder.decode(FloatContainer.self, from: data)
            #expect(result.value.isInfinite)
            #expect(result.value < 0)
        }

        @Test func decodeNaNFromString() throws {
            let json = #"{"value": "NaN"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(
                positiveInfinity: "Infinity",
                negativeInfinity: "-Infinity",
                nan: "NaN"
            )
            let result = try decoder.decode(FloatContainer.self, from: data)
            #expect(result.value.isNaN)
        }
    }

    // MARK: - JSON5 Decoding Tests

    #if !YYJSON_DISABLE_NON_STANDARD

        @Suite("YYJSONDecoder - JSON5")
        struct DecoderJSON5Tests {
            struct SimpleStruct: Codable {
                let name: String
                let value: Int
            }

            @Test func decodeJSON5WithTrailingComma() throws {
                let json = #"{"name": "test", "value": 42,}"#
                let data = json.data(using: .utf8)!
                var decoder = YYJSONDecoder()
                decoder.allowsJSON5 = true
                let result = try decoder.decode(SimpleStruct.self, from: data)
                #expect(result.name == "test")
                #expect(result.value == 42)
            }

            @Test func decodeJSON5WithComments() throws {
                let json = """
                    {
                        // This is a comment
                        "name": "test",
                        /* Multi-line
                           comment */
                        "value": 42
                    }
                    """
                let data = json.data(using: .utf8)!
                var decoder = YYJSONDecoder()
                decoder.allowsJSON5 = true
                let result = try decoder.decode(SimpleStruct.self, from: data)
                #expect(result.name == "test")
                #expect(result.value == 42)
            }

            @Test func decodeJSON5WithSingleQuotes() throws {
                let json = #"{'name': 'test', 'value': 42}"#
                let data = json.data(using: .utf8)!
                var decoder = YYJSONDecoder()
                decoder.allowsJSON5 = true
                let result = try decoder.decode(SimpleStruct.self, from: data)
                #expect(result.name == "test")
                #expect(result.value == 42)
            }

            @Test func decodeJSON5WithUnquotedKeys() throws {
                let json = #"{name: "test", value: 42}"#
                let data = json.data(using: .utf8)!
                var decoder = YYJSONDecoder()
                decoder.allowsJSON5 = true
                let result = try decoder.decode(SimpleStruct.self, from: data)
                #expect(result.name == "test")
                #expect(result.value == 42)
            }

            @Test func decodeJSON5WithSelectiveOptions() throws {
                let json = #"{"name": "test", "value": 42,}"#
                let data = json.data(using: .utf8)!
                var decoder = YYJSONDecoder()
                decoder.allowsJSON5 = JSON5DecodingOptions(trailingCommas: true)
                let result = try decoder.decode(SimpleStruct.self, from: data)
                #expect(result.name == "test")
            }
        }

    #endif  // !YYJSON_DISABLE_NON_STANDARD

    // MARK: - UserInfo Tests

    @Suite("YYJSONDecoder - UserInfo")
    struct DecoderUserInfoTests {
        struct UserInfoAwareStruct: Codable {
            let value: String

            private enum CodingKeys: String, CodingKey {
                case value
            }

            init(value: String) {
                self.value = value
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let rawValue = try container.decode(String.self, forKey: .value)
                if let prefix = decoder.userInfo[CodingUserInfoKey(rawValue: "prefix")!] as? String {
                    self.value = prefix + rawValue
                } else {
                    self.value = rawValue
                }
            }
        }

        @Test func decodeWithUserInfo() throws {
            let json = #"{"value": "world"}"#
            let data = json.data(using: .utf8)!
            var decoder = YYJSONDecoder()
            decoder.userInfo[CodingUserInfoKey(rawValue: "prefix")!] = "hello "
            let result = try decoder.decode(UserInfoAwareStruct.self, from: data)
            #expect(result.value == "hello world")
        }
    }

    // MARK: - Numeric Type Coercion Tests

    @Suite("YYJSONDecoder - Numeric Type Coercion")
    struct DecoderNumericCoercionTests {
        @Test func decodeJSONIntegerAsDouble() throws {
            // JSON integer 1 should decode as Double 1.0
            let json = "1"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(result == 1.0, "JSON integer 1 should decode as Double 1.0, got \(result)")
        }

        @Test func decodeJSONNegativeIntegerAsDouble() throws {
            let json = "-42"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(result == -42.0, "JSON integer -42 should decode as Double -42.0, got \(result)")
        }

        @Test func decodeJSONZeroIntegerAsDouble() throws {
            let json = "0"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(result == 0.0, "JSON integer 0 should decode as Double 0.0, got \(result)")
        }

        @Test func decodeJSONLargeIntegerAsDouble() throws {
            let json = "9007199254740992"  // 2^53
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(result == 9007199254740992.0)
        }

        @Test func decodeJSONIntegerAsFloat() throws {
            let json = "42"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Float.self, from: data)
            #expect(result == 42.0, "JSON integer 42 should decode as Float 42.0, got \(result)")
        }

        // Real-world scenario from bug report: Color with alpha as integer
        struct Color: Codable, Equatable {
            let r, g, b, a: Double
        }

        @Test func decodeColorWithIntegerAlpha() throws {
            // Simulates Figma API response where alpha is 1 instead of 1.0
            let json = #"{"r": 0.5, "g": 0.5, "b": 0.5, "a": 1}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Color.self, from: data)
            #expect(result.r == 0.5)
            #expect(result.g == 0.5)
            #expect(result.b == 0.5)
            #expect(result.a == 1.0, "Integer alpha 1 should decode as 1.0, got \(result.a)")
        }

        @Test func decodeColorWithMixedIntegerAndFloatComponents() throws {
            let json = #"{"r": 1, "g": 0, "b": 0.5, "a": 1}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Color.self, from: data)
            #expect(result.r == 1.0, "Integer r=1 should decode as 1.0, got \(result.r)")
            #expect(result.g == 0.0, "Integer g=0 should decode as 0.0, got \(result.g)")
            #expect(result.b == 0.5)
            #expect(result.a == 1.0, "Integer a=1 should decode as 1.0, got \(result.a)")
        }

        @Test func decodeJSONIntegerAsDoubleInArray() throws {
            let json = "[1, 2.5, 3]"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode([Double].self, from: data)
            #expect(result[0] == 1.0, "Array element 1 should decode as 1.0, got \(result[0])")
            #expect(result[1] == 2.5)
            #expect(result[2] == 3.0, "Array element 3 should decode as 3.0, got \(result[2])")
        }

        // Verify Foundation JSONDecoder behavior for comparison
        @Test func foundationDecoderBehaviorReference() throws {
            let json = #"{"r": 0.5, "g": 0.5, "b": 0.5, "a": 1}"#
            let data = json.data(using: .utf8)!
            let foundationResult = try JSONDecoder().decode(Color.self, from: data)
            #expect(foundationResult.a == 1.0, "Foundation: Integer alpha 1 should decode as 1.0")

            let yyResult = try YYJSONDecoder().decode(Color.self, from: data)
            #expect(
                yyResult.a == foundationResult.a,
                "YYJSONDecoder should match Foundation behavior: expected \(foundationResult.a), got \(yyResult.a)"
            )
        }
    }

    // MARK: - Error Handling Tests

    @Suite("YYJSONDecoder - Error Handling")
    struct DecoderErrorTests {
        @Test func decodeInvalidJSON() throws {
            let json = "not valid json"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            #expect(throws: YYJSONError.self) {
                _ = try decoder.decode(String.self, from: data)
            }
        }

        @Test func decodeEmptyData() throws {
            let data = Data()
            let decoder = YYJSONDecoder()
            #expect(throws: YYJSONError.self) {
                _ = try decoder.decode(String.self, from: data)
            }
        }

        @Test func decodeTypeMismatch() throws {
            let json = #""hello""#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            #expect(throws: YYJSONError.self) {
                _ = try decoder.decode(Int.self, from: data)
            }
        }

        struct RequiredField: Codable {
            let required: String
        }

        @Test func decodeMissingRequiredField() throws {
            let json = "{}"
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            #expect(throws: YYJSONError.self) {
                _ = try decoder.decode(RequiredField.self, from: data)
            }
        }

        @Test func decodeIncompleteJSON() throws {
            let json = #"{"name": "#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            #expect(throws: YYJSONError.self) {
                _ = try decoder.decode([String: String].self, from: data)
            }
        }
    }

    // MARK: - Superclass/Subclass Decoding Tests

    @Suite("YYJSONDecoder - Inheritance")
    struct DecoderInheritanceTests {
        class Animal: Codable {
            let name: String

            init(name: String) {
                self.name = name
            }
        }

        final class Dog: Animal {
            let breed: String

            private enum CodingKeys: String, CodingKey {
                case breed
            }

            init(name: String, breed: String) {
                self.breed = breed
                super.init(name: name)
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                breed = try container.decode(String.self, forKey: .breed)
                try super.init(from: decoder)
            }

            override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(breed, forKey: .breed)
                try super.encode(to: encoder)
            }
        }

        @Test func decodeSubclass() throws {
            let json = #"{"name": "Rex", "breed": "German Shepherd"}"#
            let data = json.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Dog.self, from: data)
            #expect(result.name == "Rex")
            #expect(result.breed == "German Shepherd")
        }
    }

#endif  // !YYJSON_DISABLE_READER
