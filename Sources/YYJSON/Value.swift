import Cyyjson
import Foundation

// MARK: - Document (Internal)

/// A safe wrapper around a yyjson document.
/// The document is immutable after creation and safe for concurrent reads.
internal final class YYDocument: @unchecked Sendable {
    let doc: UnsafeMutablePointer<yyjson_doc>

    /// Storage for in-situ parsing. Must remain alive for the lifetime of `doc`.
    private var storage: Data?

    init(data: Data, options: YYJSONReadOptions = .default) throws {
        var error = yyjson_read_err()
        let flags = options.yyjsonFlags

        if options.contains(.inSitu) {
            // In-situ mode: we must keep the buffer alive and pass a mutable pointer.
            // Create a copy with padding for yyjson's requirements.
            let paddingSize = Int(YYJSON_PADDING_SIZE)
            var mutableData = Data(data)
            mutableData.append(contentsOf: repeatElement(0 as UInt8, count: paddingSize))
            self.storage = mutableData

            let dataCount = data.count
            let result = self.storage!.withUnsafeMutableBytes { bytes -> UnsafeMutablePointer<yyjson_doc>? in
                let ptr = bytes.baseAddress?.assumingMemoryBound(to: CChar.self)
                return yyjson_read_opts(ptr, dataCount, flags, nil, &error)
            }

            guard let doc = result else {
                throw YYJSONError(parsing: error)
            }
            self.doc = doc
        } else {
            // Standard mode: yyjson copies all data internally, no need to retain.
            self.storage = nil

            if data.isEmpty {
                throw YYJSONError.invalidJSON("Empty content")
            }

            let result = data.withUnsafeBytes { bytes -> UnsafeMutablePointer<yyjson_doc>? in
                guard let baseAddress = bytes.baseAddress else { return nil }
                let ptr = UnsafeMutablePointer(mutating: baseAddress.assumingMemoryBound(to: CChar.self))
                return yyjson_read_opts(ptr, data.count, flags, nil, &error)
            }

            guard let doc = result else {
                throw YYJSONError(parsing: error)
            }
            self.doc = doc
        }
    }

    deinit {
        yyjson_doc_free(doc)
    }

    var root: UnsafeMutablePointer<yyjson_val>? {
        yyjson_doc_get_root(doc)
    }
}

// MARK: - Value

/// A JSON value that can represent any JSON type.
///
/// `YYJSONValue` is safe for concurrent reads across multiple threads/tasks
/// because the underlying yyjson document is immutable after parsing.
public struct YYJSONValue: @unchecked Sendable {
    /// Internal storage for the value kind.
    private enum Kind {
        case null
        case bool(Bool)
        case number(Double)
        case string(String)
        case object(UnsafeMutablePointer<yyjson_val>)
        case array(UnsafeMutablePointer<yyjson_val>)
    }

    private let kind: Kind

    /// The document that owns this value (for lifetime management).
    internal let document: YYDocument

    /// Initialize from a yyjson value pointer.
    /// - Parameter value: The yyjson value pointer, or nil for null.
    /// - Parameter document: The document that owns this value (for lifetime management).
    init(value: UnsafeMutablePointer<yyjson_val>?, document: YYDocument) {
        self.document = document

        guard let val = value else {
            self.kind = .null
            return
        }

        switch yyjson_get_type(val) {
        case YYJSON_TYPE_NULL:
            self.kind = .null
        case YYJSON_TYPE_BOOL:
            self.kind = .bool(yyjson_get_bool(val))
        case YYJSON_TYPE_NUM:
            let num: Double
            if yyjson_is_int(val) {
                num = Double(yyjson_get_sint(val))
            } else {
                num = yyjson_get_real(val)
            }
            self.kind = .number(num)
        case YYJSON_TYPE_STR:
            if let str = yyjson_get_str(val) {
                self.kind = .string(String(cString: str))
            } else {
                self.kind = .null
            }
        case YYJSON_TYPE_ARR:
            self.kind = .array(val)
        case YYJSON_TYPE_OBJ:
            self.kind = .object(val)
        default:
            self.kind = .null
        }
    }

    /// Whether this value is null.
    public var isNull: Bool {
        if case .null = kind { return true }
        return false
    }

    /// Access a value in an object by key.
    /// - Parameter key: The key to look up.
    /// - Returns: The value at the key, or nil if not found or not an object.
    public subscript(key: String) -> YYJSONValue? {
        guard case .object(let ptr) = kind else { return nil }
        guard let val = yyjson_obj_get(ptr, key) else { return nil }
        return YYJSONValue(value: val, document: document)
    }

    /// Access a value in an array by index.
    /// - Parameter index: The index to access.
    /// - Returns: The value at the index, or nil if out of bounds or not an array.
    public subscript(index: Int) -> YYJSONValue? {
        guard case .array(let ptr) = kind else { return nil }
        guard let val = yyjson_arr_get(ptr, index) else { return nil }
        return YYJSONValue(value: val, document: document)
    }

    /// Get the string value, or nil if not a string.
    public var string: String? {
        if case .string(let str) = kind { return str }
        return nil
    }

    /// Get the number value, or nil if not a number.
    public var number: Double? {
        if case .number(let num) = kind { return num }
        return nil
    }

    /// Get the bool value, or nil if not a bool.
    public var bool: Bool? {
        if case .bool(let b) = kind { return b }
        return nil
    }

    /// Get the object value, or nil if not an object.
    public var object: YYJSONObject? {
        guard case .object(let ptr) = kind else { return nil }
        return YYJSONObject(value: ptr, document: document)
    }

    /// Get the array value, or nil if not an array.
    public var array: YYJSONArray? {
        guard case .array(let ptr) = kind else { return nil }
        return YYJSONArray(value: ptr, document: document)
    }
}

