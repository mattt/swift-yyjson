import Foundation
import Testing

@testable import YYJSON

#if !YYJSON_DISABLE_READER

    // MARK: - YYJSONValue Basic Tests

    @Suite("YYJSONValue - Basic Types")
    struct ValueBasicTypesTests {
        @Test func parseNull() throws {
            let value = try YYJSONValue(string: "null")
            #expect(value.isNull)
            #expect(value.string == nil)
            #expect(value.number == nil)
            #expect(value.bool == nil)
            #expect(value.array == nil)
            #expect(value.object == nil)
        }

        @Test func parseBoolTrue() throws {
            let value = try YYJSONValue(string: "true")
            #expect(value.bool == true)
            #expect(!value.isNull)
        }

        @Test func parseBoolFalse() throws {
            let value = try YYJSONValue(string: "false")
            #expect(value.bool == false)
            #expect(!value.isNull)
        }

        @Test func parseInteger() throws {
            let value = try YYJSONValue(string: "42")
            #expect(value.number == 42.0)
            #expect(!value.isNull)
        }

        @Test func parseNegativeInteger() throws {
            let value = try YYJSONValue(string: "-123")
            #expect(value.number == -123.0)
        }

        @Test func parseZero() throws {
            let value = try YYJSONValue(string: "0")
            #expect(value.number == 0.0)
        }

        @Test func parseFloat() throws {
            let value = try YYJSONValue(string: "3.14159")
            #expect(value.number != nil)
            #expect(abs(value.number! - 3.14159) < 0.00001)
        }

        @Test func parseNegativeFloat() throws {
            let value = try YYJSONValue(string: "-2.718")
            #expect(value.number != nil)
            #expect(abs(value.number! - (-2.718)) < 0.001)
        }

        @Test func parseScientificNotation() throws {
            let value = try YYJSONValue(string: "1.23e10")
            #expect(value.number != nil)
            #expect(abs(value.number! - 1.23e10) < 1e5)
        }

        @Test func parseString() throws {
            let value = try YYJSONValue(string: #""hello world""#)
            #expect(value.string == "hello world")
            #expect(!value.isNull)
        }

        @Test func parseEmptyString() throws {
            let value = try YYJSONValue(string: #""""#)
            #expect(value.string == "")
        }

        @Test func parseStringWithUnicode() throws {
            let value = try YYJSONValue(string: #""Hello 你好 🌍""#)
            #expect(value.string == "Hello 你好 🌍")
        }

        @Test func parseStringWithEscapes() throws {
            let value = try YYJSONValue(string: #""line1\nline2\ttab""#)
            #expect(value.string == "line1\nline2\ttab")
        }

        @Test func parseStringWithQuotes() throws {
            let value = try YYJSONValue(string: #""say \"hello\"""#)
            #expect(value.string == #"say "hello""#)
        }
    }

    // MARK: - YYJSONValue Array Tests

    @Suite("YYJSONValue - Arrays")
    struct ValueArrayTests {
        @Test func parseEmptyArray() throws {
            let value = try YYJSONValue(string: "[]")
            #expect(value.array != nil)
            #expect(value.array?.count == 0)
        }

        @Test func parseIntArray() throws {
            let value = try YYJSONValue(string: "[1, 2, 3, 4, 5]")
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 5)
            #expect(array[0]?.number == 1.0)
            #expect(array[1]?.number == 2.0)
            #expect(array[2]?.number == 3.0)
            #expect(array[3]?.number == 4.0)
            #expect(array[4]?.number == 5.0)
        }

        @Test func parseStringArray() throws {
            let value = try YYJSONValue(string: #"["a", "b", "c"]"#)
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 3)
            #expect(array[0]?.string == "a")
            #expect(array[1]?.string == "b")
            #expect(array[2]?.string == "c")
        }

        @Test func parseMixedArray() throws {
            let value = try YYJSONValue(string: #"[1, "two", true, null, 3.14]"#)
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 5)
            #expect(array[0]?.number == 1.0)
            #expect(array[1]?.string == "two")
            #expect(array[2]?.bool == true)
            #expect(array[3]?.isNull == true)
            #expect(array[4]?.number != nil)
        }

        @Test func parseNestedArray() throws {
            let value = try YYJSONValue(string: "[[1, 2], [3, 4], [5, 6]]")
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 3)
            #expect(array[0]?.array?[0]?.number == 1.0)
            #expect(array[0]?.array?[1]?.number == 2.0)
            #expect(array[1]?.array?[0]?.number == 3.0)
            #expect(array[2]?.array?[1]?.number == 6.0)
        }

        @Test func arraySubscriptOutOfBounds() throws {
            let value = try YYJSONValue(string: "[1, 2, 3]")
            #expect(value[10] == nil)
            #expect(value[-1] == nil)
        }

        @Test func arrayIteration() throws {
            let value = try YYJSONValue(string: "[1, 2, 3, 4, 5]")
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }

            var sum = 0.0
            for element in array {
                sum += element.number ?? 0
            }
            #expect(sum == 15.0)
        }

        @Test func arraySubscriptOnNonArray() throws {
            let value = try YYJSONValue(string: #""not an array""#)
            #expect(value[0] == nil)
        }
    }

    // MARK: - YYJSONValue Object Tests

    @Suite("YYJSONValue - Objects")
    struct ValueObjectTests {
        @Test func parseEmptyObject() throws {
            let value = try YYJSONValue(string: "{}")
            #expect(value.object != nil)
            #expect(value.object?.keys.isEmpty == true)
        }

        @Test func parseSimpleObject() throws {
            let value = try YYJSONValue(string: #"{"name": "Alice", "age": 30}"#)
            #expect(value["name"]?.string == "Alice")
            #expect(value["age"]?.number == 30.0)
        }

        @Test func parseNestedObject() throws {
            let json = """
                {
                    "person": {
                        "name": "Bob",
                        "address": {
                            "city": "New York",
                            "zip": "10001"
                        }
                    }
                }
                """
            let value = try YYJSONValue(string: json)
            #expect(value["person"]?["name"]?.string == "Bob")
            #expect(value["person"]?["address"]?["city"]?.string == "New York")
            #expect(value["person"]?["address"]?["zip"]?.string == "10001")
        }

        @Test func objectWithArray() throws {
            let json = #"{"items": [1, 2, 3]}"#
            let value = try YYJSONValue(string: json)
            guard let items = value["items"]?.array else {
                Issue.record("Expected array")
                return
            }
            #expect(items.count == 3)
            #expect(items[0]?.number == 1.0)
        }

        @Test func objectKeys() throws {
            let json = #"{"a": 1, "b": 2, "c": 3}"#
            let value = try YYJSONValue(string: json)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }
            let keys = obj.keys.sorted()
            #expect(keys == ["a", "b", "c"])
        }

        @Test func objectContains() throws {
            let json = #"{"a": 1, "b": 2}"#
            let value = try YYJSONValue(string: json)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }
            #expect(obj.contains("a"))
            #expect(obj.contains("b"))
            #expect(!obj.contains("c"))
        }

        @Test func objectIteration() throws {
            let json = #"{"a": 1, "b": 2, "c": 3}"#
            let value = try YYJSONValue(string: json)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }

            var dict: [String: Double] = [:]
            for (key, val) in obj {
                dict[key] = val.number
            }
            #expect(dict == ["a": 1.0, "b": 2.0, "c": 3.0])
        }

        @Test func objectSubscriptMissingKey() throws {
            let value = try YYJSONValue(string: #"{"a": 1}"#)
            #expect(value["missing"] == nil)
        }

        @Test func objectSubscriptOnNonObject() throws {
            let value = try YYJSONValue(string: "[1, 2, 3]")
            #expect(value["key"] == nil)
        }
    }

    // MARK: - YYJSONValue Description Tests

    @Suite("YYJSONValue - Description")
    struct ValueDescriptionTests {
        @Test func nullDescription() throws {
            let value = try YYJSONValue(string: "null")
            #expect(value.description == "null")
        }

        @Test func boolDescription() throws {
            let trueValue = try YYJSONValue(string: "true")
            let falseValue = try YYJSONValue(string: "false")
            #expect(trueValue.description == "true")
            #expect(falseValue.description == "false")
        }

        @Test func numberDescription() throws {
            let value = try YYJSONValue(string: "42")
            #expect(value.description.contains("42"))
        }

        @Test func stringDescription() throws {
            let value = try YYJSONValue(string: #""hello""#)
            #expect(value.description == #""hello""#)
        }

        @Test func arrayDescription() throws {
            let value = try YYJSONValue(string: "[1, 2, 3]")
            let desc = value.description
            #expect(desc.contains("["))
            #expect(desc.contains("]"))
        }

        @Test func objectDescription() throws {
            let value = try YYJSONValue(string: #"{"a": 1}"#)
            let desc = value.description
            #expect(desc.contains("{"))
            #expect(desc.contains("}"))
            #expect(desc.contains("a"))
        }
    }

    // MARK: - YYJSONValue Parsing Options Tests

    @Suite("YYJSONValue - Parsing Options")
    struct ValueParsingOptionsTests {
        @Test func parseWithDefaultOptions() throws {
            let json = #"{"key": "value"}"#
            let value = try YYJSONValue(string: json, options: .default)
            #expect(value["key"]?.string == "value")
        }

        @Test func parseFromData() throws {
            let json = #"{"key": "value"}"#
            let data = json.data(using: .utf8)!
            let value = try YYJSONValue(data: data)
            #expect(value["key"]?.string == "value")
        }

        @Test func parseInvalidJSON() throws {
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONValue(string: "not valid json")
            }
        }

        @Test func parseEmptyString() throws {
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONValue(string: "")
            }
        }

        @Test func parseIncompleteJSON() throws {
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONValue(string: #"{"key": "#)
            }
        }
    }

    // MARK: - YYJSONObject Tests

    @Suite("YYJSONObject - Direct Access")
    struct YYJSONObjectTests {
        @Test func objectSubscript() throws {
            let value = try YYJSONValue(string: #"{"a": 1, "b": "two"}"#)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }
            #expect(obj["a"]?.number == 1.0)
            #expect(obj["b"]?.string == "two")
            #expect(obj["c"] == nil)
        }

        @Test func objectKeysProperty() throws {
            let value = try YYJSONValue(string: #"{"x": 1, "y": 2, "z": 3}"#)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }
            #expect(Set(obj.keys) == Set(["x", "y", "z"]))
        }

        @Test func objectContainsMethod() throws {
            let value = try YYJSONValue(string: #"{"exists": true}"#)
            guard let obj = value.object else {
                Issue.record("Expected object")
                return
            }
            #expect(obj.contains("exists"))
            #expect(!obj.contains("missing"))
        }
    }

    // MARK: - YYJSONArray Tests

    @Suite("YYJSONArray - Direct Access")
    struct YYJSONArrayTests {
        @Test func arraySubscript() throws {
            let value = try YYJSONValue(string: "[10, 20, 30]")
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(arr[0]?.number == 10.0)
            #expect(arr[1]?.number == 20.0)
            #expect(arr[2]?.number == 30.0)
            #expect(arr[3] == nil)
        }

        @Test func arrayCount() throws {
            let value = try YYJSONValue(string: "[1, 2, 3, 4, 5]")
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(arr.count == 5)
        }

        @Test func emptyArrayCount() throws {
            let value = try YYJSONValue(string: "[]")
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(arr.count == 0)
        }

        @Test func arrayMap() throws {
            let value = try YYJSONValue(string: "[1, 2, 3]")
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            let doubled = arr.map { ($0.number ?? 0) * 2 }
            #expect(doubled == [2.0, 4.0, 6.0])
        }

        @Test func arrayFilter() throws {
            let value = try YYJSONValue(string: "[1, 2, 3, 4, 5]")
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            let evens = arr.filter { Int($0.number ?? 0) % 2 == 0 }
            #expect(evens.count == 2)
        }
    }

    // MARK: - Complex JSON Tests

    @Suite("YYJSONValue - Complex JSON")
    struct ValueComplexJSONTests {
        @Test func parseComplexJSON() throws {
            let json = """
                {
                    "users": [
                        {
                            "id": 1,
                            "name": "Alice",
                            "email": "alice@example.com",
                            "active": true,
                            "roles": ["admin", "user"]
                        },
                        {
                            "id": 2,
                            "name": "Bob",
                            "email": "bob@example.com",
                            "active": false,
                            "roles": ["user"]
                        }
                    ],
                    "meta": {
                        "total": 2,
                        "page": 1,
                        "perPage": 10
                    }
                }
                """
            let value = try YYJSONValue(string: json)

            #expect(value["meta"]?["total"]?.number == 2.0)
            #expect(value["meta"]?["page"]?.number == 1.0)

            guard let users = value["users"]?.array else {
                Issue.record("Expected users array")
                return
            }
            #expect(users.count == 2)

            let alice = users[0]
            #expect(alice?["id"]?.number == 1.0)
            #expect(alice?["name"]?.string == "Alice")
            #expect(alice?["active"]?.bool == true)
            #expect(alice?["roles"]?.array?.count == 2)

            let bob = users[1]
            #expect(bob?["id"]?.number == 2.0)
            #expect(bob?["active"]?.bool == false)
        }

        @Test func parseDeeplyNestedJSON() throws {
            let json = """
                {
                    "level1": {
                        "level2": {
                            "level3": {
                                "level4": {
                                    "level5": {
                                        "value": "deep"
                                    }
                                }
                            }
                        }
                    }
                }
                """
            let value = try YYJSONValue(string: json)
            let deep = value["level1"]?["level2"]?["level3"]?["level4"]?["level5"]?["value"]?.string
            #expect(deep == "deep")
        }

        @Test func parseLargeArray() throws {
            var elements: [String] = []
            for i in 0 ..< 1000 {
                elements.append(String(i))
            }
            let json = "[\(elements.joined(separator: ", "))]"
            let value = try YYJSONValue(string: json)
            guard let arr = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(arr.count == 1000)
            #expect(arr[0]?.number == 0.0)
            #expect(arr[999]?.number == 999.0)
        }
    }

    // MARK: - YYJSONValue cString Tests

    @Suite("YYJSONValue - cString Property")
    struct ValueCStringTests {
        @Test func cStringForBasicString() throws {
            let value = try YYJSONValue(string: #""hello world""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil for string value")
                return
            }
            let swiftString = String(cString: cString)
            #expect(swiftString == "hello world")
        }

        @Test func cStringForEmptyString() throws {
            let value = try YYJSONValue(string: #""""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil for empty string")
                return
            }
            let swiftString = String(cString: cString)
            #expect(swiftString == "")
        }

        @Test func cStringForUnicodeString() throws {
            let value = try YYJSONValue(string: #""Hello 你好 🌍""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil for Unicode string")
                return
            }
            let swiftString = String(cString: cString)
            #expect(swiftString == "Hello 你好 🌍")
        }

        @Test func cStringForStringWithEscapes() throws {
            let value = try YYJSONValue(string: #""line1\nline2\ttab""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil for string with escapes")
                return
            }
            let swiftString = String(cString: cString)
            #expect(swiftString == "line1\nline2\ttab")
        }

        @Test func cStringForStringWithQuotes() throws {
            let value = try YYJSONValue(string: #""say \"hello\"""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil for string with quotes")
                return
            }
            let swiftString = String(cString: cString)
            #expect(swiftString == #"say "hello""#)
        }

        @Test func cStringForNull() throws {
            let value = try YYJSONValue(string: "null")
            #expect(value.cString == nil)
        }

        @Test func cStringForBool() throws {
            let trueValue = try YYJSONValue(string: "true")
            let falseValue = try YYJSONValue(string: "false")
            #expect(trueValue.cString == nil)
            #expect(falseValue.cString == nil)
        }

        @Test func cStringForNumber() throws {
            let intValue = try YYJSONValue(string: "42")
            let floatValue = try YYJSONValue(string: "3.14")
            #expect(intValue.cString == nil)
            #expect(floatValue.cString == nil)
        }

        @Test func cStringForArray() throws {
            let value = try YYJSONValue(string: "[1, 2, 3]")
            #expect(value.cString == nil)
        }

        @Test func cStringForObject() throws {
            let value = try YYJSONValue(string: #"{"key": "value"}"#)
            #expect(value.cString == nil)
        }

        @Test func cStringMatchesStringProperty() throws {
            let testCases: [(json: String, expected: String)] = [
                (#""hello world""#, "hello world"),
                (#""""#, ""),
                (#""Hello 你好 🌍""#, "Hello 你好 🌍"),
                (#""line1\nline2\ttab""#, "line1\nline2\ttab"),
                (#""say \"hello\"""#, #"say "hello""#),
            ]

            for (json, expected) in testCases {
                let value = try YYJSONValue(string: json)
                guard let cString = value.cString else {
                    Issue.record("Expected cString for: \(expected)")
                    continue
                }
                let cStringValue = String(cString: cString)
                let stringValue = value.string
                #expect(cStringValue == expected)
                #expect(cStringValue == stringValue)
            }
        }

        @Test func cStringPointerIsValid() throws {
            let value = try YYJSONValue(string: #""test string""#)
            guard let cString = value.cString else {
                Issue.record("Expected cString to be non-nil")
                return
            }

            // Verify the pointer is valid by reading from it
            let length = strlen(cString)
            #expect(length == 11)  // "test string" length

            // Verify we can read the entire string (excluding null terminator)
            let buffer = UnsafeBufferPointer(start: cString, count: length)
            let data = Data(buffer: buffer)
            let reconstructed = String(data: data, encoding: .utf8)
            #expect(reconstructed == "test string")
        }

        @Test func cStringInNestedStructure() throws {
            let json = #"{"name": "Alice", "message": "Hello\nWorld"}"#
            let value = try YYJSONValue(string: json)

            guard let nameCString = value["name"]?.cString else {
                Issue.record("Expected cString for name")
                return
            }
            #expect(String(cString: nameCString) == "Alice")

            guard let messageCString = value["message"]?.cString else {
                Issue.record("Expected cString for message")
                return
            }
            #expect(String(cString: messageCString) == "Hello\nWorld")
        }

        @Test func cStringInArray() throws {
            let json = #"["first", "second", "third"]"#
            let value = try YYJSONValue(string: json)
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }

            guard let firstCString = array[0]?.cString else {
                Issue.record("Expected cString for first element")
                return
            }
            #expect(String(cString: firstCString) == "first")

            guard let secondCString = array[1]?.cString else {
                Issue.record("Expected cString for second element")
                return
            }
            #expect(String(cString: secondCString) == "second")
        }
    }

    // MARK: - In-Place Parsing Tests

    @Suite("YYJSONValue - In-Place Parsing")
    struct ValueInPlaceTests {
        @Test func parseInPlace() throws {
            let json = #"{"name": "test", "value": 42}"#
            var data = json.data(using: .utf8)!
            let value = try YYJSONValue.parseInPlace(consuming: &data)
            #expect(value["name"]?.string == "test")
            #expect(value["value"]?.number == 42.0)
        }

        @Test func parseInPlaceEmptyData() throws {
            var data = Data()
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONValue.parseInPlace(consuming: &data)
            }
        }

        @Test func parseInPlaceInvalidJSON() throws {
            var data = "not valid json".data(using: .utf8)!
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONValue.parseInPlace(consuming: &data)
            }
        }

        @Test func parseInPlaceArray() throws {
            let json = "[1, 2, 3, 4, 5]"
            var data = json.data(using: .utf8)!
            let value = try YYJSONValue.parseInPlace(consuming: &data)
            guard let array = value.array else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 5)
            #expect(array[0]?.number == 1.0)
            #expect(array[4]?.number == 5.0)
        }

        @Test func parseInPlacePrimitive() throws {
            var data = "42".data(using: .utf8)!
            let value = try YYJSONValue.parseInPlace(consuming: &data)
            #expect(value.number == 42.0)
        }

        @Test func parseInPlaceString() throws {
            var data = #""hello world""#.data(using: .utf8)!
            let value = try YYJSONValue.parseInPlace(consuming: &data)
            #expect(value.string == "hello world")
        }

        @Test func parseInPlaceDataRetained() throws {
            let json = #"{"key": "value"}"#
            var data = json.data(using: .utf8)!
            let value = try YYJSONValue.parseInPlace(consuming: &data)
            // Verify the value is still accessible after data is consumed
            #expect(value["key"]?.string == "value")
            // Access multiple times to ensure data is retained
            #expect(value["key"]?.string == "value")
            #expect(value["key"]?.string == "value")
        }
    }

    // MARK: - YYJSONDocument Tests

    @Suite("YYJSONDocument - Initialization")
    struct YYJSONDocumentInitTests {
        @Test func initFromData() throws {
            let json = #"{"name": "Alice", "age": 30}"#
            let data = json.data(using: .utf8)!
            let document = try YYJSONDocument(data: data)
            #expect(document.root != nil)
            #expect(document.root?["name"]?.string == "Alice")
            #expect(document.root?["age"]?.number == 30.0)
        }

        @Test func initFromString() throws {
            let json = #"{"key": "value"}"#
            let document = try YYJSONDocument(string: json)
            #expect(document.root != nil)
            #expect(document.root?["key"]?.string == "value")
        }

        @Test func initFromDataWithOptions() throws {
            let json = #"{"key": "value"}"#
            let data = json.data(using: .utf8)!
            let document = try YYJSONDocument(data: data, options: .default)
            #expect(document.root != nil)
            #expect(document.root?["key"]?.string == "value")
        }

        @Test func initFromStringWithOptions() throws {
            let json = #"{"key": "value"}"#
            let document = try YYJSONDocument(string: json, options: .default)
            #expect(document.root != nil)
            #expect(document.root?["key"]?.string == "value")
        }

        @Test func initFromEmptyData() throws {
            let data = Data()
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONDocument(data: data)
            }
        }

        @Test func initFromEmptyString() throws {
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONDocument(string: "")
            }
        }

        @Test func initFromInvalidJSON() throws {
            let data = "not valid json".data(using: .utf8)!
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONDocument(data: data)
            }
        }

        @Test func parsingInPlace() throws {
            let json = #"{"name": "test", "value": 42}"#
            var data = json.data(using: .utf8)!
            let document = try YYJSONDocument(parsingInPlace: &data)
            #expect(document.root != nil)
            #expect(document.root?["name"]?.string == "test")
            #expect(document.root?["value"]?.number == 42.0)
        }

        @Test func parsingInPlaceEmptyData() throws {
            var data = Data()
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONDocument(parsingInPlace: &data)
            }
        }

        @Test func parsingInPlaceInvalidJSON() throws {
            var data = "not valid json".data(using: .utf8)!
            #expect(throws: YYJSONError.self) {
                _ = try YYJSONDocument(parsingInPlace: &data)
            }
        }
    }

    @Suite("YYJSONDocument - Root Access")
    struct YYJSONDocumentRootTests {
        @Test func rootProperty() throws {
            let document = try YYJSONDocument(string: #"{"key": "value"}"#)
            #expect(document.root != nil)
            #expect(document.root?["key"]?.string == "value")
        }

        @Test func rootObjectProperty() throws {
            let document = try YYJSONDocument(string: #"{"key": "value"}"#)
            #expect(document.rootObject != nil)
            #expect(document.rootObject?["key"]?.string == "value")
        }

        @Test func rootArrayProperty() throws {
            let document = try YYJSONDocument(string: "[1, 2, 3]")
            #expect(document.rootArray != nil)
            #expect(document.rootArray?.count == 3)
            #expect(document.rootArray?[0]?.number == 1.0)
        }

        @Test func rootObjectOnArray() throws {
            let document = try YYJSONDocument(string: "[1, 2, 3]")
            #expect(document.rootObject == nil)
        }

        @Test func rootArrayOnObject() throws {
            let document = try YYJSONDocument(string: #"{"key": "value"}"#)
            #expect(document.rootArray == nil)
        }

        @Test func rootOnPrimitive() throws {
            let document = try YYJSONDocument(string: "42")
            #expect(document.root != nil)
            #expect(document.root?.number == 42.0)
            #expect(document.rootObject == nil)
            #expect(document.rootArray == nil)
        }

        @Test func rootOnString() throws {
            let document = try YYJSONDocument(string: #""hello""#)
            #expect(document.root != nil)
            #expect(document.root?.string == "hello")
        }

        @Test func rootOnNull() throws {
            let document = try YYJSONDocument(string: "null")
            #expect(document.root != nil)
            #expect(document.root?.isNull == true)
        }

        @Test func rootOnBool() throws {
            let document = try YYJSONDocument(string: "true")
            #expect(document.root != nil)
            #expect(document.root?.bool == true)
        }
    }

    @Suite("YYJSONDocument - Complex JSON")
    struct YYJSONDocumentComplexTests {
        @Test func nestedStructures() throws {
            let json = """
                {
                    "users": [
                        {"name": "Alice", "age": 30},
                        {"name": "Bob", "age": 25}
                    ],
                    "meta": {"count": 2}
                }
                """
            let document = try YYJSONDocument(string: json)
            guard let root = document.root else {
                Issue.record("Expected root")
                return
            }
            guard let users = root["users"]?.array else {
                Issue.record("Expected users array")
                return
            }
            #expect(users.count == 2)
            #expect(users[0]?["name"]?.string == "Alice")
            #expect(users[1]?["name"]?.string == "Bob")
            #expect(root["meta"]?["count"]?.number == 2.0)
        }

        @Test func largeDocument() throws {
            var elements: [String] = []
            for i in 0 ..< 100 {
                elements.append(String(i))
            }
            let json = "[\(elements.joined(separator: ", "))]"
            let document = try YYJSONDocument(string: json)
            guard let array = document.rootArray else {
                Issue.record("Expected array")
                return
            }
            #expect(array.count == 100)
            #expect(array[0]?.number == 0.0)
            #expect(array[99]?.number == 99.0)
        }
    }

    #if !YYJSON_DISABLE_WRITER

        @Suite("YYJSONValue - Writing")
        struct ValueWritingTests {
            @Test func writeSortedKeys() throws {
                let value = try YYJSONValue(string: #"{"b":1,"a":2}"#)
                let data = try value.data(options: [.sortedKeys])
                let json = String(data: data, encoding: .utf8)!
                let aIndex = json.range(of: "\"a\"")!.lowerBound
                let bIndex = json.range(of: "\"b\"")!.lowerBound
                #expect(aIndex < bIndex)
            }

            @Test func writeFragment() throws {
                let value = try YYJSONValue(string: "true")
                let data = try value.data()
                let json = String(data: data, encoding: .utf8)!
                #expect(json == "true")
            }
        }

    #endif  // !YYJSON_DISABLE_WRITER

#endif  // !YYJSON_DISABLE_READER
