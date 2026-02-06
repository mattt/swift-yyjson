import Foundation
import Testing

@testable import YYJSON

// MARK: - JSONObject Reading Tests

#if !YYJSON_DISABLE_READER

    @Suite("YYJSONSerialization - Reading")
    struct SerializationReadingTests {
        @Test func readDictionary() throws {
            let json = #"{"name": "Alice", "age": 30}"#
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect(result?["name"] as? String == "Alice")
            #expect(result?["age"] as? Int == 30)
        }

        @Test func readArray() throws {
            let json = "[1, 2, 3, 4, 5]"
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(with: data) as? NSArray
            #expect(result?.count == 5)
            #expect(result?[0] as? Int == 1)
        }

        @Test func readNestedStructure() throws {
            let json = """
                {
                    "users": [
                        {"name": "Alice"},
                        {"name": "Bob"}
                    ]
                }
                """
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            let users = result?["users"] as? NSArray
            #expect(users?.count == 2)
            let alice = users?[0] as? NSDictionary
            #expect(alice?["name"] as? String == "Alice")
        }

        @Test func readWithMutableContainers() throws {
            let json = #"{"key": "value"}"#
            let data = json.data(using: .utf8)!
            let result =
                try YYJSONSerialization.jsonObject(
                    with: data,
                    options: .mutableContainers
                ) as? NSMutableDictionary
            #expect(result != nil)
            result?["newKey"] = "newValue"
            #expect(result?["newKey"] as? String == "newValue")
        }

        // Note: On Linux, swift-corelibs-foundation's NSDictionary returns values as NSString
        // even when NSMutableString was stored. The .mutableLeaves option still works correctly
        // (strings are mutable), but the type cast verification in this test fails.
        #if canImport(Darwin)
            @Test func readWithMutableLeaves() throws {
                let json = #"{"key": "value"}"#
                let data = json.data(using: .utf8)!
                let result =
                    try YYJSONSerialization.jsonObject(
                        with: data,
                        options: .mutableLeaves
                    ) as? NSDictionary
                let stringValue = result?["key"] as? NSMutableString
                #expect(stringValue != nil)
            }
        #endif

        @Test func readFragmentString() throws {
            let json = #""hello world""#
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            )
            #expect((result as? NSString) == "hello world")
        }

        @Test func readFragmentNumber() throws {
            let json = "42"
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            )
            #expect((result as? NSNumber)?.intValue == 42)
        }

        @Test func readFragmentBool() throws {
            let json = "true"
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            )
            #expect((result as? NSNumber)?.boolValue == true)
        }

        @Test func readFragmentNull() throws {
            let json = "null"
            let data = json.data(using: .utf8)!
            let result = try YYJSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            )
            #expect(result is NSNull)
        }

        @Test func readFragmentWithoutOption() throws {
            let json = #""just a string""#
            let data = json.data(using: .utf8)!
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONSerialization.jsonObject(with: data)
            }
        }

        #if !YYJSON_DISABLE_NON_STANDARD

            @Test func readWithJSON5() throws {
                let json = #"{"key": "value",}"#
                let data = json.data(using: .utf8)!
                let result =
                    try YYJSONSerialization.jsonObject(
                        with: data,
                        options: .json5Allowed
                    ) as? NSDictionary
                #expect(result?["key"] as? String == "value")
            }

        #endif  // !YYJSON_DISABLE_NON_STANDARD

        @Test func readInvalidJSON() throws {
            let json = "not valid json"
            let data = json.data(using: .utf8)!
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONSerialization.jsonObject(with: data)
            }
        }
    }

#endif  // !YYJSON_DISABLE_READER

// MARK: - JSONObject Writing Tests