extension YYJSONValue: CustomStringConvertible {
    public var description: String {
        switch kind {
        case .null:
            return "null"
        case .bool(let b):
            return b ? "true" : "false"
        case .number(let n):
            return String(n)
        case .string(let s):
            return "\"\(s)\""
        case .object(let ptr):
            return YYJSONObject(value: ptr, document: document).description
        case .array(let ptr):
            return YYJSONArray(value: ptr, document: document).description
        }
    }
}

// MARK: - JSON Object

/// A JSON object providing key-value access.
///
/// `YYJSONObject` is safe for concurrent reads across multiple threads/tasks
/// because the underlying yyjson document is immutable after parsing.
public struct YYJSONObject: @unchecked Sendable {
    internal let value: UnsafeMutablePointer<yyjson_val>
    internal let document: YYDocument

    internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
        self.value = value
        self.document = document
    }

    /// Access a value by key.
    /// - Parameter key: The key to look up.
    /// - Returns: The value at the key, or nil if not found.
    public subscript(key: String) -> YYJSONValue? {
        guard let val = yyjson_obj_get(value, key) else {
            return nil
        }
        return YYJSONValue(value: val, document: document)
    }

    /// Check if the object contains a key.
    /// - Parameter key: The key to check.
    /// - Returns: True if the key exists.
    public func contains(_ key: String) -> Bool {
        yyjson_obj_get(value, key) != nil
    }

    /// Get all keys in the object.
    public var keys: [String] {
        var keys: [String] = []
        var iter = yyjson_obj_iter_with(value)
        while let keyVal = yyjson_obj_iter_next(&iter) {
            if let keyStr = yyjson_get_str(keyVal) {
                keys.append(String(cString: keyStr))
            }
        }
        return keys
    }
}

extension YYJSONObject: Sequence {
    public func makeIterator() -> YYJSONObjectIterator {
        YYJSONObjectIterator(value: value, document: document)
    }
}

/// Iterator for JSON object key-value pairs.
public struct YYJSONObjectIterator: IteratorProtocol {
    private let value: UnsafeMutablePointer<yyjson_val>
    private let document: YYDocument
    private var iterator: yyjson_obj_iter

    internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
        self.value = value
        self.document = document
        self.iterator = yyjson_obj_iter_with(value)
    }

    public mutating func next() -> (key: String, value: YYJSONValue)? {
        guard let keyVal = yyjson_obj_iter_next(&iterator) else {
            return nil
        }
        guard let keyStr = yyjson_get_str(keyVal) else {
            return nil
        }
        let val = yyjson_obj_iter_get_val(keyVal)
        return (
            key: String(cString: keyStr),
            value: YYJSONValue(value: val, document: document)
        )
    }
}

extension YYJSONObject: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        for (key, value) in self {
            parts.append("\"\(key)\": \(value.description)")
        }
        return "{\(parts.joined(separator: ", "))}"
    }
}

// MARK: - JSON Array

/// A JSON array providing indexed access.
///
/// `YYJSONArray` is safe for concurrent reads across multiple threads/tasks
/// because the underlying yyjson document is immutable after parsing.
public struct YYJSONArray: @unchecked Sendable {
    internal let value: UnsafeMutablePointer<yyjson_val>
    internal let document: YYDocument

    internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
        self.value = value
        self.document = document
    }

    /// Access a value by index.
    /// - Parameter index: The index to access.
    /// - Returns: The value at the index, or nil if out of bounds.
    public subscript(index: Int) -> YYJSONValue? {
        guard let val = yyjson_arr_get(value, index) else {
            return nil
        }
        return YYJSONValue(value: val, document: document)
    }

    /// The number of elements in the array.
    public var count: Int {
        Int(yyjson_get_len(value))
    }
}

extension YYJSONArray: Sequence {
    public func makeIterator() -> YYJSONArrayIterator {
        YYJSONArrayIterator(value: value, document: document)
    }
}

/// Iterator for JSON array elements.
public struct YYJSONArrayIterator: IteratorProtocol {
    private let value: UnsafeMutablePointer<yyjson_val>
    private let document: YYDocument
    private var iterator: yyjson_arr_iter

    internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
        self.value = value
        self.document = document
        self.iterator = yyjson_arr_iter_with(value)
    }

    public mutating func next() -> YYJSONValue? {
        guard let val = yyjson_arr_iter_next(&iterator) else {
            return nil
        }
        return YYJSONValue(value: val, document: document)
    }
}

extension YYJSONArray: CustomStringConvertible {
    public var description: String {
        let elements = self.map { $0.description }
        return "[\(elements.joined(separator: ", "))]"
    }
}

// MARK: - Parsing

extension YYJSONValue {
    /// Create a JSON value by parsing JSON data.
    /// - Parameters:
    ///   - data: The JSON data to parse.
    ///   - options: Options for reading the JSON.
    /// - Throws: `YYJSONError` if parsing fails.
    public init(data: Data, options: YYJSONReadOptions = .default) throws {
        let document = try YYDocument(data: data, options: options)
        guard let root = document.root else {
            throw YYJSONError.invalidData("Document has no root value")
        }
        self.init(value: root, document: document)
    }

    /// Create a JSON value by parsing a JSON string.
    /// - Parameters:
    ///   - string: The JSON string to parse.
    ///   - options: Options for reading the JSON.
    /// - Throws: `YYJSONError` if parsing fails.
    public init(string: String, options: YYJSONReadOptions = .default) throws {
        guard let data = string.data(using: .utf8) else {
            throw YYJSONError.invalidJSON("Invalid UTF-8 string")
        }
        try self.init(data: data, options: options)
    }
}
