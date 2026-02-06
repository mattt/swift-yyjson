import Cyyjson
import Foundation

/// An object that converts between JSON and the equivalent Foundation objects.
/// This provides a drop-in replacement for Foundation's JSONSerialization using yyjson.
public enum YYJSONSerialization {
    /// Options used when creating Foundation objects from JSON data.
    public struct ReadingOptions: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Specifies that arrays and dictionaries in the returned object are mutable.
        public static let mutableContainers = ReadingOptions(rawValue: 1 << 0)

        /// Specifies that leaf strings in the JSON object graph are mutable.
        public static let mutableLeaves = ReadingOptions(rawValue: 1 << 1)

        /// Specifies that the parser allows top-level objects that aren't arrays or dictionaries.
        public static let fragmentsAllowed = ReadingOptions(rawValue: 1 << 2)

        #if !YYJSON_DISABLE_NON_STANDARD

            /// Specifies that reading serialized JSON data supports the JSON5 syntax.
            public static let json5Allowed = ReadingOptions(rawValue: 1 << 3)

        #endif  // !YYJSON_DISABLE_NON_STANDARD

        /// A deprecated option that specifies that the parser should allow top-level objects
        /// that aren't arrays or dictionaries.
        @available(*, deprecated, renamed: "fragmentsAllowed")
        public static let allowFragments = fragmentsAllowed
    }

    /// Options for writing JSON data.
    public struct WritingOptions: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Specifies that the writer should allow top-level values that aren't arrays or dictionaries.
        public static let fragmentsAllowed = WritingOptions(rawValue: 1 << 0)

        /// Specifies that the output uses white space and indentation to make the resulting data more readable.
        public static let prettyPrinted = WritingOptions(rawValue: 1 << 1)

        /// Specifies that the output sorts keys in lexicographic order.
        public static let sortedKeys = WritingOptions(rawValue: 1 << 2)

        /// Specifies that the output doesn't prefix slash characters with escape characters.
        public static let withoutEscapingSlashes = WritingOptions(rawValue: 1 << 3)

        /// Specifies that the output uses white space and 2-space indentation.
        /// This flag overrides `prettyPrinted` if both are set.
        public static let prettyPrintedTwoSpaces = WritingOptions(rawValue: 1 << 4)

        /// Escape non-ASCII characters in string values as `\uXXXX`, making the output ASCII only.
        /// Scalars outside the BMP are emitted as surrogate pairs.
        public static let escapeUnicode = WritingOptions(rawValue: 1 << 5)

        /// Add a single newline character `\n` at the end of the JSON.
        public static let newlineAtEnd = WritingOptions(rawValue: 1 << 6)
    }

    /// Returns a Foundation object from given JSON data.
    /// - Parameters:
    ///   - data: The JSON data to parse.
    ///   - options: Options for reading the JSON.
    /// - Returns: A Foundation object (NSArray, NSDictionary, NSString, NSNumber, or NSNull).
    /// - Throws: `YYJSONError` if parsing fails.
    #if !YYJSON_DISABLE_READER
        public static func jsonObject(with data: Data, options: ReadingOptions = []) throws -> Any {
            var readOptions: YYJSONReadOptions = .default
            #if !YYJSON_DISABLE_NON_STANDARD
                if options.contains(.json5Allowed) {
                    readOptions.insert(.json5)
                }
            #endif

            let document = try YYDocument(data: data, options: readOptions)
            guard let root = document.root else {
                throw YYJSONError.invalidData("Document has no root value")
            }

            let value = YYJSONValue(value: root, document: document)
            let result = try value.toFoundationObject(options: options)

            if options.contains(.fragmentsAllowed) {
                return result
            }

            if result is NSArray || result is NSDictionary {
                return result
            }

            throw YYJSONError.invalidData("Top-level JSON value must be an array or dictionary")
        }
    #endif  // !YYJSON_DISABLE_READER

    /// Returns JSON data from a Foundation object.
    /// - Parameters:
    ///   - obj: The Foundation object to convert (NSArray, NSDictionary, or a scalar with `.fragmentsAllowed`).
    ///          `YYJSONValue`, `YYJSONObject`, and `YYJSONArray` are also supported.
    ///   - options: Options for writing the JSON.
    /// - Returns: The JSON data.
    /// - Throws: `YYJSONError` if conversion fails.
    #if !YYJSON_DISABLE_WRITER
        public static func data(withJSONObject obj: Any, options: WritingOptions = []) throws -> Data {
            #if !YYJSON_DISABLE_READER
                if let jsonValue = obj as? YYJSONValue {
                    return try data(withJSONValue: jsonValue, options: options)
                }
                if let jsonObject = obj as? YYJSONObject {
                    let value = YYJSONValue(value: jsonObject.value, document: jsonObject.document)
                    return try data(withJSONValue: value, options: options)
                }
                if let jsonArray = obj as? YYJSONArray {
                    let value = YYJSONValue(value: jsonArray.value, document: jsonArray.document)
                    return try data(withJSONValue: value, options: options)
                }
            #endif  // !YYJSON_DISABLE_READER

            let isTopLevelContainer = obj is NSArray || obj is NSDictionary
            let isFragment = obj is NSString || obj is NSNumber || obj is NSNull

            if isTopLevelContainer {
                guard isValidJSONObject(obj) else {
                    throw YYJSONError.invalidData("Invalid JSON object")
                }
            } else if isFragment {
                guard options.contains(.fragmentsAllowed) else {
                    throw YYJSONError.invalidData("Top-level JSON value must be an array or dictionary")
                }
            } else {
                throw YYJSONError.invalidData("Invalid JSON object")
            }

            guard let doc = yyjson_mut_doc_new(nil) else {
                throw YYJSONError.invalidData("Failed to create document")
            }
            defer {
                yyjson_mut_doc_free(doc)
            }

            let root = try foundationObjectToYYJSON(obj, doc: doc, options: options)
            yyjson_mut_doc_set_root(doc, root)

            var flags: yyjson_write_flag = 0

            // Pretty printing: 2-space overrides 4-space
            if options.contains(.prettyPrintedTwoSpaces) {
                flags |= YYJSON_WRITE_PRETTY_TWO_SPACES
            } else if options.contains(.prettyPrinted) {
                flags |= YYJSON_WRITE_PRETTY
            }

            // Escaping options
            if !options.contains(.withoutEscapingSlashes) {
                flags |= YYJSON_WRITE_ESCAPE_SLASHES
            }
            if options.contains(.escapeUnicode) {
                flags |= YYJSON_WRITE_ESCAPE_UNICODE
            }

            // Formatting options
            if options.contains(.newlineAtEnd) {
                flags |= YYJSON_WRITE_NEWLINE_AT_END
            }

            var error = yyjson_write_err()
            var length: size_t = 0

            guard let jsonString = yyjson_mut_val_write_opts(root, flags, nil, &length, &error) else {
                throw YYJSONError(writing: error)
            }

            defer {
                free(jsonString)
            }

            return Data(bytes: jsonString, count: length)
        }
    #endif  // !YYJSON_DISABLE_WRITER

    /// Returns a Boolean value that indicates whether the serializer can convert a given object to JSON data.
    /// - Parameter obj: The object to validate.
    /// - Returns: `true` if the object can be converted to JSON, `false` otherwise.
    ///
    /// - Note: Like Foundation's `JSONSerialization`, this only returns `true` for top-level
    ///   arrays and dictionaries. Scalar values (strings, numbers, null) are only valid
    ///   when nested inside containers.
    public static func isValidJSONObject(_ obj: Any) -> Bool {
        guard obj is NSArray || obj is NSDictionary else {
            return false
        }
        return isValidJSONObjectRecursive(obj)
    }

    // MARK: - Private Helpers

    private static func isValidJSONObjectRecursive(_ obj: Any) -> Bool {
        switch obj {
        case let dict as NSDictionary:
            for (key, value) in dict {
                guard key is NSString else {
                    return false
                }
                if let number = value as? NSNumber {
                    let doubleValue = number.doubleValue
                    if doubleValue.isNaN || doubleValue.isInfinite {
                        return false
                    }
                }
                if !isValidJSONObjectRecursive(value) {
                    return false
                }
            }
            return true

        case let arr as NSArray:
            for element in arr {
                if let number = element as? NSNumber {
                    let doubleValue = number.doubleValue
                    if doubleValue.isNaN || doubleValue.isInfinite {
                        return false
                    }
                }
                if !isValidJSONObjectRecursive(element) {
                    return false
                }
            }
            return true

        case is NSString, is NSNumber, is NSNull:
            return true

        default:
            return false
        }
    }

    #if !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER

        /// Serializes a `YYJSONValue` without Foundation round-tripping.
        /// - Parameters:
        ///   - value: The YYJSON value to write.
        ///   - options: `YYJSONSerialization.WritingOptions` mapped to `YYJSONWriteOptions`.
        ///     `withoutEscapingSlashes` maps to `escapeSlashes` being *absent*.
        private static func data(withJSONValue value: YYJSONValue, options: WritingOptions) throws -> Data {
            guard let rawValue = value.rawValue else {
                throw YYJSONError.invalidData("Value has no backing document")
            }

            let isTopLevelContainer = yyjson_is_obj(rawValue) || yyjson_is_arr(rawValue)
            if !isTopLevelContainer && !options.contains(.fragmentsAllowed) {
                throw YYJSONError.invalidData("Top-level JSON value must be an array or dictionary")
            }

            var writeOptions: YYJSONWriteOptions = []
            if options.contains(.prettyPrintedTwoSpaces) {
                writeOptions.insert(.prettyPrintedTwoSpaces)
            } else if options.contains(.prettyPrinted) {
                writeOptions.insert(.prettyPrinted)
            }
            if options.contains(.sortedKeys) {
                writeOptions.insert(.sortedKeys)
            }
            if !options.contains(.withoutEscapingSlashes) {
                writeOptions.insert(.escapeSlashes)
            }
            if options.contains(.escapeUnicode) {
                writeOptions.insert(.escapeUnicode)
            }
            if options.contains(.newlineAtEnd) {
                writeOptions.insert(.newlineAtEnd)
            }

            return try value.data(options: writeOptions)
        }

    #endif  // !YYJSON_DISABLE_READER && !YYJSON_DISABLE_WRITER

    #if !YYJSON_DISABLE_WRITER
        private static func foundationObjectToYYJSON(
            _ obj: Any,
            doc: UnsafeMutablePointer<yyjson_mut_doc>,
            options: WritingOptions
        ) throws -> UnsafeMutablePointer<yyjson_mut_val> {
            switch obj {
            case let str as NSString:
                return yyFromString(str as String, in: doc)

            case let num as NSNumber:
                let doubleValue = num.doubleValue
                if doubleValue.isNaN || doubleValue.isInfinite {
                    throw YYJSONError.invalidData("NaN or Infinity not allowed in JSON")
                }

                if isBoolNumber(num) {
                    return yyjson_mut_bool(doc, num.boolValue)
                }

                let objCType = num.objCType.pointee
                switch objCType {
                case 0x63, 0x73, 0x69, 0x6C, 0x71:  // 'c', 's', 'i', 'l', 'q' (signed integers)
                    return yyjson_mut_sint(doc, num.int64Value)
                case 0x43, 0x53, 0x49, 0x4C, 0x51:  // 'C', 'S', 'I', 'L', 'Q' (unsigned integers)
                    return yyjson_mut_uint(doc, num.uint64Value)
                default:
                    return yyjson_mut_real(doc, doubleValue)
                }

            case is NSNull:
                return yyjson_mut_null(doc)

            case let arr as NSArray:
                guard let jsonArr = yyjson_mut_arr(doc) else {
                    throw YYJSONError.invalidData("Failed to create array")
                }
                for element in arr {
                    let elementVal = try foundationObjectToYYJSON(element, doc: doc, options: options)
                    _ = yyjson_mut_arr_append(jsonArr, elementVal)
                }
                return jsonArr

            case let dict as NSDictionary:
                guard let jsonObj = yyjson_mut_obj(doc) else {
                    throw YYJSONError.invalidData("Failed to create object")
                }

                let keys: [Any]
                if options.contains(.sortedKeys) {
                    keys = (dict.allKeys as? [String])?.sorted() ?? dict.allKeys
                } else {
                    keys = dict.allKeys
                }

                for key in keys {
                    guard let keyString = key as? String else {
                        throw YYJSONError.invalidData("Dictionary keys must be strings")
                    }
                    guard let value = dict[key] else { continue }
                    let keyVal = yyFromString(keyString, in: doc)
                    let valueVal = try foundationObjectToYYJSON(value, doc: doc, options: options)
                    _ = yyjson_mut_obj_put(jsonObj, keyVal, valueVal)
                }
                return jsonObj

            default:
                throw YYJSONError.invalidData("Unsupported Foundation type: \(type(of: obj))")
            }
        }
    #endif  // !YYJSON_DISABLE_WRITER
}

