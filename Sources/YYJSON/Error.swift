import Cyyjson
import Foundation

/// Errors that can occur when parsing, decoding, or encoding JSON.
public struct YYJSONError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The kind of error that occurred.
    public enum Kind: Equatable, Sendable {
        /// The JSON data was malformed.
        case invalidJSON
        /// The value was not of the expected type.
        case typeMismatch(expected: String, actual: String)
        /// A required key was not found.
        case missingKey(String)
        /// A required value was null or missing.
        case missingValue
        /// The data is corrupted or invalid.
        case invalidData
        /// An error occurred while writing JSON.
        case writeError
    }

    /// The kind of error.
    public let kind: Kind

    /// A detailed message describing the error.
    public let message: String

    /// The coding path where the error occurred (for decoding errors).
    public let path: String

    public var description: String {
        if path.isEmpty {
            return message
        }
        return "\(message) (at \(path))"
    }

    private init(kind: Kind, message: String, path: String = "") {
        self.kind = kind
        self.message = message
        self.path = path
    }

    // MARK: - Public Factory Methods

    /// Create an invalid JSON error.
    public static func invalidJSON(_ message: String) -> YYJSONError {
        YYJSONError(kind: .invalidJSON, message: message)
    }

    /// Create a type mismatch error.
    public static func typeMismatch(expected: String, actual: String, path: String = "") -> YYJSONError {
        YYJSONError(
            kind: .typeMismatch(expected: expected, actual: actual),
            message: "Expected \(expected), got \(actual)",
            path: path
        )
    }

    /// Create a missing key error.
    public static func missingKey(_ key: String, path: String = "") -> YYJSONError {
        YYJSONError(
            kind: .missingKey(key),
            message: "Missing key '\(key)'",
            path: path
        )
    }

    /// Create a missing value error.
    public static func missingValue(path: String = "") -> YYJSONError {
        YYJSONError(
            kind: .missingValue,
            message: "Value is null or missing",
            path: path
        )
    }

    /// Create an invalid data error.
    public static func invalidData(_ message: String, path: String = "") -> YYJSONError {
        YYJSONError(kind: .invalidData, message: message, path: path)
    }

    /// Create a write error.
    public static func writeError(_ message: String) -> YYJSONError {
        YYJSONError(kind: .writeError, message: message)
    }

    // MARK: - Internal Initializers

    /// Create an error from a yyjson read error.
    internal init(parsing error: yyjson_read_err) {
        let message: String
        switch error.code {
        case YYJSON_READ_ERROR_INVALID_PARAMETER:
            message = "Invalid parameter"
        case YYJSON_READ_ERROR_MEMORY_ALLOCATION:
            message = "Memory allocation failed"
        case YYJSON_READ_ERROR_EMPTY_CONTENT:
            message = "Empty content"
        case YYJSON_READ_ERROR_UNEXPECTED_CONTENT:
            message = "Unexpected content"
        case YYJSON_READ_ERROR_UNEXPECTED_END:
            message = "Unexpected end of input"
        case YYJSON_READ_ERROR_UNEXPECTED_CHARACTER:
            message = "Unexpected character at position \(error.pos)"
        case YYJSON_READ_ERROR_JSON_STRUCTURE:
            message = "Invalid JSON structure"
        case YYJSON_READ_ERROR_INVALID_COMMENT:
            message = "Invalid comment"
        case YYJSON_READ_ERROR_INVALID_NUMBER:
            message = "Invalid number"
        case YYJSON_READ_ERROR_INVALID_STRING:
            message = "Invalid string"
        case YYJSON_READ_ERROR_LITERAL:
            message = "Invalid literal"
        default:
            message = "Unknown read error (code: \(error.code))"
        }

        self.kind = .invalidJSON
        self.message = message
        self.path = ""
    }

    /// Create an error from a yyjson write error.
    internal init(writing error: yyjson_write_err) {
        let message: String
        switch error.code {
        case YYJSON_WRITE_ERROR_INVALID_PARAMETER:
            message = "Invalid parameter"
        case YYJSON_WRITE_ERROR_MEMORY_ALLOCATION:
            message = "Memory allocation failed"
        case YYJSON_WRITE_ERROR_INVALID_VALUE_TYPE:
            message = "Invalid value type"
        case YYJSON_WRITE_ERROR_NAN_OR_INF:
            message = "NaN or Infinity not allowed in JSON"
        case YYJSON_WRITE_ERROR_INVALID_STRING:
            message = "Invalid string"
        default:
            message = "Unknown write error (code: \(error.code))"
        }

        self.kind = .writeError
        self.message = message
        self.path = ""
    }
}
