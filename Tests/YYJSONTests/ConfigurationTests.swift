import Foundation
import Testing

@testable import YYJSON

// MARK: - Read Options Tests

@Suite("YYJSONReadOptions")
struct ReadOptionsTests {
    @Test func defaultOptions() {
        let options = YYJSONReadOptions.default
        #expect(options.rawValue == 0)
    }

    @Test func inSituOption() {
        let options = YYJSONReadOptions.inSitu
        #expect(options.rawValue != 0)
    }

    @Test func stopWhenDoneOption() throws {
        let json = #"{"key": "value"}  extra content"#
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .stopWhenDone)
        #expect(value["key"]?.string == "value")
    }

    @Test func allowTrailingCommasOption() throws {
        let json = #"{"a": 1, "b": 2,}"#
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowTrailingCommas)
        #expect(value["a"]?.number == 1.0)
        #expect(value["b"]?.number == 2.0)
    }

    @Test func allowCommentsOption() throws {
        let json = """
            {
                // Single line comment
                "key": "value"
                /* Multi-line
                   comment */
            }
            """
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowComments)
        #expect(value["key"]?.string == "value")
    }

    @Test func allowInfAndNaNOption() throws {
        let json = #"{"inf": Infinity, "nan": NaN}"#
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowInfAndNaN)
        #expect(value["inf"]?.number?.isInfinite == true)
        #expect(value["nan"]?.number?.isNaN == true)
    }

    @Test func allowInvalidUnicodeOption() throws {
        let options = YYJSONReadOptions.allowInvalidUnicode
        #expect(options.rawValue != 0)
    }

    @Test func allowBOMOption() throws {
        var json = Data([0xEF, 0xBB, 0xBF])
        json.append(#"{"key": "value"}"#.data(using: .utf8)!)

        let value = try YYJSONValue(data: json, options: .allowBOM)
        #expect(value["key"]?.string == "value")
    }

    @Test func allowExtendedNumbersOption() throws {
        let json = #"{"hex": 0xFF, "leadingPlus": +42}"#
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowExtendedNumbers)
        #expect(value["hex"]?.number == 255.0)
        #expect(value["leadingPlus"]?.number == 42.0)
    }

    @Test func allowSingleQuotedStringsOption() throws {
        let json = "{'key': 'value'}"
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowSingleQuotedStrings)
        #expect(value["key"]?.string == "value")
    }

    @Test func allowUnquotedKeysOption() throws {
        let json = "{key: \"value\"}"
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .allowUnquotedKeys)
        #expect(value["key"]?.string == "value")
    }

    @Test func json5Option() throws {
        let json = """
            {
                // This is JSON5
                key: 'value',
                number: +42,
            }
            """
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: .json5)
        #expect(value["key"]?.string == "value")
        #expect(value["number"]?.number == 42.0)
    }

    @Test func combinedOptions() throws {
        let options: YYJSONReadOptions = [.allowTrailingCommas, .allowComments]
        let json = """
            {
                // Comment
                "key": "value",
            }
            """
        let data = json.data(using: .utf8)!

        let value = try YYJSONValue(data: data, options: options)
        #expect(value["key"]?.string == "value")
    }

    @Test func optionSetOperations() {
        var options = YYJSONReadOptions.default
        options.insert(.allowTrailingCommas)
        #expect(options.contains(.allowTrailingCommas))

        options.remove(.allowTrailingCommas)
        #expect(!options.contains(.allowTrailingCommas))

        let combined = YYJSONReadOptions.allowComments.union(.allowTrailingCommas)
        #expect(combined.contains(.allowComments))
        #expect(combined.contains(.allowTrailingCommas))
    }
}

// MARK: - Write Options Tests

@Suite("YYJSONWriteOptions")
struct WriteOptionsTests {
    @Test func defaultOptions() {
        let options = YYJSONWriteOptions.default
        #expect(options.rawValue == 0)
    }

    @Test func prettyPrintedOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .prettyPrinted

        struct Simple: Codable {
            let key: String
        }

