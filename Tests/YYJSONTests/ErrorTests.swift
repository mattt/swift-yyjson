import Foundation
import Testing

@testable import YYJSON

// MARK: - Error Kind Tests

@Suite("YYJSONError - Kinds")
struct ErrorKindTests {
    @Test func invalidJSONError() {
        let error = YYJSONError.invalidJSON("Test message")
        #expect(error.kind == .invalidJSON)
        #expect(error.message == "Test message")
        #expect(error.path.isEmpty)
    }

    @Test func typeMismatchError() {
        let error = YYJSONError.typeMismatch(expected: "string", actual: "number", path: "root.key")
        if case .typeMismatch(let expected, let actual) = error.kind {
            #expect(expected == "string")
            #expect(actual == "number")
        } else {
            Issue.record("Expected typeMismatch kind")
        }
        #expect(error.path == "root.key")
    }

    @Test func missingKeyError() {
        let error = YYJSONError.missingKey("requiredField", path: "root")
        if case .missingKey(let key) = error.kind {
            #expect(key == "requiredField")
        } else {
            Issue.record("Expected missingKey kind")
        }
    }

    @Test func missingValueError() {
        let error = YYJSONError.missingValue(path: "root.optional")
        #expect(error.kind == .missingValue)
        #expect(error.path == "root.optional")
    }

    @Test func invalidDataError() {
        let error = YYJSONError.invalidData("Data is corrupted", path: "root.data")
        #expect(error.kind == .invalidData)
        #expect(error.message == "Data is corrupted")
    }

    @Test func writeErrorError() {
        let error = YYJSONError.writeError("Failed to write")
        #expect(error.kind == .writeError)
        #expect(error.message == "Failed to write")
    }
}

// MARK: - Error Description Tests

@Suite("YYJSONError - Description")
struct ErrorDescriptionTests {
    @Test func descriptionWithoutPath() {
        let error = YYJSONError.invalidJSON("Invalid JSON structure")
        #expect(error.description == "Invalid JSON structure")
    }

    @Test func descriptionWithPath() {
        let error = YYJSONError.typeMismatch(expected: "string", actual: "number", path: "user.name")
        #expect(error.description.contains("user.name"))
        #expect(error.description.contains("Expected string, got number"))
    }

    @Test func missingKeyDescription() {
        let error = YYJSONError.missingKey("email", path: "user")
        #expect(error.description.contains("email"))
    }

    @Test func missingValueDescription() {
        let error = YYJSONError.missingValue(path: "data.value")
        #expect(error.description.contains("null or missing"))
    }
}

// MARK: - Error Equatable Tests

@Suite("YYJSONError - Equatable")
struct ErrorEquatableTests {
    @Test func sameErrorsAreEqual() {
        let error1 = YYJSONError.invalidJSON("message")
        let error2 = YYJSONError.invalidJSON("message")
        #expect(error1 == error2)
    }

    @Test func differentMessagesAreNotEqual() {
        let error1 = YYJSONError.invalidJSON("message1")
        let error2 = YYJSONError.invalidJSON("message2")
        #expect(error1 != error2)
    }

    @Test func differentKindsAreNotEqual() {
        let error1 = YYJSONError.invalidJSON("message")
        let error2 = YYJSONError.invalidData("message")
        #expect(error1 != error2)
    }

    @Test func typeMismatchEquality() {
        let error1 = YYJSONError.typeMismatch(expected: "string", actual: "number", path: "path")
        let error2 = YYJSONError.typeMismatch(expected: "string", actual: "number", path: "path")
        #expect(error1 == error2)
    }

    @Test func typeMismatchInequality() {
        let error1 = YYJSONError.typeMismatch(expected: "string", actual: "number", path: "path")
        let error2 = YYJSONError.typeMismatch(expected: "bool", actual: "number", path: "path")
        #expect(error1 != error2)
    }
}

// MARK: - Parsing Error Tests