#if !YYJSON_DISABLE_WRITER

    @Suite("YYJSONSerialization - Writing")
    struct SerializationWritingTests {
        @Test func writeDictionary() throws {
            let dict: NSDictionary = ["name": "Alice", "age": 30]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("name"))
            #expect(json.contains("Alice"))
            #expect(json.contains("age"))
        }

        @Test func writeArray() throws {
            let array: NSArray = [1, 2, 3, 4, 5]
            let data = try YYJSONSerialization.data(withJSONObject: array)
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "[1,2,3,4,5]")
        }

        #if !YYJSON_DISABLE_NON_STANDARD

            @Test func writeAllowsInfAndNaNLiterals() throws {
                let dict: NSDictionary = [
                    "inf": Double.infinity,
                    "nan": Double.nan,
                ]
                let data = try YYJSONSerialization.data(
                    withJSONObject: dict,
                    options: .allowInfAndNaN
                )
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("Infinity") || json.contains("inf"))
                #expect(json.contains("NaN") || json.contains("nan"))
            }

            @Test func writeInfAndNaNAsNull() throws {
                let dict: NSDictionary = [
                    "inf": Double.infinity,
                    "nan": Double.nan,
                ]
                let data = try YYJSONSerialization.data(
                    withJSONObject: dict,
                    options: .infAndNaNAsNull
                )
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("\"inf\":null"))
                #expect(json.contains("\"nan\":null"))
            }

            @Test func writeInfAndNaNAsNullOverridesAllowInfAndNaN() throws {
                let dict: NSDictionary = [
                    "inf": Double.infinity,
                    "nan": Double.nan,
                ]
                let data = try YYJSONSerialization.data(
                    withJSONObject: dict,
                    options: [.allowInfAndNaN, .infAndNaNAsNull]
                )
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("\"inf\":null"))
                #expect(json.contains("\"nan\":null"))
            }

            @Test func writeNonFiniteWithoutOptionThrows() throws {
                let dict: NSDictionary = ["value": Double.nan]
                #expect(throws: YYJSONError.self) {
                    _ = try YYJSONSerialization.data(withJSONObject: dict)
                }
            }

        #endif  // !YYJSON_DISABLE_NON_STANDARD

        #if !YYJSON_DISABLE_READER

            private static func jsonString(
                for object: Any,
                options: YYJSONSerialization.WritingOptions = []
            ) throws -> String {
                let data = try YYJSONSerialization.data(
                    withJSONObject: object,
                    options: options
                )
                return String(data: data, encoding: .utf8)!
            }

            @Test func writeYYJSONValue() throws {
                let value = try YYJSONValue(string: #"{"name":"Alice","age":30}"#)
                let data = try YYJSONSerialization.data(withJSONObject: value)
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("\"name\""))
                #expect(json.contains("\"age\""))
            }

            @Test func writeYYJSONObject() throws {
                let value = try YYJSONValue(string: #"{"name":"Alice"}"#)
                guard let object = value.object else {
                    Issue.record("Expected object")
                    return
                }
                let data = try YYJSONSerialization.data(withJSONObject: object)
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("\"name\""))
            }

            @Test func writeYYJSONArray() throws {
                let value = try YYJSONValue(string: "[1,2,3]")
                guard let array = value.array else {
                    Issue.record("Expected array")
                    return
                }
                let data = try YYJSONSerialization.data(withJSONObject: array)
                let json = String(data: data, encoding: .utf8)!
                #expect(json == "[1,2,3]")
            }

            @Test func writeYYJSONValueFragmentWithoutOption() throws {
                let value = try YYJSONValue(string: "true")
                #expect(throws: YYJSONError.self) {
                    _ = try YYJSONSerialization.data(withJSONObject: value)
                }
            }

            @Test func writeYYJSONValueFragmentWithOption() throws {
                let value = try YYJSONValue(string: "true")
                let data = try YYJSONSerialization.data(
                    withJSONObject: value,
                    options: .fragmentsAllowed
                )
                let json = String(data: data, encoding: .utf8)!
                #expect(json == "true")
            }

            @Test func writeYYJSONValueSortedKeys() throws {
                let value = try YYJSONValue(string: #"{"z":1,"a":{"b":1,"a":2}}"#)
                let data = try YYJSONSerialization.data(
                    withJSONObject: value,
                    options: .sortedKeys
                )
                let json = String(data: data, encoding: .utf8)!
                let outerA = json.range(of: "\"a\"")!.lowerBound
                let outerZ = json.range(of: "\"z\"")!.lowerBound
                #expect(outerA < outerZ)
                let innerA = json.range(of: "\"a\":2")!.lowerBound
                let innerB = json.range(of: "\"b\":1")!.lowerBound
                #expect(innerA < innerB)
            }

            @Test func writeYYJSONValuePrettyPrinted() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                let data = try YYJSONSerialization.data(
                    withJSONObject: value,
                    options: .prettyPrinted
                )
                let json = String(data: data, encoding: .utf8)!
                #expect(json.contains("\n"))
            }

            @Test func writeYYJSONValueIndentationTwoSpaces() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                let json = try Self.jsonString(
                    for: value,
                    options: [.indentationTwoSpaces]
                )
                #expect(json.contains("  \"key\""))
                #expect(!json.contains("    \"key\""))
            }

            @Test func writeYYJSONObjectIndentationTwoSpaces() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                guard let object = value.object else {
                    Issue.record("Expected object")
                    return
                }
                let json = try Self.jsonString(
                    for: object,
                    options: [.indentationTwoSpaces]
                )
                #expect(json.contains("  \"key\""))
                #expect(!json.contains("    \"key\""))
            }

            @Test func writeYYJSONArrayIndentationTwoSpaces() throws {
                let value = try YYJSONValue(string: #"[{"key":"value"}]"#)
                guard let array = value.array else {
                    Issue.record("Expected array")
                    return
                }
                let json = try Self.jsonString(
                    for: array,
                    options: [.indentationTwoSpaces]
                )
                #expect(json.contains("\n  {"))
                #expect(!json.contains("\n    {"))
            }

            @Test func writeYYJSONValueIndentationTwoSpacesOverridesPrettyPrinted() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                let json = try Self.jsonString(
                    for: value,
                    options: [.prettyPrinted, .indentationTwoSpaces]
                )
                #expect(json.contains("  \"key\""))
                #expect(!json.contains("    \"key\""))
            }

            @Test func writeYYJSONValueEscapeUnicode() throws {
                let value = try YYJSONValue(string: #"{"emoji":"🎉"}"#)
                let json = try Self.jsonString(
                    for: value,
                    options: [.escapeUnicode]
                )
                #expect(!json.contains("🎉"))
                #expect(json.contains("\\u"))
            }

            @Test func writeYYJSONObjectEscapeUnicode() throws {
                let value = try YYJSONValue(string: #"{"emoji":"🎉"}"#)
                guard let object = value.object else {
                    Issue.record("Expected object")
                    return
                }
                let json = try Self.jsonString(
                    for: object,
                    options: [.escapeUnicode]
                )
                #expect(!json.contains("🎉"))
                #expect(json.contains("\\u"))
            }

            @Test func writeYYJSONArrayEscapeUnicode() throws {
                let value = try YYJSONValue(string: #"["🎉"]"#)
                guard let array = value.array else {
                    Issue.record("Expected array")
                    return
                }
                let json = try Self.jsonString(
                    for: array,
                    options: [.escapeUnicode]
                )
                #expect(!json.contains("🎉"))
                #expect(json.contains("\\u"))
            }

            @Test func writeYYJSONValueNewlineAtEnd() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                let json = try Self.jsonString(
                    for: value,
                    options: [.newlineAtEnd]
                )
                #expect(json.hasSuffix("\n"))
            }

            @Test func writeYYJSONObjectNewlineAtEnd() throws {
                let value = try YYJSONValue(string: #"{"key":"value"}"#)
                guard let object = value.object else {
                    Issue.record("Expected object")
                    return
                }
                let json = try Self.jsonString(
                    for: object,
                    options: [.newlineAtEnd]
                )
                #expect(json.hasSuffix("\n"))
            }

            @Test func writeYYJSONArrayNewlineAtEnd() throws {
                let value = try YYJSONValue(string: #"[1,2,3]"#)
                guard let array = value.array else {
                    Issue.record("Expected array")
                    return
                }
                let json = try Self.jsonString(
                    for: array,
                    options: [.newlineAtEnd]
                )
                #expect(json.hasSuffix("\n"))
            }

            @Test func writeYYJSONValueIndentationTwoSpacesSortedKeys() throws {
                let value = try YYJSONValue(string: #"{"b":2,"a":1}"#)
                let json = try Self.jsonString(
                    for: value,
                    options: [.indentationTwoSpaces, .sortedKeys]
                )
                let aIndex = json.range(of: "\"a\"")!.lowerBound
                let bIndex = json.range(of: "\"b\"")!.lowerBound
                #expect(aIndex < bIndex)
                #expect(json.contains("  \"a\""))
            }

            @Test func writeYYJSONObjectIndentationTwoSpacesSortedKeys() throws {
                let value = try YYJSONValue(string: #"{"b":2,"a":1}"#)
                guard let object = value.object else {
                    Issue.record("Expected object")
                    return
                }
                let json = try Self.jsonString(
                    for: object,
                    options: [.indentationTwoSpaces, .sortedKeys]
                )
                let aIndex = json.range(of: "\"a\"")!.lowerBound
                let bIndex = json.range(of: "\"b\"")!.lowerBound
                #expect(aIndex < bIndex)
                #expect(json.contains("  \"a\""))
            }

            @Test func writeYYJSONArrayIndentationTwoSpacesSortedKeys() throws {
                let value = try YYJSONValue(string: #"[{"b":2,"a":1}]"#)
                guard let array = value.array else {
                    Issue.record("Expected array")
                    return
                }
                let json = try Self.jsonString(
                    for: array,
                    options: [.indentationTwoSpaces, .sortedKeys]
                )
                let aIndex = json.range(of: "\"a\"")!.lowerBound
                let bIndex = json.range(of: "\"b\"")!.lowerBound
                #expect(aIndex < bIndex)
                #expect(json.contains("\n  {"))
            }

        #endif  // !YYJSON_DISABLE_READER

        @Test func writeNestedStructure() throws {
            let dict: NSDictionary = [
                "users": [
                    ["name": "Alice"],
                    ["name": "Bob"],
                ]
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("users"))
            #expect(json.contains("Alice"))
            #expect(json.contains("Bob"))
        }

        @Test func writePrettyPrinted() throws {
            let dict: NSDictionary = ["key": "value"]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: .prettyPrinted
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("\n"))
        }

        @Test func writeSortedKeys() throws {
            let dict: NSDictionary = ["z": 1, "a": 2, "m": 3]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: .sortedKeys
            )
            let json = String(data: data, encoding: .utf8)!
            let aIndex = json.range(of: "\"a\"")!.lowerBound
            let mIndex = json.range(of: "\"m\"")!.lowerBound
            let zIndex = json.range(of: "\"z\"")!.lowerBound
            #expect(aIndex < mIndex)
            #expect(mIndex < zIndex)
        }

        @Test func writeWithoutEscapingSlashes() throws {
            let dict: NSDictionary = ["path": "/usr/bin"]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: .withoutEscapingSlashes
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("/usr/bin"))
            #expect(!json.contains("\\/"))
        }

        @Test func writeWithEscapingSlashes() throws {
            let dict: NSDictionary = ["path": "/usr/bin"]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("\\/usr\\/bin"))
        }

        @Test func writeFragmentString() throws {
            let data = try YYJSONSerialization.data(
                withJSONObject: NSString(string: "hello"),
                options: .fragmentsAllowed
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json == #""hello""#)
        }

        @Test func writeFragmentNumber() throws {
            let data = try YYJSONSerialization.data(
                withJSONObject: NSNumber(value: 42),
                options: .fragmentsAllowed
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "42")
        }

        @Test func writeFragmentBool() throws {
            let data = try YYJSONSerialization.data(
                withJSONObject: NSNumber(value: true),
                options: .fragmentsAllowed
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "true")
        }

        @Test func writeFragmentNull() throws {
            let data = try YYJSONSerialization.data(
                withJSONObject: NSNull(),
                options: .fragmentsAllowed
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "null")
        }

        @Test func writeFragmentWithoutOption() throws {
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONSerialization.data(
                    withJSONObject: NSString(string: "hello")
                )
            }
        }

        @Test func writeInvalidObject() throws {
            class CustomClass {}
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONSerialization.data(withJSONObject: CustomClass())
            }
        }

        // MARK: - indentationTwoSpaces

        @Test func writeIndentationTwoSpaces() throws {
            let dict: NSDictionary = ["key": "value"]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.indentationTwoSpaces]
            )
            let json = String(data: data, encoding: .utf8)!
            // Should use 2-space indentation (not 4-space)
            #expect(json.contains("  \"key\""))
            #expect(!json.contains("    \"key\""))
        }

        @Test func writeIndentationTwoSpacesOverridesPrettyPrinted() throws {
            let dict: NSDictionary = ["a": 1]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted, .indentationTwoSpaces]
            )
            let json = String(data: data, encoding: .utf8)!
            // 2-space should take priority
            #expect(json.contains("  \"a\""))
            #expect(!json.contains("    \"a\""))
        }

        @Test func writeIndentationTwoSpacesWithSortedKeys() throws {
            let dict: NSDictionary = ["b": 2, "a": 1]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.indentationTwoSpaces, .sortedKeys]
            )
            let json = String(data: data, encoding: .utf8)!
            // Check key order and indentation
            let aIndex = json.range(of: "\"a\"")!.lowerBound
            let bIndex = json.range(of: "\"b\"")!.lowerBound
            #expect(aIndex < bIndex)  // a before b
            #expect(json.contains("  \"a\""))  // 2-space indent
        }

        @Test func writeIndentationTwoSpacesNestedStructure() throws {
            let dict: NSDictionary = ["outer": ["inner": ["deep": 1]]]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.indentationTwoSpaces]
            )
            let json = String(data: data, encoding: .utf8)!
            // Verify 2-space indentation at each nesting level
            #expect(json.contains("  \"outer\""))  // Level 1: 2 spaces
            #expect(json.contains("    \"inner\""))  // Level 2: 4 spaces
            #expect(json.contains("      \"deep\""))  // Level 3: 6 spaces
        }

        // MARK: - escapeUnicode

        @Test func writeEscapeUnicode() throws {
            let dict: NSDictionary = ["emoji": "🎉"]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.escapeUnicode]
            )
            let json = String(data: data, encoding: .utf8)!
            // Emoji should be escaped as \uXXXX
            #expect(!json.contains("🎉"))
            #expect(json.contains("\\u"))
        }

        @Test func writeEscapeUnicodeWithChinese() throws {
            let dict: NSDictionary = ["text": "你好"]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.escapeUnicode]
            )
            let json = String(data: data, encoding: .utf8)!
            // Chinese characters should be escaped
            #expect(!json.contains("你好"))
            #expect(json.contains("\\u"))
        }

        // MARK: - newlineAtEnd

        @Test func writeNewlineAtEnd() throws {
            let dict: NSDictionary = ["a": 1]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.newlineAtEnd]
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json.hasSuffix("\n"))
        }

        @Test func writeNoNewlineAtEndByDefault() throws {
            let dict: NSDictionary = ["a": 1]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: []
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(!json.hasSuffix("\n"))
        }

        @Test func writeNewlineAtEndWithPrettyPrinted() throws {
            let dict: NSDictionary = ["a": 1]
            let data = try YYJSONSerialization.data(
                withJSONObject: dict,
                options: [.prettyPrinted, .newlineAtEnd]
            )
            let json = String(data: data, encoding: .utf8)!
            #expect(json.hasSuffix("\n"))
            #expect(json.contains("    \"a\""))  // 4-space indent
        }
    }