        let data = try encoder.encode(Simple(key: "value"))
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\n"))
        #expect(json.contains("    "))
    }

    @Test func prettyPrintedTwoSpacesOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .prettyPrintedTwoSpaces

        struct Simple: Codable {
            let key: String
        }

        let data = try encoder.encode(Simple(key: "value"))
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\n"))
        #expect(json.contains("  "))
    }

    @Test func escapeUnicodeOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .escapeUnicode

        let data = try encoder.encode("你好")
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\\u"))
        #expect(!json.contains("你"))
    }

    @Test func escapeSlashesOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .escapeSlashes

        let data = try encoder.encode("/path/to/file")
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\\/"))
    }

    @Test func allowInfAndNaNOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .allowInfAndNaN

        let data = try encoder.encode(Double.infinity)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("Infinity") || json.contains("inf"))
    }

    @Test func infAndNaNAsNullOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .infAndNaNAsNull

        let data = try encoder.encode(Double.infinity)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "null")
    }

    @Test func newlineAtEndOption() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = .newlineAtEnd

        let data = try encoder.encode("test")
        let json = String(data: data, encoding: .utf8)!
        #expect(json.hasSuffix("\n"))
    }

    @Test func combinedWriteOptions() throws {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.prettyPrinted, .newlineAtEnd]

        struct Simple: Codable {
            let key: String
        }

        let data = try encoder.encode(Simple(key: "value"))
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\n"))
        #expect(json.hasSuffix("\n"))
    }

    @Test func optionSetOperations() {
        var options = YYJSONWriteOptions.default
        options.insert(.prettyPrinted)
        #expect(options.contains(.prettyPrinted))

        options.remove(.prettyPrinted)
        #expect(!options.contains(.prettyPrinted))

        let combined = YYJSONWriteOptions.prettyPrinted.union(.newlineAtEnd)
        #expect(combined.contains(.prettyPrinted))
        #expect(combined.contains(.newlineAtEnd))
    }
}

// MARK: - JSON5 Decoding Options Tests

@Suite("JSON5DecodingOptions")
struct JSON5DecodingOptionsTests {
    @Test func booleanLiteralTrue() {
        let options: JSON5DecodingOptions = true
        #expect(options.trailingCommas)
        #expect(options.comments)
        #expect(options.infAndNaN)
        #expect(options.extendedNumbers)
        #expect(options.extendedEscapes)
        #expect(options.extendedWhitespace)
        #expect(options.singleQuotedStrings)
        #expect(options.unquotedKeys)
    }

    @Test func booleanLiteralFalse() {
        let options: JSON5DecodingOptions = false
        #expect(!options.trailingCommas)
        #expect(!options.comments)
        #expect(!options.infAndNaN)
        #expect(!options.extendedNumbers)
        #expect(!options.extendedEscapes)
        #expect(!options.extendedWhitespace)
        #expect(!options.singleQuotedStrings)
        #expect(!options.unquotedKeys)
    }

    @Test func selectiveOptions() {
        let options = JSON5DecodingOptions(
            trailingCommas: true,
            comments: true,
            infAndNaN: false,
            extendedNumbers: false,
            extendedEscapes: false,
            extendedWhitespace: false,
            singleQuotedStrings: false,
            unquotedKeys: false
        )
        #expect(options.trailingCommas)
        #expect(options.comments)
        #expect(!options.infAndNaN)
        #expect(!options.singleQuotedStrings)
    }

    @Test func readOptionsConversion() {
        let options = JSON5DecodingOptions(
            trailingCommas: true,
            comments: true
        )
        let readOptions = options.readOptions
        #expect(readOptions.contains(.allowTrailingCommas))
        #expect(readOptions.contains(.allowComments))
        #expect(!readOptions.contains(.allowInfAndNaN))
    }

    @Test func decoderWithJSON5Options() throws {
        let json = """
            {
                // Comment
                key: 'value',
            }
            """
        let data = json.data(using: .utf8)!

        struct Simple: Codable {
            let key: String
        }

        var decoder = YYJSONDecoder()
        decoder.allowsJSON5 = true
        let result = try decoder.decode(Simple.self, from: data)
        #expect(result.key == "value")
    }

    @Test func decoderWithSelectiveJSON5() throws {
        let json = #"{"key": "value",}"#
        let data = json.data(using: .utf8)!

        struct Simple: Codable {
            let key: String
        }

        var decoder = YYJSONDecoder()
        decoder.allowsJSON5 = JSON5DecodingOptions(trailingCommas: true)
        let result = try decoder.decode(Simple.self, from: data)
        #expect(result.key == "value")
    }

    @Test func json5OptionsSendable() async {
        let options: JSON5DecodingOptions = true
        await Task {
            #expect(options.trailingCommas)
        }.value
    }
}

// MARK: - Key Decoding Strategy Tests

@Suite("KeyDecodingStrategy")
struct KeyDecodingStrategyTests {
    struct SnakeCaseStruct: Codable {
        let firstName: String
        let lastName: String
        let emailAddress: String
    }

    @Test func useDefaultKeys() throws {
        let json = #"{"firstName": "John", "lastName": "Doe", "emailAddress": "john@example.com"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let result = try decoder.decode(SnakeCaseStruct.self, from: data)
        #expect(result.firstName == "John")
    }

    @Test func convertFromSnakeCase() throws {
        let json = #"{"first_name": "John", "last_name": "Doe", "email_address": "john@example.com"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(SnakeCaseStruct.self, from: data)
        #expect(result.firstName == "John")
        #expect(result.lastName == "Doe")
        #expect(result.emailAddress == "john@example.com")
    }

