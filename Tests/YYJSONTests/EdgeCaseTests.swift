import Foundation
import Testing

@testable import YYJSON

// MARK: - Large Number Tests

@Suite("Edge Cases - Large Numbers")
struct LargeNumberTests {
    @Test func decodeLargeInt64() throws {
        let json = "9223372036854775807"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Int64.self, from: data)
        #expect(result == Int64.max)
    }

    @Test func decodeSmallInt64() throws {
        let json = "-9223372036854775808"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Int64.self, from: data)
        #expect(result == Int64.min)
    }

    @Test func decodeLargeUInt64() throws {
        let json = "18446744073709551615"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(UInt64.self, from: data)
        #expect(result == UInt64.max)
    }

    @Test func encodeLargeInt64() throws {
        let encoder = YYJSONEncoder()
        let data = try encoder.encode(Int64.max)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "9223372036854775807")
    }

    @Test func encodeLargeUInt64() throws {
        let encoder = YYJSONEncoder()
        let data = try encoder.encode(UInt64.max)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "18446744073709551615")
    }

    @Test func verySmallDouble() throws {
        let json = "1e-308"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Double.self, from: data)
        #expect(result > 0)
        #expect(result < 1e-307)
    }

    @Test func veryLargeDouble() throws {
        let json = "1e308"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Double.self, from: data)
        #expect(result > 1e307)
    }
}

// MARK: - Unicode Tests

@Suite("Edge Cases - Unicode")
struct UnicodeEdgeCaseTests {
    @Test func allEmojiCategories() throws {
        let emojis = "😀🎉🚀🌍💡🔥❤️✨🎵🎨"
        let json = "\"\(emojis)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == emojis)
    }

    @Test func complexEmoji() throws {
        let emoji = "👨‍👩‍👧‍👦"
        let json = "\"\(emoji)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == emoji)
    }

    @Test func flagEmoji() throws {
        let flags = "🇺🇸🇬🇧🇯🇵🇫🇷"
        let json = "\"\(flags)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == flags)
    }

    @Test func chineseJapaneseKorean() throws {
        let text = "中文日本語한국어"
        let json = "\"\(text)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == text)
    }

    @Test func arabicHebrewText() throws {
        let text = "العربية עברית"
        let json = "\"\(text)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == text)
    }

    @Test func unicodeEscapeSequence() throws {
        let json = #""\u0048\u0065\u006C\u006C\u006F""#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == "Hello")
    }

    @Test func mixedUnicodeAndEscapes() throws {
        let json = #""Hello \u4E16\u754C""#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result == "Hello 世界")
    }
}

// MARK: - String Edge Cases

@Suite("Edge Cases - Strings")
struct StringEdgeCaseTests {
    @Test func allEscapeSequences() throws {
        let json = #""quote: \" backslash: \\ slash: \/ newline: \n tab: \t carriage: \r backspace: \b formfeed: \f""#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result.contains("\""))
        #expect(result.contains("\\"))
        #expect(result.contains("/"))
        #expect(result.contains("\n"))
        #expect(result.contains("\t"))
        #expect(result.contains("\r"))
    }

    @Test func veryLongString() throws {
        let longString = String(repeating: "x", count: 1_000_000)
        let json = "\"\(longString)\""
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result.count == 1_000_000)
    }

    @Test func stringWithNullCharacter() throws {
        let json = #""before\u0000after""#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result.contains("before"))
        #expect(result.contains("after") || result.count > 0)
    }

    @Test func stringWithOnlyWhitespace() throws {
        let json = #""   \n\t\r   ""#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(String.self, from: data)
        #expect(result.contains(" "))
        #expect(result.contains("\n"))
    }
}

// MARK: - Array Edge Cases

@Suite("Edge Cases - Arrays")
struct ArrayEdgeCaseTests {
    @Test func largeArray() throws {
        var elements: [String] = []
        for i in 0 ..< 10000 {
            elements.append(String(i))
        }
        let json = "[\(elements.joined(separator: ","))]"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode([Int].self, from: data)
        #expect(result.count == 10000)
        #expect(result.first == 0)
        #expect(result.last == 9999)
    }

    @Test func deeplyNestedArrays() throws {
        var json = "1"
        for _ in 0 ..< 100 {
            json = "[\(json)]"
        }
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value.array != nil)
    }

    @Test func arrayWithAllTypes() throws {
        let json = #"[null, true, false, 42, 3.14, "string", [], {}]"#
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        guard let arr = value.array else {
            Issue.record("Expected array")
            return
        }
        #expect(arr.count == 8)
        #expect(arr[0]?.isNull == true)
        #expect(arr[1]?.bool == true)
        #expect(arr[2]?.bool == false)
        #expect(arr[3]?.number == 42.0)
        #expect(arr[5]?.string == "string")
        #expect(arr[6]?.array != nil)
        #expect(arr[7]?.object != nil)
    }
}

