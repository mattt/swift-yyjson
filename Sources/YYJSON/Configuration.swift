import Cyyjson
import Foundation

/// Options for reading JSON data.
public struct YYJSONReadOptions: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Default option (RFC 8259 compliant).
    public static let `default` = YYJSONReadOptions([])

    /// Stops when done instead of issuing an error if there's additional content
    /// after a JSON document.
    public static let stopWhenDone = YYJSONReadOptions(rawValue: YYJSON_READ_STOP_WHEN_DONE)

    /// Read all numbers as raw strings.
    public static let numberAsRaw = YYJSONReadOptions(rawValue: YYJSON_READ_NUMBER_AS_RAW)

    /// Allow reading invalid unicode when parsing string values.
    public static let allowInvalidUnicode = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_INVALID_UNICODE)

    /// Read big numbers as raw strings.
    public static let bigNumberAsRaw = YYJSONReadOptions(rawValue: YYJSON_READ_BIGNUM_AS_RAW)

    #if !YYJSON_DISABLE_NON_STANDARD

        /// Allow single trailing comma at the end of an object or array.
        public static let allowTrailingCommas = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_TRAILING_COMMAS)

        /// Allow C-style single-line and multi-line comments.
        public static let allowComments = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_COMMENTS)

        /// Allow inf/nan number and literal, case-insensitive.
        public static let allowInfAndNaN = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_INF_AND_NAN)

        /// Allow UTF-8 BOM and skip it before parsing.
        public static let allowBOM = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_BOM)

        /// Allow extended number formats (hex, leading/trailing decimal point, leading plus).
        public static let allowExtendedNumbers = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_EXT_NUMBER)

        /// Allow extended escape sequences in strings.
        public static let allowExtendedEscapes = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_EXT_ESCAPE)

        /// Allow extended whitespace characters.
        public static let allowExtendedWhitespace = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_EXT_WHITESPACE)

        /// Allow strings enclosed in single quotes.
        public static let allowSingleQuotedStrings = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_SINGLE_QUOTED_STR)

        /// Allow object keys without quotes.
        public static let allowUnquotedKeys = YYJSONReadOptions(rawValue: YYJSON_READ_ALLOW_UNQUOTED_KEY)

        /// Allow JSON5 format.
        ///
        /// This includes trailing commas, comments, inf/nan, extended numbers,
        /// extended escapes, extended whitespace, single-quoted strings, and unquoted keys.
        public static let json5 = YYJSONReadOptions(rawValue: YYJSON_READ_JSON5)

    #endif  // !YYJSON_DISABLE_NON_STANDARD

    /// Convert to yyjson read flags.
    internal var yyjsonFlags: yyjson_read_flag {
        yyjson_read_flag(rawValue)
    }
}

/// Options for writing JSON data.
public struct YYJSONWriteOptions: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Default option (minified output).
    public static let `default` = YYJSONWriteOptions([])

    /// Write JSON pretty with 4 space indent.
    public static let prettyPrinted = YYJSONWriteOptions(rawValue: YYJSON_WRITE_PRETTY)

    /// Write JSON pretty with 2 space indent (implies `prettyPrinted`).
    public static let indentationTwoSpaces = YYJSONWriteOptions(rawValue: YYJSON_WRITE_PRETTY_TWO_SPACES)

    /// Escape unicode as `\uXXXX`, making the output ASCII only.
    public static let escapeUnicode = YYJSONWriteOptions(rawValue: YYJSON_WRITE_ESCAPE_UNICODE)

    /// Escape '/' as '\/'.
    public static let escapeSlashes = YYJSONWriteOptions(rawValue: YYJSON_WRITE_ESCAPE_SLASHES)

    #if !YYJSON_DISABLE_NON_STANDARD

        /// Writes infinity and NaN values as `Infinity` and `NaN` literals.
        ///
        /// If you set `infAndNaNAsNull`, it takes precedence.
        public static let allowInfAndNaN = YYJSONWriteOptions(rawValue: YYJSON_WRITE_ALLOW_INF_AND_NAN)

        /// Writes infinity and NaN values as `null` literals.
        ///
        /// This option takes precedence over `allowInfAndNaN`.
        public static let infAndNaNAsNull = YYJSONWriteOptions(rawValue: YYJSON_WRITE_INF_AND_NAN_AS_NULL)

    #endif  // !YYJSON_DISABLE_NON_STANDARD

    /// Allow invalid unicode when encoding string values.
    public static let allowInvalidUnicode = YYJSONWriteOptions(rawValue: YYJSON_WRITE_ALLOW_INVALID_UNICODE)

    /// Add a newline character at the end of the JSON.
    public static let newlineAtEnd = YYJSONWriteOptions(rawValue: YYJSON_WRITE_NEWLINE_AT_END)

    /// Sorts object keys lexicographically.
    public static let sortedKeys = YYJSONWriteOptions(rawValue: 1 << 16)

    // Mask for Swift-only flags (bits 16+) that should not be passed to yyjson C library
    private static let swiftOnlyFlagsMask: UInt32 = 0xFFFF_0000

    /// Convert to yyjson write flags, excluding Swift-only flags.
    internal var yyjsonFlags: yyjson_write_flag {
        // Only pass bits 0-15 to yyjson C library; bits 16+ are Swift-only flags
        yyjson_write_flag(rawValue & ~YYJSONWriteOptions.swiftOnlyFlagsMask)
    }
}