    @Test func convertFromSnakeCaseMultipleUnderscores() throws {
        struct MultiUnderscore: Codable {
            let myLongVariableName: String
        }

        let json = #"{"my_long_variable_name": "value"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(MultiUnderscore.self, from: data)
        #expect(result.myLongVariableName == "value")
    }

    @Test func customKeyStrategy() throws {
        struct UppercaseKeys: Codable {
            let value: String
        }

        let json = #"{"VALUE": "test"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            let lastKey = keys.last!
            return AnyCodingKey(stringValue: lastKey.stringValue.lowercased())
        }
        let result = try decoder.decode(UppercaseKeys.self, from: data)
        #expect(result.value == "test")
    }

    @Test func customKeyStrategyWithPath() throws {
        struct Nested: Codable {
            let inner: Inner
            struct Inner: Codable {
                let value: String
            }
        }

        let json = #"{"INNER": {"VALUE": "test"}}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            let lastKey = keys.last!
            return AnyCodingKey(stringValue: lastKey.stringValue.lowercased())
        }
        let result = try decoder.decode(Nested.self, from: data)
        #expect(result.inner.value == "test")
    }
}

// MARK: - Date Decoding Strategy Tests

@Suite("DateDecodingStrategy")
struct DateDecodingStrategyTests {
    struct DateContainer: Codable {
        let date: Date
    }

    @Test func deferredToDate() throws {
        let timestamp = Date().timeIntervalSinceReferenceDate
        let json = #"{"date": \#(timestamp)}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        let result = try decoder.decode(DateContainer.self, from: data)
        #expect(abs(result.date.timeIntervalSinceReferenceDate - timestamp) < 0.001)
    }

    @Test func iso8601() throws {
        let json = #"{"date": "2021-06-15T10:30:00Z"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(DateContainer.self, from: data)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: result.date)
        #expect(components.year == 2021)
        #expect(components.month == 6)
        #expect(components.day == 15)
    }

    @Test func secondsSince1970() throws {
        let json = #"{"date": 1623754200.0}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let result = try decoder.decode(DateContainer.self, from: data)
        #expect(result.date.timeIntervalSince1970 > 0)
    }

    @Test func millisecondsSince1970() throws {
        let json = #"{"date": 1623754200000.0}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let result = try decoder.decode(DateContainer.self, from: data)
        #expect(result.date.timeIntervalSince1970 > 0)
    }

    @Test func formattedDate() throws {
        let json = #"{"date": "15/06/2021"}"#
        let data = json.data(using: .utf8)!

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone(identifier: "UTC")

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        let result = try decoder.decode(DateContainer.self, from: data)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: result.date)
        #expect(components.year == 2021)
        #expect(components.month == 6)
        #expect(components.day == 15)
    }

    @Test func customDateStrategy() throws {
        let json = #"{"date": "2021-06-15"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
            }
            return date
        }
        let result = try decoder.decode(DateContainer.self, from: data)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: result.date)
        #expect(components.year == 2021)
        #expect(components.month == 6)
        #expect(components.day == 15)
    }
}

// MARK: - Data Decoding Strategy Tests

@Suite("DataDecodingStrategy")
struct DataDecodingStrategyTests {
    struct DataContainer: Codable {
        let data: Data
    }

    @Test func base64() throws {
        let json = #"{"data": "SGVsbG8gV29ybGQ="}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dataDecodingStrategy = .base64
        let result = try decoder.decode(DataContainer.self, from: data)
        #expect(String(data: result.data, encoding: .utf8) == "Hello World")
    }

    @Test func customDataStrategy() throws {
        let json = #"{"data": "48656c6c6f"}"#
        let data = json.data(using: .utf8)!

        var decoder = YYJSONDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let hexString = try container.decode(String.self)
            var result = Data()
            var hex = hexString
            while hex.count >= 2 {
                let byte = String(hex.prefix(2))
                hex = String(hex.dropFirst(2))
                if let value = UInt8(byte, radix: 16) {
                    result.append(value)
                }
            }
            return result
        }
        let result = try decoder.decode(DataContainer.self, from: data)
        #expect(String(data: result.data, encoding: .utf8) == "Hello")
    }
}

// MARK: - Non-Conforming Float Strategy Tests

@Suite("NonConformingFloatDecodingStrategy")
struct NonConformingFloatStrategyTests {
    struct FloatContainer: Codable {
        let value: Double
    }

    @Test func throwOnNonConformingDefaultsToThrow() throws {
        var decoder = YYJSONDecoder()
        switch decoder.nonConformingFloatDecodingStrategy {
        case .throw:
            #expect(true)
        default:
            Issue.record("Default should be .throw")
        }
    }

    @Test func convertFromStringPositiveInfinity() throws {
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

    @Test func convertFromStringNegativeInfinity() throws {
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

    @Test func convertFromStringNaN() throws {
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