#endif  // !YYJSON_DISABLE_WRITER

// MARK: - isValidJSONObject Tests

@Suite("YYJSONSerialization - isValidJSONObject")
struct SerializationValidationTests {
    @Test func validDictionary() {
        let dict: NSDictionary = ["key": "value"]
        #expect(YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func validArray() {
        let array: NSArray = [1, 2, 3]
        #expect(YYJSONSerialization.isValidJSONObject(array))
    }

    @Test func validNestedStructure() {
        let dict: NSDictionary = [
            "array": [1, 2, 3],
            "nested": ["key": "value"],
        ]
        #expect(YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func invalidTopLevelString() {
        #expect(!YYJSONSerialization.isValidJSONObject(NSString(string: "hello")))
    }

    @Test func invalidTopLevelNumber() {
        #expect(!YYJSONSerialization.isValidJSONObject(NSNumber(value: 42)))
    }

    @Test func invalidTopLevelNull() {
        #expect(!YYJSONSerialization.isValidJSONObject(NSNull()))
    }

    @Test func invalidNonStringKey() {
        let dict: NSDictionary = [NSNumber(value: 1): "value"]
        #expect(!YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func invalidNaNValue() {
        let dict: NSDictionary = ["key": NSNumber(value: Double.nan)]
        #expect(!YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func invalidInfinityValue() {
        let dict: NSDictionary = ["key": NSNumber(value: Double.infinity)]
        #expect(!YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func invalidNestedNaN() {
        let dict: NSDictionary = [
            "nested": ["value": NSNumber(value: Double.nan)]
        ]
        #expect(!YYJSONSerialization.isValidJSONObject(dict))
    }