@Suite("YYJSONError - Parsing Errors")
struct ErrorParsingTests {
    @Test func emptyContentError() throws {
        let data = Data()
        do {
            _ = try YYJSONValue(data: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func unexpectedCharacterError() throws {
        let json = "{ invalid }"
        do {
            _ = try YYJSONValue(string: json)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func unexpectedEndError() throws {
        let json = #"{"key": "#
        do {
            _ = try YYJSONValue(string: json)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func invalidNumberError() throws {
        let json = "123abc"
        do {
            _ = try YYJSONValue(string: json)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func invalidStringError() throws {
        let json = #""unterminated"#
        do {
            _ = try YYJSONValue(string: json)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func invalidLiteralError() throws {
        let json = "tru"
        do {
            _ = try YYJSONValue(string: json)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }

    @Test func invalidUTF8Error() throws {
        let invalidUTF8 = Data([0x22, 0xFE, 0xFF, 0x22])
        do {
            _ = try YYJSONValue(data: invalidUTF8)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidJSON)
        }
    }
}

// MARK: - Decoding Error Tests

@Suite("YYJSONError - Decoding Errors")
struct ErrorDecodingTests {
    struct SimpleStruct: Codable {
        let name: String
        let age: Int
    }

    @Test func missingRequiredKeyError() throws {
        let json = #"{"name": "Alice"}"#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(SimpleStruct.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            if case .missingKey(let key) = error.kind {
                #expect(key == "age")
            } else {
                Issue.record("Expected missingKey error kind")
            }
        }
    }

    @Test func typeMismatchErrorOnDecode() throws {
        // Decoder coerces numbers to strings, so test with an object instead
        let json = #"{"name": {"nested": "value"}, "age": 30}"#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(SimpleStruct.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            if case .typeMismatch(let expected, _) = error.kind {
                #expect(expected == "string")
            } else {
                Issue.record("Expected typeMismatch error kind, got \(error.kind)")
            }
        }
    }

    @Test func typeMismatchIntFromString() throws {
        let json = #"{"name": "Alice", "age": "thirty"}"#
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(SimpleStruct.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            if case .typeMismatch = error.kind {
                #expect(error.path.contains("age"))
            } else {
                Issue.record("Expected typeMismatch error kind")
            }
        }
    }

    @Test func typeMismatchExpectingArray() throws {
        let json = #"{"items": "not an array"}"#
        let data = json.data(using: .utf8)!

        struct Container: Codable {
            let items: [Int]
        }

        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(Container.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            if case .typeMismatch(let expected, _) = error.kind {
                #expect(expected == "array")
            } else {
                Issue.record("Expected typeMismatch error kind")
            }
        }
    }

    @Test func typeMismatchExpectingObject() throws {
        let json = "[1, 2, 3]"
        let data = json.data(using: .utf8)!
        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(SimpleStruct.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            if case .typeMismatch(let expected, _) = error.kind {
                #expect(expected == "object")
            } else {
                Issue.record("Expected typeMismatch error kind")
            }
        }
    }

    @Test func invalidBase64DataError() throws {
        let json = #"{"data": "not-valid-base64!!!"}"#
        let data = json.data(using: .utf8)!

        struct Container: Codable {
            let data: Data
        }

        var decoder = YYJSONDecoder()
        decoder.dataDecodingStrategy = .base64
        do {
            _ = try decoder.decode(Container.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidData)
        }
    }

    @Test func invalidISO8601DateError() throws {
        let json = #"{"date": "not-a-date"}"#
        let data = json.data(using: .utf8)!

        struct Container: Codable {
            let date: Date
        }

        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            _ = try decoder.decode(Container.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.kind == .invalidData)
        }
    }
}

// MARK: - Error Path Tests

@Suite("YYJSONError - Path Tracking")
struct ErrorPathTests {
    @Test func nestedPathTracking() throws {
        // Use an object instead of number since decoder coerces numbers to strings
        let json = """
            {
                "user": {
                    "profile": {
                        "name": {"nested": "value"}
                    }
                }
            }
            """
        let data = json.data(using: .utf8)!

        struct Profile: Codable {
            let name: String
        }
        struct User: Codable {
            let profile: Profile
        }
        struct Root: Codable {
            let user: User
        }

        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(Root.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.path.contains("user"))
            #expect(error.path.contains("profile"))
            #expect(error.path.contains("name"))
        }
    }

    @Test func arrayIndexPathTracking() throws {
        let json = """
            {
                "items": [
                    {"value": 1},
                    {"value": "not a number"},
                    {"value": 3}
                ]
            }
            """
        let data = json.data(using: .utf8)!

        struct Item: Codable {
            let value: Int
        }
        struct Root: Codable {
            let items: [Item]
        }

        let decoder = YYJSONDecoder()
        do {
            _ = try decoder.decode(Root.self, from: data)
            Issue.record("Expected error to be thrown")
        } catch let error as YYJSONError {
            #expect(error.path.contains("items"))
        }
    }
}

// MARK: - Sendable Tests

@Suite("YYJSONError - Sendable")
struct ErrorSendableTests {
    @Test func errorIsSendable() async {
        let error = YYJSONError.invalidJSON("test")
        await Task {
            #expect(error.message == "test")
        }.value
    }
}