// MARK: - YYJSONValue to Foundation Conversion

#if !YYJSON_DISABLE_READER

    extension YYJSONValue {
        fileprivate func toFoundationObject(options: YYJSONSerialization.ReadingOptions) throws -> Any {
            if isNull {
                return NSNull()
            }

            if let b = bool {
                return NSNumber(value: b)
            }

            if let n = number {
                if n.truncatingRemainder(dividingBy: 1) == 0 {
                    if n >= Double(Int64.min) && n <= Double(Int64.max) {
                        return NSNumber(value: Int64(n))
                    }
                }
                return NSNumber(value: n)
            }

            if let s = string {
                if options.contains(.mutableLeaves) {
                    return try makeMutableString(from: s)
                }
                return NSString(string: s)
            }

            if let arr = array {
                let result = NSMutableArray()

                for element in arr {
                    let foundationValue = try element.toFoundationObject(options: options)
                    result.add(foundationValue)
                }

                if options.contains(.mutableContainers) {
                    return result
                } else {
                    return NSArray(array: Array(result))
                }
            }

            if let obj = object {
                let result = NSMutableDictionary()

                for (key, value) in obj {
                    let foundationValue = try value.toFoundationObject(options: options)
                    result[key] = foundationValue
                }

                if options.contains(.mutableContainers) {
                    return result
                } else {
                    var swiftDict: [String: Any] = [:]
                    for (key, value) in result {
                        if let keyString = key as? String {
                            swiftDict[keyString] = value
                        }
                    }
                    return NSDictionary(dictionary: swiftDict)
                }
            }

            return NSNull()
        }
    }

