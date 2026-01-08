import Foundation
import Testing

@testable import YYJSON

#if !YYJSON_DISABLE_WRITER && !YYJSON_DISABLE_READER

    // MARK: - Basic Type Encoding Tests

    @Suite("YYJSONEncoder - Basic Types")
    struct EncoderBasicTypesTests {
        @Test func encodeString() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode("hello world")
            let result = String(data: data, encoding: .utf8)
            #expect(result == #""hello world""#)
        }

        @Test func encodeEmptyString() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode("")
            let result = String(data: data, encoding: .utf8)
            #expect(result == #""""#)
        }

        @Test func encodeStringWithUnicode() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode("Hello 你好 🌍")
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("Hello"))
            #expect(result.contains("你好"))
        }

        @Test func encodeStringWithEscapes() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode("line1\nline2\ttab")
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("\\n"))
            #expect(result.contains("\\t"))
        }

        @Test func encodeInt() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(42)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "42")
        }

        @Test func encodeNegativeInt() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(-123)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "-123")
        }

        @Test func encodeZero() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(0)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "0")
        }

        @Test func encodeInt8() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(Int8(127))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "127")
        }

        @Test func encodeInt16() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(Int16(32767))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "32767")
        }

        @Test func encodeInt32() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(Int32(2147483647))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "2147483647")
        }

        @Test func encodeInt64() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(Int64(9223372036854775807))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "9223372036854775807")
        }

        @Test func encodeUInt() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(UInt(42))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "42")
        }

        @Test func encodeUInt8() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(UInt8(255))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "255")
        }

        @Test func encodeUInt16() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(UInt16(65535))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "65535")
        }

        @Test func encodeUInt32() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(UInt32(4294967295))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "4294967295")
        }

        @Test func encodeUInt64() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(UInt64(18446744073709551615))
            let result = String(data: data, encoding: .utf8)
            #expect(result == "18446744073709551615")
        }

        @Test func encodeDouble() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(3.14159)
            let result = String(data: data, encoding: .utf8)!
            let decoded = Double(result)!
            #expect(abs(decoded - 3.14159) < 0.00001)
        }

        @Test func encodeFloat() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(Float(3.14))
            let result = String(data: data, encoding: .utf8)!
            let decoded = Double(result)!
            #expect(abs(decoded - 3.14) < 0.01)
        }

        @Test func encodeBoolTrue() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(true)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "true")
        }

        @Test func encodeBoolFalse() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(false)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "false")
        }

        @Test func encodeNil() throws {
            let encoder = YYJSONEncoder()
            let value: String? = nil
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "null")
        }
    }

    // MARK: - Collection Encoding Tests

    @Suite("YYJSONEncoder - Collections")
    struct EncoderCollectionTests {
        @Test func encodeEmptyArray() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode([Int]())
            let result = String(data: data, encoding: .utf8)
            #expect(result == "[]")
        }

        @Test func encodeIntArray() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode([1, 2, 3, 4, 5])
            let result = String(data: data, encoding: .utf8)
            #expect(result == "[1,2,3,4,5]")
        }

        @Test func encodeStringArray() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(["a", "b", "c"])
            let result = String(data: data, encoding: .utf8)
            #expect(result == #"["a","b","c"]"#)
        }

        @Test func encodeNestedArray() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode([[1, 2], [3, 4], [5, 6]])
            let result = String(data: data, encoding: .utf8)
            #expect(result == "[[1,2],[3,4],[5,6]]")
        }

        @Test func encodeEmptyDictionary() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode([String: Int]())
            let result = String(data: data, encoding: .utf8)
            #expect(result == "{}")
        }

        @Test func encodeDictionary() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(["a": 1])
            let result = String(data: data, encoding: .utf8)
            #expect(result == #"{"a":1}"#)
        }

        @Test func encodeArrayOfOptionals() throws {
            let encoder = YYJSONEncoder()
            let values: [Int?] = [1, nil, 3, nil, 5]
            let data = try encoder.encode(values)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "[1,null,3,null,5]")
        }
    }

    // MARK: - Struct Encoding Tests

    @Suite("YYJSONEncoder - Structs")
    struct EncoderStructTests {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let age: Int
            let active: Bool
        }

        @Test func encodeSimpleStruct() throws {
            let value = SimpleStruct(name: "Alice", age: 30, active: true)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(SimpleStruct.self, from: data)
            #expect(decoded == value)
        }

        struct NestedStruct: Codable, Equatable {
            struct Inner: Codable, Equatable {
                let value: String
            }
            let inner: Inner
        }

        @Test func encodeNestedStruct() throws {
            let value = NestedStruct(inner: .init(value: "nested"))
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(NestedStruct.self, from: data)
            #expect(decoded == value)
        }

        struct StructWithOptionals: Codable {
            let required: String
            let optional: String?
        }

        @Test func encodeStructWithPresentOptional() throws {
            let value = StructWithOptionals(required: "yes", optional: "present")
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("required"))
            #expect(json.contains("optional"))
            #expect(json.contains("present"))
        }

        @Test func encodeStructWithNilOptional() throws {
            let value = StructWithOptionals(required: "yes", optional: nil)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("required"))
        }

        struct StructWithArray: Codable, Equatable {
            let items: [String]
        }

        @Test func encodeStructWithArray() throws {
            let value = StructWithArray(items: ["a", "b", "c"])
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(StructWithArray.self, from: data)
            #expect(decoded == value)
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

        @Test func encodeAllNumericTypes() throws {
            let value = AllNumericTypes(
                int: 1,
                int8: 2,
                int16: 3,
                int32: 4,
                int64: 5,
                uint: 6,
                uint8: 7,
                uint16: 8,
                uint32: 9,
                uint64: 10,
                float: 1.5,
                double: 2.5
            )
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(AllNumericTypes.self, from: data)
            #expect(decoded.int == value.int)
            #expect(decoded.int8 == value.int8)
            #expect(decoded.int16 == value.int16)
            #expect(decoded.int32 == value.int32)
            #expect(decoded.int64 == value.int64)
            #expect(decoded.uint == value.uint)
            #expect(decoded.uint8 == value.uint8)
            #expect(decoded.uint16 == value.uint16)
            #expect(decoded.uint32 == value.uint32)
            #expect(decoded.uint64 == value.uint64)
        }
    }

    // MARK: - Enum Encoding Tests

    @Suite("YYJSONEncoder - Enums")
    struct EncoderEnumTests {
        enum StringEnum: String, Codable {
            case first
            case second
            case third
        }

        @Test func encodeStringEnum() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(StringEnum.second)
            let result = String(data: data, encoding: .utf8)
            #expect(result == #""second""#)
        }

        enum IntEnum: Int, Codable {
            case zero = 0
            case one = 1
            case two = 2
        }

        @Test func encodeIntEnum() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(IntEnum.one)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "1")
        }

        @Test func encodeArrayOfEnums() throws {
            let encoder = YYJSONEncoder()
            let data = try encoder.encode([StringEnum.first, .second, .third])
            let result = String(data: data, encoding: .utf8)
            #expect(result == #"["first","second","third"]"#)
        }
    }

    // MARK: - Write Options Tests

    @Suite("YYJSONEncoder - Write Options")
    struct EncoderWriteOptionsTests {
        struct SimpleStruct: Codable {
            let name: String
            let value: Int
        }

        @Test func encodePrettyPrinted() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .prettyPrinted
            let value = SimpleStruct(name: "test", value: 42)
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("\n"))
            #expect(result.contains("    "))
        }

        @Test func encodePrettyPrintedTwoSpaces() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .prettyPrintedTwoSpaces
            let value = SimpleStruct(name: "test", value: 42)
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("\n"))
            #expect(result.contains("  "))
        }

        @Test func encodeMinified() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .default
            let value = SimpleStruct(name: "test", value: 42)
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)!
            #expect(!result.contains("\n"))
            #expect(!result.contains(" "))
        }

        @Test func encodeWithEscapedSlashes() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .escapeSlashes
            let data = try encoder.encode("path/to/file")
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("\\/"))
        }

        @Test func encodeWithNewlineAtEnd() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .newlineAtEnd
            let data = try encoder.encode("test")
            let result = String(data: data, encoding: .utf8)!
            #expect(result.hasSuffix("\n"))
        }

        @Test func encodeWithEscapedUnicode() throws {
            var encoder = YYJSONEncoder()
            encoder.writeOptions = .escapeUnicode
            let data = try encoder.encode("你好")
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("\\u"))
        }
    }

    // MARK: - UserInfo Tests

    @Suite("YYJSONEncoder - UserInfo")
    struct EncoderUserInfoTests {
        struct UserInfoAwareStruct: Codable {
            let value: String

            private enum CodingKeys: String, CodingKey {
                case value
            }

            init(value: String) {
                self.value = value
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if let prefix = encoder.userInfo[CodingUserInfoKey(rawValue: "prefix")!] as? String {
                    try container.encode(prefix + value, forKey: .value)
                } else {
                    try container.encode(value, forKey: .value)
                }
            }
        }

        @Test func encodeWithUserInfo() throws {
            var encoder = YYJSONEncoder()
            encoder.userInfo[CodingUserInfoKey(rawValue: "prefix")!] = "hello_"
            let value = UserInfoAwareStruct(value: "world")
            let data = try encoder.encode(value)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("hello_world"))
        }
    }

    // MARK: - Roundtrip Tests

    @Suite("YYJSONEncoder - Roundtrip")
    struct EncoderRoundtripTests {
        struct ComplexStruct: Codable, Equatable {
            let string: String
            let int: Int
            let double: Double
            let bool: Bool
            let array: [Int]
            let nested: NestedStruct

            struct NestedStruct: Codable, Equatable {
                let value: String
            }
        }

        @Test func roundtripComplexStruct() throws {
            let original = ComplexStruct(
                string: "test",
                int: 42,
                double: 3.14,
                bool: true,
                array: [1, 2, 3],
                nested: .init(value: "nested")
            )

            let encoder = YYJSONEncoder()
            let data = try encoder.encode(original)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(ComplexStruct.self, from: data)

            #expect(decoded == original)
        }

        @Test func roundtripDeeplyNestedStructure() throws {
            struct Level3: Codable, Equatable {
                let value: String
            }
            struct Level2: Codable, Equatable {
                let level3: Level3
            }
            struct Level1: Codable, Equatable {
                let level2: Level2
            }
            struct Root: Codable, Equatable {
                let level1: Level1
            }

            let original = Root(
                level1: Level1(
                    level2: Level2(
                        level3: Level3(value: "deep")
                    )
                )
            )

            let encoder = YYJSONEncoder()
            let data = try encoder.encode(original)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(Root.self, from: data)

            #expect(decoded == original)
        }

        @Test func roundtripLargeArray() throws {
            let original = Array(1 ... 1000)

            let encoder = YYJSONEncoder()
            let data = try encoder.encode(original)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode([Int].self, from: data)

            #expect(decoded == original)
        }
    }

    // MARK: - Nested Container Tests

    @Suite("YYJSONEncoder - Nested Containers")
    struct EncoderNestedContainerTests {
        struct ManuallyEncoded: Codable, Equatable {
            let outer: String
            let inner: Inner

            struct Inner: Codable, Equatable {
                let value: Int
            }

            private enum CodingKeys: String, CodingKey {
                case outer
                case nested
            }

            private enum NestedKeys: String, CodingKey {
                case value
            }

            init(outer: String, inner: Inner) {
                self.outer = outer
                self.inner = inner
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                outer = try container.decode(String.self, forKey: .outer)
                let nestedContainer = try container.nestedContainer(keyedBy: NestedKeys.self, forKey: .nested)
                let value = try nestedContainer.decode(Int.self, forKey: .value)
                inner = Inner(value: value)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(outer, forKey: .outer)
                var nestedContainer = container.nestedContainer(keyedBy: NestedKeys.self, forKey: .nested)
                try nestedContainer.encode(inner.value, forKey: .value)
            }
        }

        @Test func encodeWithNestedKeyedContainer() throws {
            let value = ManuallyEncoded(outer: "test", inner: .init(value: 42))
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(ManuallyEncoded.self, from: data)
            #expect(decoded == value)
        }

        struct ArrayContainer: Codable, Equatable {
            let items: [String]

            private enum CodingKeys: String, CodingKey {
                case items
            }

            init(items: [String]) {
                self.items = items
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                var nestedArray = try container.nestedUnkeyedContainer(forKey: .items)
                var items: [String] = []
                while !nestedArray.isAtEnd {
                    items.append(try nestedArray.decode(String.self))
                }
                self.items = items
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var nestedArray = container.nestedUnkeyedContainer(forKey: .items)
                for item in items {
                    try nestedArray.encode(item)
                }
            }
        }

        @Test func encodeWithNestedUnkeyedContainer() throws {
            let value = ArrayContainer(items: ["a", "b", "c"])
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(ArrayContainer.self, from: data)
            #expect(decoded == value)
        }
    }

    // MARK: - Super Encoder Tests

    @Suite("YYJSONEncoder - Super Encoder")
    struct EncoderSuperEncoderTests {
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

        @Test func encodeSubclass() throws {
            let dog = Dog(name: "Rex", breed: "German Shepherd")
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(dog)

            let decoder = YYJSONDecoder()
            let decoded = try decoder.decode(Dog.self, from: data)
            #expect(decoded.name == "Rex")
            #expect(decoded.breed == "German Shepherd")
        }
    }

    // MARK: - Single Value Container Tests

    @Suite("YYJSONEncoder - Single Value Container")
    struct EncoderSingleValueContainerTests {
        struct Wrapper<T: Codable>: Codable {
            let value: T

            init(_ value: T) {
                self.value = value
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                value = try container.decode(T.self)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(value)
            }
        }

        @Test func encodeSingleValueString() throws {
            let value = Wrapper("hello")
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)
            #expect(result == #""hello""#)
        }

        @Test func encodeSingleValueInt() throws {
            let value = Wrapper(42)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "42")
        }

        @Test func encodeSingleValueBool() throws {
            let value = Wrapper(true)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "true")
        }

        @Test func encodeSingleValueNil() throws {
            let value = Wrapper<String?>(nil)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(value)
            let result = String(data: data, encoding: .utf8)
            #expect(result == "null")
        }
    }

    // MARK: - Date Encoding Strategy Tests

    @Suite("YYJSONEncoder - Date Encoding Strategies")
    struct EncoderDateEncodingStrategyTests {
        struct DateContainer: Codable {
            let date: Date
        }

        @Test func encodeDateAsSecondsSince1970() throws {
            let date = Date(timeIntervalSince1970: 1000000)
            let container = DateContainer(date: date)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("1000000"))
        }

        @Test func encodeDateAsMillisecondsSince1970() throws {
            let date = Date(timeIntervalSince1970: 1000)
            let container = DateContainer(date: date)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("1000000"))
        }

        @Test func encodeDateAsISO8601() throws {
            let date = Date(timeIntervalSince1970: 0)
            let container = DateContainer(date: date)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("1970-01-01"))
            #expect(result.contains("T00:00:00"))
        }

        @Test func encodeDateWithFormatter() throws {
            let date = Date(timeIntervalSince1970: 0)
            let container = DateContainer(date: date)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .formatted(formatter)
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("1970/01/01"))
        }

        @Test func encodeDateWithCustomStrategy() throws {
            let date = Date(timeIntervalSince1970: 12345)
            let container = DateContainer(date: date)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                try container.encode("custom:\(Int(date.timeIntervalSince1970))")
            }
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("custom:12345"))
        }

        @Test func encodeDateArrayAsSecondsSince1970() throws {
            struct DatesContainer: Codable {
                let dates: [Date]
            }
            let dates = [
                Date(timeIntervalSince1970: 1000),
                Date(timeIntervalSince1970: 2000),
                Date(timeIntervalSince1970: 3000),
            ]
            let container = DatesContainer(dates: dates)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("1000"))
            #expect(result.contains("2000"))
            #expect(result.contains("3000"))
        }

        @Test func encodeDateDeferredToDate() throws {
            let date = Date(timeIntervalSince1970: 1000000)
            let container = DateContainer(date: date)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .deferredToDate
            let data = try encoder.encode(container)

            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .deferredToDate
            let decoded = try decoder.decode(DateContainer.self, from: data)
            #expect(abs(decoded.date.timeIntervalSince1970 - date.timeIntervalSince1970) < 0.001)
        }
    }

    // MARK: - Data Encoding Strategy Tests

    @Suite("YYJSONEncoder - Data Encoding Strategies")
    struct EncoderDataEncodingStrategyTests {
        struct DataContainer: Codable {
            let data: Data
        }

        @Test func encodeDataAsBase64() throws {
            let bytes = "Hello World".data(using: .utf8)!
            let container = DataContainer(data: bytes)
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .base64
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("SGVsbG8gV29ybGQ="))
        }

        @Test func encodeDataAsBase64IsDefault() throws {
            let bytes = "Hello World".data(using: .utf8)!
            let container = DataContainer(data: bytes)
            let encoder = YYJSONEncoder()
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("SGVsbG8gV29ybGQ="))
        }

        @Test func encodeDataWithCustomStrategy() throws {
            let bytes = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f])
            let container = DataContainer(data: bytes)
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .custom { data, encoder in
                var container = encoder.singleValueContainer()
                let hexString = data.map { String(format: "%02x", $0) }.joined()
                try container.encode(hexString)
            }
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("48656c6c6f"))
        }

        @Test func encodeDataDeferredToData() throws {
            let bytes = Data([1, 2, 3, 4, 5])
            let container = DataContainer(data: bytes)
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .deferredToData
            let data = try encoder.encode(container)

            var decoder = YYJSONDecoder()
            decoder.dataDecodingStrategy = .deferredToData
            let decoded = try decoder.decode(DataContainer.self, from: data)
            #expect(decoded.data == bytes)
        }

        @Test func encodeDataArrayAsBase64() throws {
            struct DataArrayContainer: Codable {
                let items: [Data]
            }
            let items = [
                "First".data(using: .utf8)!,
                "Second".data(using: .utf8)!,
                "Third".data(using: .utf8)!,
            ]
            let container = DataArrayContainer(items: items)
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .base64
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("Rmlyc3Q="))
            #expect(result.contains("U2Vjb25k"))
            #expect(result.contains("VGhpcmQ="))
        }

        @Test func encodeEmptyData() throws {
            let container = DataContainer(data: Data())
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .base64
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains(#""data":"""#))
        }

        @Test func roundtripDataWithBase64() throws {
            let originalBytes = "Hello, World! 🌍".data(using: .utf8)!
            let container = DataContainer(data: originalBytes)

            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .base64
            let encoded = try encoder.encode(container)

            var decoder = YYJSONDecoder()
            decoder.dataDecodingStrategy = .base64
            let decoded = try decoder.decode(DataContainer.self, from: encoded)
            #expect(decoded.data == originalBytes)
        }

        @Test func encodeNestedDataAsBase64() throws {
            struct NestedContainer: Codable {
                struct Inner: Codable {
                    let payload: Data
                }
                let inner: Inner
            }
            let bytes = "Nested payload".data(using: .utf8)!
            let container = NestedContainer(inner: .init(payload: bytes))
            var encoder = YYJSONEncoder()
            encoder.dataEncodingStrategy = .base64
            let data = try encoder.encode(container)
            let result = String(data: data, encoding: .utf8)!
            #expect(result.contains("TmVzdGVkIHBheWxvYWQ="))
        }
    }

#endif  // !YYJSON_DISABLE_WRITER && !YYJSON_DISABLE_READER