    @Test func invalidArrayWithNaN() {
        let array: NSArray = [1, 2, NSNumber(value: Double.nan)]
        #expect(!YYJSONSerialization.isValidJSONObject(array))
    }

    @Test func validMixedTypes() {
        let dict: NSDictionary = [
            "string": "hello",
            "number": 42,
            "bool": true,
            "null": NSNull(),
            "array": [1, 2, 3],
            "object": ["nested": "value"],
        ]
        #expect(YYJSONSerialization.isValidJSONObject(dict))
    }
}

// MARK: - Roundtrip Tests

#if !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER

    @Suite("YYJSONSerialization - Roundtrip")
    struct SerializationRoundtripTests {
        @Test func roundtripDictionary() throws {
            let original: NSDictionary = [
                "string": "hello",
                "number": 42,
                "bool": true,
                "null": NSNull(),
                "array": [1, 2, 3],
            ]
            let data = try YYJSONSerialization.data(withJSONObject: original)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect(decoded?["string"] as? String == "hello")
            #expect(decoded?["number"] as? Int == 42)
            #expect(decoded?["bool"] as? Bool == true)
            #expect(decoded?["null"] is NSNull)
        }

        @Test func roundtripArray() throws {
            let original: NSArray = [1, "two", true, NSNull(), ["nested": "value"]]
            let data = try YYJSONSerialization.data(withJSONObject: original)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSArray
            #expect(decoded?.count == 5)
            #expect(decoded?[0] as? Int == 1)
            #expect(decoded?[1] as? String == "two")
            #expect(decoded?[2] as? Bool == true)
            #expect(decoded?[3] is NSNull)
        }

        @Test func roundtripComplexStructure() throws {
            let original: NSDictionary = [
                "users": [
                    ["id": 1, "name": "Alice", "active": true],
                    ["id": 2, "name": "Bob", "active": false],
                ],
                "meta": [
                    "total": 2,
                    "page": 1,
                ],
            ]
            let data = try YYJSONSerialization.data(withJSONObject: original)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary

            let users = decoded?["users"] as? NSArray
            #expect(users?.count == 2)

            let alice = users?[0] as? NSDictionary
            #expect(alice?["name"] as? String == "Alice")

            let meta = decoded?["meta"] as? NSDictionary
            #expect(meta?["total"] as? Int == 2)
        }
    }

