import Cyyjson
import Foundation

#if !YYJSON_DISABLE_READER

    // MARK: - Helper Functions

    @inline(__always)
    func yyToString(_ val: UnsafeMutablePointer<yyjson_val>) -> String {
        let ptr = unsafe_yyjson_get_str(val)!
        let len = unsafe_yyjson_get_len(val)
        let buf = UnsafeBufferPointer(start: UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self), count: len)
        return String(decoding: buf, as: UTF8.self)
    }

    @inline(__always)
    func yyObjGet(_ obj: UnsafeMutablePointer<yyjson_val>, key: String) -> UnsafeMutablePointer<yyjson_val>? {
        var tmp = key
        return tmp.withUTF8 { buf in
            guard let ptr = buf.baseAddress else { return nil }
            return yyjson_obj_getn(obj, ptr, buf.count)
        }
    }

    /// A decoder that decodes JSON data into Swift types using the yyjson library.
    public struct YYJSONDecoder {
        /// Options for reading JSON.
        public var readOptions: YYJSONReadOptions

        /// A value that determines how to decode a type's coding keys from JSON keys.
        public var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys

        /// The strategy used when decoding dates from part of a JSON object.
        public var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate

        /// The strategy that a decoder uses to decode raw data.
        public var dataDecodingStrategy: DataDecodingStrategy = .base64

        /// The strategy used by a decoder when it encounters exceptional floating-point values.
        public var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw

        #if !YYJSON_DISABLE_NON_STANDARD

            /// Specifies that decoding supports the JSON5 syntax.
            ///
            /// Set to `true` to enable all JSON5 features, or configure individual options:
            /// ```swift
            /// decoder.allowsJSON5 = true  // Enable all JSON5 features
            /// decoder.allowsJSON5 = .init(trailingCommas: true, comments: true)  // Selective
            /// ```
            public var allowsJSON5: JSON5DecodingOptions = false

        #endif  // !YYJSON_DISABLE_NON_STANDARD

        /// A dictionary you use to customize the decoding process by providing contextual information.
        public var userInfo: [CodingUserInfoKey: Any] = [:]

        /// Creates a new decoder with default options.
        public init() {
            self.readOptions = .default
            self.keyDecodingStrategy = .useDefaultKeys
            self.dateDecodingStrategy = .deferredToDate
            self.dataDecodingStrategy = .base64
            self.nonConformingFloatDecodingStrategy = .throw
            #if !YYJSON_DISABLE_NON_STANDARD
                self.allowsJSON5 = false
            #endif
            self.userInfo = [:]
        }

        /// Decodes a value of the given type from JSON data.
        /// - Parameters:
        ///   - type: The type to decode.
        ///   - data: The JSON data to decode.
        /// - Returns: A value of the requested type.
        /// - Throws: `YYJSONError` if decoding fails.
        public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
            var options = readOptions
            #if !YYJSON_DISABLE_NON_STANDARD
                options.formUnion(allowsJSON5.readOptions)
            #endif

            let document = try YYDocument(data: data, options: options)
            guard let root = document.root else {
                throw YYJSONError.invalidData("Document has no root value")
            }

            let decoder = _YYDecoder(
                value: root,
                codingPath: [],
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )

            return try T(from: decoder)
        }
    }

    // MARK: - JSON5 Decoding Options

    #if !YYJSON_DISABLE_NON_STANDARD

        /// Options for JSON5 decoding, allowing granular control over non-standard JSON features.
        ///
        /// Use `true` to enable all JSON5 features, or configure individual options:
        /// ```swift
        /// decoder.allowsJSON5 = true  // Enable all JSON5 features
        /// decoder.allowsJSON5 = .init(trailingCommas: true, comments: true)  // Selective
        /// ```
        public struct JSON5DecodingOptions: ExpressibleByBooleanLiteral, Sendable {
            /// Allow single trailing comma at the end of an object or array.
            public var trailingCommas: Bool

            /// Allow C-style single-line and multi-line comments.
            public var comments: Bool

            /// Allow inf/nan number and literal, case-insensitive.
            public var infAndNaN: Bool

            /// Allow extended number formats (hex, leading/trailing decimal point, leading plus).
            public var extendedNumbers: Bool

            /// Allow extended escape sequences in strings.
            public var extendedEscapes: Bool

            /// Allow extended whitespace characters.
            public var extendedWhitespace: Bool

            /// Allow strings enclosed in single quotes.
            public var singleQuotedStrings: Bool

            /// Allow object keys without quotes.
            public var unquotedKeys: Bool

            public init(booleanLiteral value: Bool) {
                self.trailingCommas = value
                self.comments = value
                self.infAndNaN = value
                self.extendedNumbers = value
                self.extendedEscapes = value
                self.extendedWhitespace = value
                self.singleQuotedStrings = value
                self.unquotedKeys = value
            }

            public init(
                trailingCommas: Bool = false,
                comments: Bool = false,
                infAndNaN: Bool = false,
                extendedNumbers: Bool = false,
                extendedEscapes: Bool = false,
                extendedWhitespace: Bool = false,
                singleQuotedStrings: Bool = false,
                unquotedKeys: Bool = false
            ) {
                self.trailingCommas = trailingCommas
                self.comments = comments
                self.infAndNaN = infAndNaN
                self.extendedNumbers = extendedNumbers
                self.extendedEscapes = extendedEscapes
                self.extendedWhitespace = extendedWhitespace
                self.singleQuotedStrings = singleQuotedStrings
                self.unquotedKeys = unquotedKeys
            }

            /// Convert to yyjson read options.
            internal var readOptions: YYJSONReadOptions {
                var options: YYJSONReadOptions = []
                if trailingCommas { options.insert(.allowTrailingCommas) }
                if comments { options.insert(.allowComments) }
                if infAndNaN { options.insert(.allowInfAndNaN) }
                if extendedNumbers { options.insert(.allowExtendedNumbers) }
                if extendedEscapes { options.insert(.allowExtendedEscapes) }
                if extendedWhitespace { options.insert(.allowExtendedWhitespace) }
                if singleQuotedStrings { options.insert(.allowSingleQuotedStrings) }
                if unquotedKeys { options.insert(.allowUnquotedKeys) }
                return options
            }
        }

    #endif  // !YYJSON_DISABLE_NON_STANDARD

    // MARK: - Decoding Strategies

    /// The values that determine how to decode a type's coding keys from JSON keys.
    public enum KeyDecodingStrategy {
        /// A key decoding strategy that doesn't change key names during decoding.
        case useDefaultKeys

        /// A key decoding strategy that converts snake-case keys to camel-case keys.
        case convertFromSnakeCase

        /// A key decoding strategy defined by the closure you supply.
        case custom(@Sendable ([CodingKey]) -> CodingKey)
    }

    /// The strategies available for formatting dates when decoding them from JSON.
    public enum DateDecodingStrategy {
        /// The strategy that uses formatting from the Date structure.
        case deferredToDate

        /// The strategy that formats dates according to the ISO 8601 standard.
        case iso8601

        /// The strategy that formats dates in terms of seconds since midnight UTC on January 1st, 1970.
        case secondsSince1970

        /// The strategy that formats dates in terms of milliseconds since midnight UTC on January 1st, 1970.
        case millisecondsSince1970

        /// The strategy that defers formatting settings to a supplied date formatter.
        case formatted(DateFormatter)

        /// The strategy that formats custom dates by calling a user-defined function.
        case custom(@Sendable (Decoder) throws -> Date)
    }

    /// The strategies for decoding raw data.
    public enum DataDecodingStrategy {
        /// The strategy that decodes data using Base 64 decoding.
        case base64

        /// The strategy that decodes data using the encoding specified by the data instance itself.
        case deferredToData

        /// The strategy that decodes data using a user-defined function.
        case custom(@Sendable (Decoder) throws -> Data)
    }

    /// The strategies for decoding nonconforming floating-point numbers, also known as IEEE 754 exceptional values.
    public enum NonConformingFloatDecodingStrategy: Sendable {
        /// The strategy that throws an error upon decoding an exceptional floating-point value.
        case `throw`

        /// The strategy that decodes exceptional floating-point values from a specified string representation.
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }

    // MARK: - Internal Decoder Implementation

    /// Internal decoder implementing the Decoder protocol.
    struct _YYDecoder: Decoder {
        let value: UnsafeMutablePointer<yyjson_val>?
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let keyDecodingStrategy: KeyDecodingStrategy
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy

        init(
            value: UnsafeMutablePointer<yyjson_val>?,
            codingPath: [CodingKey] = [],
            userInfo: [CodingUserInfoKey: Any] = [:],
            keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys,
            dateDecodingStrategy: DateDecodingStrategy = .deferredToDate,
            dataDecodingStrategy: DataDecodingStrategy = .base64,
            nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
        ) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.keyDecodingStrategy = keyDecodingStrategy
            self.dateDecodingStrategy = dateDecodingStrategy
            self.dataDecodingStrategy = dataDecodingStrategy
            self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
        where Key: CodingKey {
            guard let value = value else {
                throw YYJSONError.missingValue(path: pathString)
            }

            guard yyjson_is_obj(value) else {
                throw YYJSONError.typeMismatch(
                    expected: "object",
                    actual: typeString(value),
                    path: pathString
                )
            }

            let container = _YYKeyedDecodingContainer<Key>(
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return KeyedDecodingContainer(container)
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let value = value else {
                throw YYJSONError.missingValue(path: pathString)
            }

            guard yyjson_is_arr(value) else {
                throw YYJSONError.typeMismatch(
                    expected: "array",
                    actual: typeString(value),
                    path: pathString
                )
            }

            return _YYUnkeyedDecodingContainer(
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            _YYSingleValueDecodingContainer(
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
        }

        private var pathString: String {
            codingPath.map { $0.stringValue }.joined(separator: ".")
        }

        private func typeString(_ val: UnsafeMutablePointer<yyjson_val>) -> String {
            switch yyjson_get_type(val) {
            case YYJSON_TYPE_NULL:
                return "null"
            case YYJSON_TYPE_BOOL:
                return "bool"
            case YYJSON_TYPE_NUM:
                return "number"
            case YYJSON_TYPE_STR:
                return "string"
            case YYJSON_TYPE_ARR:
                return "array"
            case YYJSON_TYPE_OBJ:
                return "object"
            default:
                return "unknown"
            }
        }
    }

    // MARK: - Decoding Containers

    /// Keyed decoding container for JSON objects.
    struct _YYKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let value: UnsafeMutablePointer<yyjson_val>
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let keyDecodingStrategy: KeyDecodingStrategy
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy

        var allKeys: [Key] {
            var keys: [Key] = []
            var iter = yyjson_obj_iter_with(value)
            while let keyVal = yyjson_obj_iter_next(&iter) {
                let jsonKey = yyToString(keyVal)
                let decodedKey = decodeKey(jsonKey)
                if let key = Key(stringValue: decodedKey.stringValue) {
                    keys.append(key)
                }
            }
            return keys
        }

        func contains(_ key: Key) -> Bool {
            let jsonKey = encodeKey(key)
            return yyObjGet(value, key: jsonKey) != nil
        }

        private func decodeKey(_ jsonKey: String) -> CodingKey {
            switch keyDecodingStrategy {
            case .useDefaultKeys:
                return AnyCodingKey(stringValue: jsonKey)
            case .convertFromSnakeCase:
                return AnyCodingKey(stringValue: convertFromSnakeCase(jsonKey))
            case .custom(let transform):
                return transform(codingPath + [AnyCodingKey(stringValue: jsonKey)])
            }
        }

        private func encodeKey(_ key: Key) -> String {
            switch keyDecodingStrategy {
            case .useDefaultKeys:
                return key.stringValue
            case .convertFromSnakeCase:
                // Reverse: convert camelCase to snake_case
                return convertToSnakeCase(key.stringValue)
            case .custom:
                // For custom strategy, we need to search all keys
                // This is less efficient but necessary for correctness
                var iter = yyjson_obj_iter_with(value)
                while let keyVal = yyjson_obj_iter_next(&iter) {
                    let jsonKey = yyToString(keyVal)
                    let decodedKey = decodeKey(jsonKey)
                    if decodedKey.stringValue == key.stringValue {
                        return jsonKey
                    }
                }
                return key.stringValue
            }
        }

        private func convertFromSnakeCase(_ string: String) -> String {
            var result = ""
            var capitalizeNext = false
            for char in string {
                if char == "_" {
                    capitalizeNext = true
                } else {
                    if capitalizeNext {
                        result.append(char.uppercased())
                        capitalizeNext = false
                    } else {
                        result.append(char)
                    }
                }
            }
            return result
        }

        private func convertToSnakeCase(_ string: String) -> String {
            var result = ""
            for (index, char) in string.enumerated() {
                if char.isUppercase && index > 0 {
                    result.append("_")
                }
                result.append(char.lowercased())
            }
            return result
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            let jsonKey = encodeKey(key)
            guard let val = yyObjGet(value, key: jsonKey) else {
                return true
            }
            return yyjson_is_null(val)
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            try decodeValue(forKey: key) { val in
                if yyjson_is_bool(val) {
                    return yyjson_get_bool(val)
                }
                if yyjson_is_num(val) {
                    let num = yyjson_get_num(val)
                    return num != 0.0
                }
                if yyjson_is_str(val) {
                    let lowercased = yyToString(val).lowercased()
                    if lowercased == "true" || lowercased == "1" {
                        return true
                    }
                    if lowercased == "false" || lowercased == "0" {
                        return false
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "bool",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            try decodeValue(forKey: key) { val in
                if yyjson_is_str(val) {
                    return yyToString(val)
                }
                if yyjson_is_num(val) {
                    return String(yyjson_get_num(val))
                }
                if yyjson_is_bool(val) {
                    return yyjson_get_bool(val) ? "true" : "false"
                }
                throw YYJSONError.typeMismatch(
                    expected: "string",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            try decodeValue(forKey: key) { val in
                if yyjson_is_num(val) {
                    let num = yyjson_get_num(val)

                    if !num.isFinite {
                        switch nonConformingFloatDecodingStrategy {
                        case .throw:
                            throw YYJSONError.invalidData(
                                "Parsed JSON number \(num) does not fit in Double",
                                path: pathString(for: key)
                            )
                        case .convertFromString:
                            return num
                        }
                    }

                    return num
                }
                if yyjson_is_str(val) {
                    let string = yyToString(val)

                    switch nonConformingFloatDecodingStrategy {
                    case .throw:
                        break
                    case .convertFromString(let posInf, let negInf, let nan):
                        if string == posInf {
                            return .infinity
                        } else if string == negInf {
                            return -.infinity
                        } else if string == nan {
                            return .nan
                        }
                    }

                    if let num = Double(string) {
                        return num
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "number",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            Float(try decode(Double.self, forKey: key))
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try decodeValue(forKey: key) { val in
                if yyjson_is_num(val) {
                    if yyjson_is_int(val) {
                        let sint = yyjson_get_sint(val)
                        return Int(sint)
                    }
                    return Int(yyjson_get_num(val))
                }
                if yyjson_is_str(val) {
                    if let num = Int(yyToString(val)) {
                        return num
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "integer",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            Int8(try decode(Int.self, forKey: key))
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            Int16(try decode(Int.self, forKey: key))
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            Int32(try decode(Int.self, forKey: key))
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try decodeValue(forKey: key) { val in
                if yyjson_is_num(val) {
                    if yyjson_is_int(val) {
                        return yyjson_get_sint(val)
                    }
                    return Int64(yyjson_get_num(val))
                }
                if yyjson_is_str(val) {
                    if let num = Int64(yyToString(val)) {
                        return num
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "integer",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try decodeValue(forKey: key) { val in
                if yyjson_is_num(val) {
                    if yyjson_is_int(val) {
                        let uint = yyjson_get_uint(val)
                        return UInt(uint)
                    }
                    return UInt(yyjson_get_num(val))
                }
                if yyjson_is_str(val) {
                    if let num = UInt(yyToString(val)) {
                        return num
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "unsigned integer",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            UInt8(try decode(UInt.self, forKey: key))
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            UInt16(try decode(UInt.self, forKey: key))
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            UInt32(try decode(UInt.self, forKey: key))
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try decodeValue(forKey: key) { val in
                if yyjson_is_num(val) {
                    return yyjson_get_uint(val)
                }
                if yyjson_is_str(val) {
                    if let num = UInt64(yyToString(val)) {
                        return num
                    }
                }
                throw YYJSONError.typeMismatch(
                    expected: "unsigned integer",
                    actual: typeString(val),
                    path: pathString(for: key)
                )
            }
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            let jsonKey = encodeKey(key)
            let val = yyObjGet(value, key: jsonKey)

            // Handle special types
            if type == Date.self {
                let date = try decodeDate(from: val, path: pathString(for: key))
                return date as! T
            }

            if type == Data.self {
                let data = try decodeData(from: val, path: pathString(for: key))
                return data as! T
            }

            let decoder = _YYDecoder(
                value: val,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try T(from: decoder)
        }

        private func decodeDate(from value: UnsafeMutablePointer<yyjson_val>?, path: String) throws
            -> Date
        {
            guard let value = value else {
                throw YYJSONError.missingValue(path: path)
            }

            switch dateDecodingStrategy {
            case .deferredToDate:
                // Let Date's Decodable implementation handle it
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: keyDecodingStrategy,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Date(from: decoder)

            case .iso8601:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: string) {
                    return date
                }
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: string) {
                    return date
                }
                throw YYJSONError.invalidData(
                    "Expected date string to be ISO8601-formatted",
                    path: path
                )

            case .secondsSince1970:
                let seconds = try decode(Double.self, from: value, path: path)
                return Date(timeIntervalSince1970: seconds)

            case .millisecondsSince1970:
                let milliseconds = try decode(Double.self, from: value, path: path)
                return Date(timeIntervalSince1970: milliseconds / 1000.0)

            case .formatted(let formatter):
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let date = formatter.date(from: string) else {
                    throw YYJSONError.invalidData(
                        "Date string does not match format expected by formatter",
                        path: path
                    )
                }
                return date

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: keyDecodingStrategy,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        private func decodeData(from value: UnsafeMutablePointer<yyjson_val>?, path: String) throws
            -> Data
        {
            guard let value = value else {
                throw YYJSONError.missingValue(path: path)
            }

            switch dataDecodingStrategy {
            case .base64:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let data = Data(base64Encoded: string) else {
                    throw YYJSONError.invalidData(
                        "Encountered Base64-encoded string that cannot be decoded",
                        path: path
                    )
                }
                return data

            case .deferredToData:
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: keyDecodingStrategy,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Data(from: decoder)

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: keyDecodingStrategy,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        private func decode<T>(
            _ type: T.Type,
            from value: UnsafeMutablePointer<yyjson_val>,
            path: String
        ) throws -> T where T: BinaryFloatingPoint {
            if yyjson_is_num(value) {
                let num = yyjson_get_num(value)

                // Check for non-conforming floats
                if !num.isFinite {
                    switch nonConformingFloatDecodingStrategy {
                    case .throw:
                        throw YYJSONError.invalidData(
                            "Parsed JSON number \(num) does not fit in \(T.self)",
                            path: path
                        )
                    case .convertFromString(let posInf, let negInf, let nan):
                        if num == .infinity {
                            throw YYJSONError.invalidData(
                                "Expected \(posInf) but found infinity",
                                path: path
                            )
                        } else if num == -.infinity {
                            throw YYJSONError.invalidData(
                                "Expected \(negInf) but found negative infinity",
                                path: path
                            )
                        } else {
                            throw YYJSONError.invalidData(
                                "Expected \(nan) but found NaN",
                                path: path
                            )
                        }
                    }
                }

                return T(num)
            }

            throw YYJSONError.typeMismatch(expected: "number", actual: typeString(value), path: path)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
        {
            let jsonKey = encodeKey(key)
            let val = yyObjGet(value, key: jsonKey)
            let decoder = _YYDecoder(
                value: val,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try decoder.container(keyedBy: type)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            let jsonKey = encodeKey(key)
            let val = yyObjGet(value, key: jsonKey)
            let decoder = _YYDecoder(
                value: val,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try decoder.unkeyedContainer()
        }

        func superDecoder() throws -> Decoder {
            _YYDecoder(
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            let jsonKey = encodeKey(key)
            let val = yyObjGet(value, key: jsonKey)
            return _YYDecoder(
                value: val,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                keyDecodingStrategy: keyDecodingStrategy,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
        }

        private func decodeValue<T>(
            forKey key: Key,
            _ block: (UnsafeMutablePointer<yyjson_val>) throws -> T
        ) throws -> T {
            let jsonKey = encodeKey(key)
            guard let val = yyObjGet(value, key: jsonKey) else {
                throw YYJSONError.missingKey(key.stringValue, path: pathString(for: key))
            }
            return try block(val)
        }

        private func pathString(for key: Key) -> String {
            (codingPath + [key]).map { $0.stringValue }.joined(separator: ".")
        }

        private func typeString(_ val: UnsafeMutablePointer<yyjson_val>) -> String {
            switch yyjson_get_type(val) {
            case YYJSON_TYPE_NULL:
                return "null"
            case YYJSON_TYPE_BOOL:
                return "bool"
            case YYJSON_TYPE_NUM:
                return "number"
            case YYJSON_TYPE_STR:
                return "string"
            case YYJSON_TYPE_ARR:
                return "array"
            case YYJSON_TYPE_OBJ:
                return "object"
            default:
                return "unknown"
            }
        }
    }

    /// Unkeyed decoding container for JSON arrays.
    struct _YYUnkeyedDecodingContainer: UnkeyedDecodingContainer {
        let value: UnsafeMutablePointer<yyjson_val>
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy

        var currentIndex: Int = 0
        private var iterator: yyjson_arr_iter

        init(
            value: UnsafeMutablePointer<yyjson_val>,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            dateDecodingStrategy: DateDecodingStrategy = .deferredToDate,
            dataDecodingStrategy: DataDecodingStrategy = .base64,
            nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
        ) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateDecodingStrategy = dateDecodingStrategy
            self.dataDecodingStrategy = dataDecodingStrategy
            self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
            self.iterator = yyjson_arr_iter_with(value)
        }

        var count: Int? {
            Int(yyjson_arr_size(value))
        }

        var isAtEnd: Bool {
            var iter = iterator
            return !yyjson_arr_iter_has_next(&iter)
        }

        var currentCodingPath: [CodingKey] {
            codingPath + [AnyCodingKey(index: currentIndex)]
        }

        mutating func decodeNil() throws -> Bool {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            return yyjson_is_null(val)
        }

        mutating func decode(_ type: Bool.Type) throws -> Bool {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_bool(val) {
                return yyjson_get_bool(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "bool",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: String.Type) throws -> String {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_str(val) {
                return yyToString(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "string",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: Double.Type) throws -> Double {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_num(val) {
                let num = yyjson_get_num(val)

                if !num.isFinite {
                    switch nonConformingFloatDecodingStrategy {
                    case .throw:
                        throw YYJSONError.invalidData(
                            "Parsed JSON number \(num) does not fit in Double",
                            path: pathString
                        )
                    case .convertFromString:
                        return num
                    }
                }

                return num
            }
            if yyjson_is_str(val) {
                let string = yyToString(val)

                switch nonConformingFloatDecodingStrategy {
                case .throw:
                    break
                case .convertFromString(let posInf, let negInf, let nan):
                    if string == posInf {
                        return .infinity
                    } else if string == negInf {
                        return -.infinity
                    } else if string == nan {
                        return .nan
                    }
                }

                if let num = Double(string) {
                    return num
                }
            }
            throw YYJSONError.typeMismatch(
                expected: "number",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: Float.Type) throws -> Float {
            Float(try decode(Double.self))
        }

        mutating func decode(_ type: Int.Type) throws -> Int {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return Int(yyjson_get_sint(val))
                }
                return Int(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "integer",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            Int8(try decode(Int.self))
        }

        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            Int16(try decode(Int.self))
        }

        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            Int32(try decode(Int.self))
        }

        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return yyjson_get_sint(val)
                }
                return Int64(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "integer",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: UInt.Type) throws -> UInt {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return UInt(yyjson_get_uint(val))
                }
                return UInt(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "unsigned integer",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            UInt8(try decode(UInt.self))
        }

        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            UInt16(try decode(UInt.self))
        }

        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            UInt32(try decode(UInt.self))
        }

        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            if yyjson_is_num(val) {
                return yyjson_get_uint(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "unsigned integer",
                actual: typeString(val),
                path: pathString
            )
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1

            // Handle special types
            if type == Date.self {
                let date = try decodeDate(from: val, path: pathString)
                return date as! T
            }

            if type == Data.self {
                let data = try decodeData(from: val, path: pathString)
                return data as! T
            }

            let decoder = _YYDecoder(
                value: val,
                codingPath: currentCodingPath,
                userInfo: userInfo,
                keyDecodingStrategy: .useDefaultKeys,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try T(from: decoder)
        }

        private mutating func decodeDate(from value: UnsafeMutablePointer<yyjson_val>, path: String)
            throws -> Date
        {
            switch dateDecodingStrategy {
            case .deferredToDate:
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: currentCodingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Date(from: decoder)

            case .iso8601:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: string) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: string) {
                    return date
                }
                throw YYJSONError.invalidData(
                    "Expected date string to be ISO8601-formatted",
                    path: path
                )

            case .secondsSince1970:
                let seconds = try decode(Double.self)
                return Date(timeIntervalSince1970: seconds)

            case .millisecondsSince1970:
                let milliseconds = try decode(Double.self)
                return Date(timeIntervalSince1970: milliseconds / 1000.0)

            case .formatted(let formatter):
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let date = formatter.date(from: string) else {
                    throw YYJSONError.invalidData(
                        "Date string does not match format expected by formatter",
                        path: path
                    )
                }
                return date

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: currentCodingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        private func decodeData(from value: UnsafeMutablePointer<yyjson_val>, path: String) throws
            -> Data
        {
            switch dataDecodingStrategy {
            case .base64:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let data = Data(base64Encoded: string) else {
                    throw YYJSONError.invalidData(
                        "Encountered Base64-encoded string that cannot be decoded",
                        path: path
                    )
                }
                return data

            case .deferredToData:
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: currentCodingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Data(from: decoder)

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: currentCodingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
        {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            let decoder = _YYDecoder(
                value: val,
                codingPath: currentCodingPath,
                userInfo: userInfo,
                keyDecodingStrategy: .useDefaultKeys,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try decoder.container(keyedBy: type)
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            let decoder = _YYDecoder(
                value: val,
                codingPath: currentCodingPath,
                userInfo: userInfo,
                keyDecodingStrategy: .useDefaultKeys,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try decoder.unkeyedContainer()
        }

        mutating func superDecoder() throws -> Decoder {
            guard let val = yyjson_arr_iter_next(&iterator) else {
                throw YYJSONError.missingValue(path: pathString)
            }
            currentIndex += 1
            return _YYDecoder(
                value: val,
                codingPath: currentCodingPath,
                userInfo: userInfo,
                keyDecodingStrategy: .useDefaultKeys,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
        }

        private var pathString: String {
            currentCodingPath.map { $0.stringValue }.joined(separator: ".")
        }

        private func typeString(_ val: UnsafeMutablePointer<yyjson_val>) -> String {
            switch yyjson_get_type(val) {
            case YYJSON_TYPE_NULL:
                return "null"
            case YYJSON_TYPE_BOOL:
                return "bool"
            case YYJSON_TYPE_NUM:
                return "number"
            case YYJSON_TYPE_STR:
                return "string"
            case YYJSON_TYPE_ARR:
                return "array"
            case YYJSON_TYPE_OBJ:
                return "object"
            default:
                return "unknown"
            }
        }
    }

    /// Single value decoding container.
    struct _YYSingleValueDecodingContainer: SingleValueDecodingContainer {
        let value: UnsafeMutablePointer<yyjson_val>?
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy

        init(
            value: UnsafeMutablePointer<yyjson_val>?,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            dateDecodingStrategy: DateDecodingStrategy = .deferredToDate,
            dataDecodingStrategy: DataDecodingStrategy = .base64,
            nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
        ) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateDecodingStrategy = dateDecodingStrategy
            self.dataDecodingStrategy = dataDecodingStrategy
            self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        }

        func decodeNil() -> Bool {
            guard let val = value else { return true }
            return yyjson_is_null(val)
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_bool(val) {
                return yyjson_get_bool(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "bool",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: String.Type) throws -> String {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_str(val) {
                return yyToString(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "string",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: Double.Type) throws -> Double {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_num(val) {
                let num = yyjson_get_num(val)

                if !num.isFinite {
                    switch nonConformingFloatDecodingStrategy {
                    case .throw:
                        throw YYJSONError.invalidData(
                            "Parsed JSON number \(num) does not fit in Double",
                            path: pathString
                        )
                    case .convertFromString:
                        return num
                    }
                }

                return num
            }
            if yyjson_is_str(val) {
                let string = yyToString(val)

                switch nonConformingFloatDecodingStrategy {
                case .throw:
                    break
                case .convertFromString(let posInf, let negInf, let nan):
                    if string == posInf {
                        return .infinity
                    } else if string == negInf {
                        return -.infinity
                    } else if string == nan {
                        return .nan
                    }
                }

                if let num = Double(string) {
                    return num
                }
            }
            throw YYJSONError.typeMismatch(
                expected: "number",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: Float.Type) throws -> Float {
            Float(try decode(Double.self))
        }

        func decode(_ type: Int.Type) throws -> Int {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return Int(yyjson_get_sint(val))
                }
                return Int(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "integer",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            Int8(try decode(Int.self))
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            Int16(try decode(Int.self))
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            Int32(try decode(Int.self))
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return yyjson_get_sint(val)
                }
                return Int64(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "integer",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_num(val) {
                if yyjson_is_int(val) {
                    return UInt(yyjson_get_uint(val))
                }
                return UInt(yyjson_get_num(val))
            }
            throw YYJSONError.typeMismatch(
                expected: "unsigned integer",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            UInt8(try decode(UInt.self))
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            UInt16(try decode(UInt.self))
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            UInt32(try decode(UInt.self))
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }
            if yyjson_is_num(val) {
                return yyjson_get_uint(val)
            }
            throw YYJSONError.typeMismatch(
                expected: "unsigned integer",
                actual: typeString(val),
                path: pathString
            )
        }

        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            guard let val = value else {
                throw YYJSONError.missingValue(path: pathString)
            }

            // Handle special types
            if type == Date.self {
                let date = try decodeDate(from: val, path: pathString)
                return date as! T
            }

            if type == Data.self {
                let data = try decodeData(from: val, path: pathString)
                return data as! T
            }

            let decoder = _YYDecoder(
                value: val,
                codingPath: codingPath,
                userInfo: userInfo,
                keyDecodingStrategy: .useDefaultKeys,
                dateDecodingStrategy: dateDecodingStrategy,
                dataDecodingStrategy: dataDecodingStrategy,
                nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
            )
            return try T(from: decoder)
        }

        private func decodeDate(from value: UnsafeMutablePointer<yyjson_val>, path: String) throws
            -> Date
        {
            switch dateDecodingStrategy {
            case .deferredToDate:
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Date(from: decoder)

            case .iso8601:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: string) {
                    return date
                }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: string) {
                    return date
                }
                throw YYJSONError.invalidData(
                    "Expected date string to be ISO8601-formatted",
                    path: path
                )

            case .secondsSince1970:
                let seconds = try decode(Double.self)
                return Date(timeIntervalSince1970: seconds)

            case .millisecondsSince1970:
                let milliseconds = try decode(Double.self)
                return Date(timeIntervalSince1970: milliseconds / 1000.0)

            case .formatted(let formatter):
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let date = formatter.date(from: string) else {
                    throw YYJSONError.invalidData(
                        "Date string does not match format expected by formatter",
                        path: path
                    )
                }
                return date

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        private func decodeData(from value: UnsafeMutablePointer<yyjson_val>, path: String) throws
            -> Data
        {
            switch dataDecodingStrategy {
            case .base64:
                guard yyjson_is_str(value) else {
                    throw YYJSONError.typeMismatch(
                        expected: "string",
                        actual: typeString(value),
                        path: path
                    )
                }
                let string = yyToString(value)
                guard let data = Data(base64Encoded: string) else {
                    throw YYJSONError.invalidData(
                        "Encountered Base64-encoded string that cannot be decoded",
                        path: path
                    )
                }
                return data

            case .deferredToData:
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try Data(from: decoder)

            case .custom(let closure):
                let decoder = _YYDecoder(
                    value: value,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    keyDecodingStrategy: .useDefaultKeys,
                    dateDecodingStrategy: dateDecodingStrategy,
                    dataDecodingStrategy: dataDecodingStrategy,
                    nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy
                )
                return try closure(decoder)
            }
        }

        private var pathString: String {
            codingPath.map { $0.stringValue }.joined(separator: ".")
        }

        private func typeString(_ val: UnsafeMutablePointer<yyjson_val>) -> String {
            switch yyjson_get_type(val) {
            case YYJSON_TYPE_NULL:
                return "null"
            case YYJSON_TYPE_BOOL:
                return "bool"
            case YYJSON_TYPE_NUM:
                return "number"
            case YYJSON_TYPE_STR:
                return "string"
            case YYJSON_TYPE_ARR:
                return "array"
            case YYJSON_TYPE_OBJ:
                return "object"
            default:
                return "unknown"
            }
        }
    }

#endif  // !YYJSON_DISABLE_READER