// MARK: - Object Edge Cases

@Suite("Edge Cases - Objects")
struct ObjectEdgeCaseTests {
    @Test func objectWithManyKeys() throws {
        var pairs: [String] = []
        for i in 0 ..< 1000 {
            pairs.append("\"\(i)\": \(i)")
        }
        let json = "{\(pairs.joined(separator: ","))}"
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value.object?.keys.count == 1000)
        #expect(value["0"]?.number == 0.0)
        #expect(value["999"]?.number == 999.0)
    }

    @Test func objectWithSpecialKeyNames() throws {
        let json = #"{"": "empty", " ": "space", "\n": "newline", "key with spaces": "value"}"#
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value[""]?.string == "empty")
        #expect(value[" "]?.string == "space")
        #expect(value["key with spaces"]?.string == "value")
    }

    @Test func objectWithDuplicateKeys() throws {
        let json = #"{"key": "first", "key": "second"}"#
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value["key"]?.string != nil)
    }

    @Test func deeplyNestedObjects() throws {
        var json = #"{"value": 42}"#
        for i in 0 ..< 100 {
            json = #"{"level\#(i)": \#(json)}"#
        }
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value.object != nil)
    }
}

// MARK: - Whitespace Tests

@Suite("Edge Cases - Whitespace")
struct WhitespaceEdgeCaseTests {
    @Test func jsonWithExcessWhitespace() throws {
        let json = """

            {

                "key"   :   "value"   ,

                "array" :   [   1   ,   2   ,   3   ]

            }

            """
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value["key"]?.string == "value")
        #expect(value["array"]?.array?.count == 3)
    }

    @Test func jsonWithNoWhitespace() throws {
        let json = #"{"a":1,"b":[2,3],"c":{"d":4}}"#
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value["a"]?.number == 1.0)
        #expect(value["b"]?.array?.count == 2)
        #expect(value["c"]?["d"]?.number == 4.0)
    }

    @Test func jsonWithTabsAndNewlines() throws {
        let json = "{\n\t\"key\":\t\"value\"\n}"
        let data = json.data(using: .utf8)!
        let value = try YYJSONValue(data: data)
        #expect(value["key"]?.string == "value")
    }
}

// MARK: - Number Edge Cases

@Suite("Edge Cases - Numbers")
struct NumberEdgeCaseTests {
    @Test func negativeZero() throws {
        let json = "-0"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Double.self, from: data)
        #expect(result == 0.0)
    }

    @Test func numberWithLeadingZero() throws {
        let json = "0.123"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Double.self, from: data)
        #expect(abs(result - 0.123) < 0.001)
    }

    @Test func scientificNotationVariants() throws {
        let variants = ["1e10", "1E10", "1e+10", "1E+10", "1e-10", "1E-10"]
        for variant in variants {
            let data = variant.data(using: .utf8)!
            let decoder = YYJSONDecoder()
            let result = try decoder.decode(Double.self, from: data)
            #expect(result != 0)
        }
    }

    @Test func precisionTest() throws {
        let json = "0.12345678901234567890"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Double.self, from: data)
        #expect(abs(result - 0.123456789012345) < 1e-14)
    }

    @Test func integerAsDouble() throws {
        let json = #"{"value": 42.0}"#
        let data = json.data(using: .utf8)!

        struct Container: Codable {
            let value: Double
        }

        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Container.self, from: data)
        #expect(result.value == 42.0)
    }
}

// MARK: - Codable Edge Cases

@Suite("Edge Cases - Codable")
struct CodableEdgeCaseTests {
    @Test func emptyStruct() throws {
        struct Empty: Codable, Equatable {}
        let json = "{}"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(Empty.self, from: data)
        #expect(result == Empty())

        let encoder = YYJSONEncoder()
        let encoded = try encoder.encode(result)
        let encodedJson = String(data: encoded, encoding: .utf8)!
        #expect(encodedJson == "{}")
    }

    @Test func structWithAllOptionalNil() throws {
        struct AllOptional: Codable {
            let a: String?
            let b: Int?
            let c: Bool?
        }
        let json = "{}"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode(AllOptional.self, from: data)
        #expect(result.a == nil)
        #expect(result.b == nil)
        #expect(result.c == nil)
    }

    @Test func arrayOfDifferentLengths() throws {
        let json = "[[], [1], [1, 2], [1, 2, 3]]"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode([[Int]].self, from: data)
        #expect(result.count == 4)
        #expect(result[0].count == 0)
        #expect(result[1].count == 1)
        #expect(result[2].count == 2)
        #expect(result[3].count == 3)
    }