#endif  // !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER

// MARK: - Number Type Handling Tests

#if !YYJSON_DISABLE_WRITER

    @Suite("YYJSONSerialization - Number Types")
    struct SerializationNumberTests {
        @Test func writeSignedIntegers() throws {
            let dict: NSDictionary = [
                "int8": NSNumber(value: Int8(-128)),
                "int16": NSNumber(value: Int16(-32768)),
                "int32": NSNumber(value: Int32(-2147483648)),
                "int64": NSNumber(value: Int64(-9223372036854775808)),
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("-128"))
            #expect(json.contains("-32768"))
        }

        @Test func writeUnsignedIntegers() throws {
            let dict: NSDictionary = [
                "uint8": NSNumber(value: UInt8(255)),
                "uint16": NSNumber(value: UInt16(65535)),
                "uint32": NSNumber(value: UInt32(4294967295)),
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("255"))
            #expect(json.contains("65535"))
        }

        @Test func writeFloatingPoint() throws {
            #if !YYJSON_DISABLE_READER
                let dict: NSDictionary = [
                    "float": NSNumber(value: Float(3.14)),
                    "double": NSNumber(value: Double(2.71828)),
                ]
                let data = try YYJSONSerialization.data(withJSONObject: dict)
                let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
                let floatValue = (decoded?["float"] as? NSNumber)?.doubleValue ?? 0
                #expect(abs(floatValue - 3.14) < 0.01)
            #endif
        }

        @Test func writeBooleans() throws {
            let dict: NSDictionary = [
                "true": NSNumber(value: true),
                "false": NSNumber(value: false),
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json.contains("true"))
            #expect(json.contains("false"))
        }
    }