#endif  // !YYJSON_DISABLE_READER

// MARK: - Helper Functions

#if !canImport(Darwin)
    // Cache singleton bool NSNumbers for identity comparison on Linux.
    private let nsBoolTrue = NSNumber(value: true)
    private let nsBoolFalse = NSNumber(value: false)
#endif

/// Determines whether an `NSNumber` represents a Boolean value.
///
/// On Darwin, use CoreFoundation's `CFBooleanGetTypeID()`
/// to reliably identify Boolean `NSNumber` instances.
/// On Linux (swift-corelibs-foundation),
/// `CFGetTypeID` and `CFBooleanGetTypeID` are unavailable,
/// so compare against cached singleton instances.
/// This works because Foundation reuses the same `NSNumber`
/// instances for `true` and `false`.
@inline(__always)
private func isBoolNumber(_ num: NSNumber) -> Bool {
    #if canImport(Darwin)
        return CFGetTypeID(num) == CFBooleanGetTypeID()
    #else
        return num === nsBoolTrue || num === nsBoolFalse
    #endif
}

/// Creates a mutable string from a Swift `String`.
///
/// On Darwin, initialize `NSMutableString` directly.
/// On Linux (swift-corelibs-foundation),
/// use `mutableCopy()` to ensure consistent mutability.
private func makeMutableString(from string: String) throws -> NSMutableString {
    #if canImport(Darwin)
        return NSMutableString(string: string)
    #else
        // Unlikely to fail, but prefer explicit error over force-casting.
        guard let mutable = (string as NSString).mutableCopy() as? NSMutableString else {
            throw YYJSONError.invalidData(
                "Failed to create mutable string copy on Linux"
            )
        }
        return mutable
    #endif
}