    @Test func dictionaryWithIntKeys() throws {
        let json = #"{"1": "one", "2": "two", "3": "three"}"#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode([Int: String].self, from: data)
        #expect(result[1] == "one")
        #expect(result[2] == "two")
        #expect(result[3] == "three")
    }

    enum CaseIterableEnum: String, Codable, CaseIterable {
        case a, b, c, d, e
    }

    @Test func arrayOfEnums() throws {
        let json = #"["a", "b", "c", "d", "e"]"#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        let result = try decoder.decode([CaseIterableEnum].self, from: data)
        #expect(result == CaseIterableEnum.allCases)
    }
}

// MARK: - Memory and Performance Edge Cases

@Suite("Edge Cases - Memory")
struct MemoryEdgeCaseTests {
    @Test func parseAndDiscardMultipleTimes() throws {
        let json = #"{"key": "value"}"#
        let data = json.data(using: .utf8)!

        for _ in 0 ..< 1000 {
            let value = try YYJSONValue(data: data)
            #expect(value["key"]?.string == "value")
        }
    }

    @Test func encodeDecodeMultipleTimes() throws {
        struct Simple: Codable, Equatable {
            let value: Int
        }

        let original = Simple(value: 42)
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        for _ in 0 ..< 1000 {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(Simple.self, from: data)
            #expect(decoded == original)
        }
    }
}

// MARK: - Thread Safety Tests

@Suite("Edge Cases - Concurrency")
struct ConcurrencyEdgeCaseTests {
    @Test func concurrentDecoding() async throws {
        let json = #"{"value": 42}"#
        let data = json.data(using: .utf8)!

        struct Simple: Codable, Sendable {
            let value: Int
        }

        await withTaskGroup(of: Int.self) { group in
            for _ in 0 ..< 100 {
                group.addTask {
                    do {
                        let decoder = YYJSONDecoder()
                        let result = try decoder.decode(Simple.self, from: data)
                        return result.value
                    } catch {
                        return -1
                    }
                }
            }

            for await value in group {
                #expect(value == 42)
            }
        }
    }

    @Test func concurrentValueAccess() async throws {
        let json = #"{"a": 1, "b": 2, "c": 3}"#
        let value = try YYJSONValue(string: json)

        await withTaskGroup(of: Double?.self) { group in
            for key in ["a", "b", "c"] {
                group.addTask {
                    return value[key]?.number
                }
            }

            var results: [Double] = []
            for await number in group {
                if let n = number {
                    results.append(n)
                }
            }
            #expect(results.sorted() == [1.0, 2.0, 3.0])
        }
    }
}

// MARK: - Boundary Value Tests

@Suite("Edge Cases - Boundary Values")
struct BoundaryValueTests {
    @Test func int8Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(Int8.min)
        let maxData = try encoder.encode(Int8.max)

        let minResult = try decoder.decode(Int8.self, from: minData)
        let maxResult = try decoder.decode(Int8.self, from: maxData)

        #expect(minResult == Int8.min)
        #expect(maxResult == Int8.max)
    }

    @Test func int16Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(Int16.min)
        let maxData = try encoder.encode(Int16.max)

        let minResult = try decoder.decode(Int16.self, from: minData)
        let maxResult = try decoder.decode(Int16.self, from: maxData)

        #expect(minResult == Int16.min)
        #expect(maxResult == Int16.max)
    }

    @Test func int32Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(Int32.min)
        let maxData = try encoder.encode(Int32.max)

        let minResult = try decoder.decode(Int32.self, from: minData)
        let maxResult = try decoder.decode(Int32.self, from: maxData)

        #expect(minResult == Int32.min)
        #expect(maxResult == Int32.max)
    }

    @Test func uint8Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(UInt8.min)
        let maxData = try encoder.encode(UInt8.max)

        let minResult = try decoder.decode(UInt8.self, from: minData)
        let maxResult = try decoder.decode(UInt8.self, from: maxData)

        #expect(minResult == UInt8.min)
        #expect(maxResult == UInt8.max)
    }

    @Test func uint16Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(UInt16.min)
        let maxData = try encoder.encode(UInt16.max)

        let minResult = try decoder.decode(UInt16.self, from: minData)
        let maxResult = try decoder.decode(UInt16.self, from: maxData)

        #expect(minResult == UInt16.min)
        #expect(maxResult == UInt16.max)
    }

    @Test func uint32Boundaries() throws {
        let encoder = YYJSONEncoder()
        let decoder = YYJSONDecoder()

        let minData = try encoder.encode(UInt32.min)
        let maxData = try encoder.encode(UInt32.max)

        let minResult = try decoder.decode(UInt32.self, from: minData)
        let maxResult = try decoder.decode(UInt32.self, from: maxData)

        #expect(minResult == UInt32.min)
        #expect(maxResult == UInt32.max)
    }
}