#endif  // !YYJSON_DISABLE_WRITER

// MARK: - Edge Cases Tests

#if !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER

    @Suite("YYJSONSerialization - Edge Cases")
    struct SerializationEdgeCasesTests {
        @Test func emptyDictionary() throws {
            let dict: NSDictionary = [:]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "{}")
        }

        @Test func emptyArray() throws {
            let array: NSArray = []
            let data = try YYJSONSerialization.data(withJSONObject: array)
            let json = String(data: data, encoding: .utf8)!
            #expect(json == "[]")
        }

        @Test func unicodeStrings() throws {
            let dict: NSDictionary = [
                "emoji": "🎉🎊🎁",
                "chinese": "你好世界",
                "japanese": "こんにちは",
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect(decoded?["emoji"] as? String == "🎉🎊🎁")
            #expect(decoded?["chinese"] as? String == "你好世界")
            #expect(decoded?["japanese"] as? String == "こんにちは")
        }

        @Test func specialCharactersInStrings() throws {
            let dict: NSDictionary = [
                "newline": "line1\nline2",
                "tab": "col1\tcol2",
                "quote": "say \"hello\"",
                "backslash": "path\\to\\file",
            ]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect(decoded?["newline"] as? String == "line1\nline2")
            #expect(decoded?["tab"] as? String == "col1\tcol2")
            #expect(decoded?["quote"] as? String == "say \"hello\"")
            #expect(decoded?["backslash"] as? String == "path\\to\\file")
        }

        @Test func veryLongString() throws {
            let longString = String(repeating: "a", count: 100_000)
            let dict: NSDictionary = ["long": longString]
            let data = try YYJSONSerialization.data(withJSONObject: dict)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect((decoded?["long"] as? String)?.count == 100_000)
        }

        @Test func deeplyNestedStructure() throws {
            var current: NSDictionary = ["value": "deep"]
            for i in 0 ..< 50 {
                current = ["level\(i)": current]
            }
            let data = try YYJSONSerialization.data(withJSONObject: current)
            let decoded = try YYJSONSerialization.jsonObject(with: data) as? NSDictionary
            #expect(decoded != nil)
        }
    }

#endif  // !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER
