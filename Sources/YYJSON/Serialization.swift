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

        /// Specifies that reading serialized JSON data supports the JSON5 syntax.
        public static let json5Allowed = ReadingOptions(rawValue: 1 << 3)

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

        /// Specifies that the parser should allow top-level objects that aren't arrays or dictionaries.
        public static let fragmentsAllowed = WritingOptions(rawValue: 1 << 0)

        /// Specifies that the output uses white space and indentation to make the resulting data more readable.
        public static let prettyPrinted = WritingOptions(rawValue: 1 << 1)

        /// Specifies that the output sorts keys in lexicographic order.
        public static let sortedKeys = WritingOptions(rawValue: 1 << 2)

        /// Specifies that the output doesn't prefix slash characters with escape characters.
        public static let withoutEscapingSlashes = WritingOptions(rawValue: 1 << 3)
    }

    /// Returns a Foundation object from given JSON data.
    /// - Parameters:
    ///   - data: The JSON data to parse.
    ///   - options: Options for reading the JSON.
    /// - Returns: A Foundation object (NSArray, NSDictionary, NSString, NSNumber, or NSNull).
    /// - Throws: `YYJSONError` if parsing fails.
    public static func jsonObject(with data: Data, options: ReadingOptions = []) throws -> Any {
        var readOptions: YYJSONReadOptions = .default
        if options.contains(.json5Allowed) {
            readOptions.insert(.json5)
        }

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

    /// Returns JSON data from a Foundation object.
    /// - Parameters:
    ///   - obj: The Foundation object to convert (must be NSArray, NSDictionary, or a scalar with `.fragmentsAllowed`).
    ///   - options: Options for writing the JSON.
    /// - Returns: The JSON data.
    /// - Throws: `YYJSONError` if conversion fails.
    public static func data(withJSONObject obj: Any, options: WritingOptions = []) throws -> Data {
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
        if options.contains(.prettyPrinted) {
            flags |= YYJSON_WRITE_PRETTY
        }
        if !options.contains(.withoutEscapingSlashes) {
            flags |= YYJSON_WRITE_ESCAPE_SLASHES
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

    private static func foundationObjectToYYJSON(
        _ obj: Any,
        doc: UnsafeMutablePointer<yyjson_mut_doc>,
        options: WritingOptions
    ) throws -> UnsafeMutablePointer<yyjson_mut_val> {
        switch obj {
        case let str as NSString:
            return yyjson_mut_strcpy(doc, str as String)

        case let num as NSNumber:
            let doubleValue = num.doubleValue
            if doubleValue.isNaN || doubleValue.isInfinite {
                throw YYJSONError.invalidData("NaN or Infinity not allowed in JSON")
            }

            if CFGetTypeID(num) == CFBooleanGetTypeID() {
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
                let keyVal = yyjson_mut_strcpy(doc, keyString)
                let valueVal = try foundationObjectToYYJSON(value, doc: doc, options: options)
                _ = yyjson_mut_obj_put(jsonObj, keyVal, valueVal)
            }
            return jsonObj

        default:
            throw YYJSONError.invalidData("Unsupported Foundation type: \(type(of: obj))")
        }
    }
}

// MARK: - YYJSONValue to Foundation Conversion

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
                return NSMutableString(string: s)
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
