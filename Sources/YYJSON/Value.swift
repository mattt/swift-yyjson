import Cyyjson
import Foundation

#if !YYJSON_DISABLE_READER

    // MARK: - Document (Internal)

    /// A safe wrapper around a yyjson document.
    ///
    /// The document is immutable after creation and safe for concurrent reads.
    internal final class YYDocument: @unchecked Sendable {
        let doc: UnsafeMutablePointer<yyjson_doc>

        /// Retained data buffer (used when parsing consumes the input).
        private var retainedData: Data?

        /// Creates a document by parsing JSON data.
        ///
        /// - Parameters:
        ///   - data: The JSON data to parse.
        ///   - options: Options for reading the JSON.
        /// - Throws: `YYJSONError` if parsing fails.
        init(data: Data, options: YYJSONReadOptions = .default) throws {
            var error = yyjson_read_err()
            var flags = options.yyjsonFlags
            // Mask out YYJSON_READ_INSITU to prevent use-after-free issues.
            // In-place parsing must use the dedicated consuming initializer.
            flags &= ~yyjson_read_flag(YYJSON_READ_INSITU)

            self.retainedData = nil

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

        /// Creates a document by consuming mutable data.
        ///
        /// This initializer takes ownership of the provided data
        /// and parses directly within the buffer,
        /// avoiding any data copies.
        ///
        /// - Parameters:
        ///   - consuming: The data to parse.
        ///     This data will be consumed and must not be used after this call.
        ///   - options: Options for reading the JSON.
        /// - Throws: `YYJSONError` if parsing fails.
        init(consuming data: inout Data, options: YYJSONReadOptions = .default) throws {
            var error = yyjson_read_err()
            var flags = options.yyjsonFlags
            flags |= YYJSON_READ_INSITU

            if data.isEmpty {
                throw YYJSONError.invalidJSON("Empty content")
            }

            let paddingSize = Int(YYJSON_PADDING_SIZE)
            let originalCount = data.count

            data.reserveCapacity(originalCount + paddingSize)
            data.append(contentsOf: repeatElement(0 as UInt8, count: paddingSize))

            self.retainedData = data

            let result = self.retainedData!.withUnsafeMutableBytes { bytes -> UnsafeMutablePointer<yyjson_doc>? in
                let ptr = bytes.baseAddress?.assumingMemoryBound(to: CChar.self)
                return yyjson_read_opts(ptr, originalCount, flags, nil, &error)
            }

            guard let doc = result else {
                throw YYJSONError(parsing: error)
            }
            self.doc = doc
        }

        deinit {
            yyjson_doc_free(doc)
        }

        var root: UnsafeMutablePointer<yyjson_val>? {
            yyjson_doc_get_root(doc)
        }
    }

    // MARK: - Document (Public)

    /// A parsed JSON document that owns the underlying memory.
    ///
    /// `YYJSONDocument` is a move-only type
    /// that represents ownership of a parsed JSON document.
    /// It cannot be copied, only moved,
    /// which makes resource ownership explicit at compile time.
    ///
    /// Use `YYJSONDocument` when you want explicit control
    /// over the lifetime of the parsed JSON data.
    /// For simpler use cases,
    /// use ``YYJSONValue/init(data:options:)`` directly,
    /// which manages the document internally.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let document = try YYJSONDocument(data: jsonData)
    /// if let root = document.root {
    ///     print(root["name"]?.string ?? "unknown")
    /// }
    /// ```
    ///
    /// For highest performance with large documents,
    /// use in-place parsing:
    ///
    /// ```swift
    /// var data = try Data(contentsOf: fileURL)
    /// let document = try YYJSONDocument(parsingInPlace: &data)
    /// // `data` is now consumed and should not be used
    /// ```
    public struct YYJSONDocument: ~Copyable, @unchecked Sendable {
        internal let _document: YYDocument

        /// Creates a document by parsing JSON data.
        ///
        /// - Parameters:
        ///   - data: The JSON data to parse.
        ///   - options: Options for reading the JSON.
        /// - Throws: `YYJSONError` if parsing fails.
        public init(data: Data, options: YYJSONReadOptions = .default) throws {
            self._document = try YYDocument(data: data, options: options)
        }

        /// Creates a document by parsing a JSON string.
        ///
        /// - Parameters:
        ///   - string: The JSON string to parse.
        ///   - options: Options for reading the JSON.
        /// - Throws: `YYJSONError` if parsing fails.
        public init(string: String, options: YYJSONReadOptions = .default) throws {
            guard let data = string.data(using: .utf8) else {
                throw YYJSONError.invalidJSON("Invalid UTF-8 string")
            }
            self._document = try YYDocument(data: data, options: options)
        }

        /// Creates a document by parsing JSON data in place,
        /// consuming the provided data.
        ///
        /// This initializer provides the highest performance parsing
        /// by avoiding a copy of the input data.
        /// The `data` parameter is consumed during parsing
        /// and retained by the document for its lifetime.
        ///
        /// - Parameters:
        ///   - parsingInPlace: The JSON data to parse.
        ///     This data will be **consumed** by this initializer
        ///     and is no longer valid after the call.
        ///   - options: Options for reading the JSON.
        /// - Throws: `YYJSONError` if parsing fails.
        public init(parsingInPlace data: inout Data, options: YYJSONReadOptions = .default) throws {
            self._document = try YYDocument(consuming: &data, options: options)
        }

        /// The root value of the parsed JSON document.
        ///
        /// Returns `nil` if the document has no root value.
        public var root: YYJSONValue? {
            guard let root = _document.root else {
                return nil
            }
            return YYJSONValue(value: root, document: _document)
        }

        /// The root value as an object, or `nil` if the root is not an object
        /// or if the document has no root value.
        public var rootObject: YYJSONObject? {
            root?.object
        }

        /// The root value as an array, or `nil` if the root is not an array
        /// or if the document has no root value.
        public var rootArray: YYJSONArray? {
            root?.array
        }
    }

    // MARK: - Value

    /// A JSON value that can represent any JSON type.
    ///
    /// `YYJSONValue` is safe for concurrent reads across multiple threads and tasks
    /// because the underlying yyjson document is immutable after parsing.
    ///
    /// String values are lazily converted to Swift `String`
    /// when accessed via the `.string` property.
    /// For zero-allocation access in performance-critical code,
    /// use `.cString` to get the raw C string pointer.
    public struct YYJSONValue: @unchecked Sendable {
        /// Internal storage for the value kind.
        /// Strings are stored as pointers and converted lazily on access.
        private enum Kind {
            case null
            case bool(Bool)
            case number(Double)
            case stringPtr(UnsafePointer<CChar>)
            case object(UnsafeMutablePointer<yyjson_val>)
            case array(UnsafeMutablePointer<yyjson_val>)
        }

        private let kind: Kind

        /// The document that owns this value (for lifetime management).
        internal let document: YYDocument

        /// Initializes from a yyjson value pointer.
        ///
        /// - Parameters:
        ///   - value: The yyjson value pointer, or `nil` for null.
        ///   - document: The document that owns this value (for lifetime management).
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
                    self.kind = .stringPtr(str)
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

        /// Accesses a value in an object by key.
        ///
        /// - Parameter key: The key to look up.
        /// - Returns: The value at the key,
        ///   or `nil` if not found or not an object.
        public subscript(key: String) -> YYJSONValue? {
            guard case .object(let ptr) = kind else { return nil }
            guard let val = yyObjGet(ptr, key: key) else { return nil }
            return YYJSONValue(value: val, document: document)
        }

        /// Accesses a value in an array by index.
        ///
        /// - Parameter index: The index to access.
        /// - Returns: The value at the index,
        ///   or `nil` if out of bounds or not an array.
        public subscript(index: Int) -> YYJSONValue? {
            guard case .array(let ptr) = kind else { return nil }
            guard let val = yyjson_arr_get(ptr, index) else { return nil }
            return YYJSONValue(value: val, document: document)
        }

        /// Get the string value, or nil if not a string.
        ///
        /// This property converts the underlying C string to a Swift `String`,
        /// which involves a copy.
        /// For zero-allocation access in hot paths, use `.cString` instead.
        public var string: String? {
            if case .stringPtr(let ptr) = kind {
                return String(cString: ptr)
            }
            return nil
        }

        /// Get the raw C string pointer, or nil if not a string.
        ///
        /// This provides zero-allocation access to the string data. The pointer
        /// is valid for the lifetime of the `YYJSONValue` and its underlying document.
        ///
        /// - Warning: Do not use this pointer after the `YYJSONValue`
        ///            or its originating document has been deallocated.
        public var cString: UnsafePointer<CChar>? {
            if case .stringPtr(let ptr) = kind { return ptr }
            return nil
        }

        /// The number value, or `nil` if not a number.
        public var number: Double? {
            if case .number(let num) = kind { return num }
            return nil
        }

        /// The Boolean value, or `nil` if not a Boolean.
        public var bool: Bool? {
            if case .bool(let b) = kind { return b }
            return nil
        }

        /// The object value, or `nil` if not an object.
        public var object: YYJSONObject? {
            guard case .object(let ptr) = kind else { return nil }
            return YYJSONObject(value: ptr, document: document)
        }

        /// The array value, or `nil` if not an array.
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
            case .stringPtr(let ptr):
                return "\"\(String(cString: ptr))\""
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
    /// `YYJSONObject` is safe for concurrent reads across multiple threads and tasks
    /// because the underlying yyjson document is immutable after parsing.
    public struct YYJSONObject: @unchecked Sendable {
        internal let value: UnsafeMutablePointer<yyjson_val>
        internal let document: YYDocument

        internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
            self.value = value
            self.document = document
        }

        /// Accesses a value by key.
        ///
        /// - Parameter key: The key to look up.
        /// - Returns: The value at the key, or `nil` if not found.
        public subscript(key: String) -> YYJSONValue? {
            guard let val = yyObjGet(value, key: key) else {
                return nil
            }
            return YYJSONValue(value: val, document: document)
        }

        /// Returns a Boolean value indicating whether the object contains the given key.
        ///
        /// - Parameter key: The key to check.
        /// - Returns: `true` if the key exists; otherwise, `false`.
        public func contains(_ key: String) -> Bool {
            yyObjGet(value, key: key) != nil
        }

        /// All keys in the object.
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
    /// `YYJSONArray` is safe for concurrent reads across multiple threads and tasks
    /// because the underlying yyjson document is immutable after parsing.
    public struct YYJSONArray: @unchecked Sendable {
        internal let value: UnsafeMutablePointer<yyjson_val>
        internal let document: YYDocument

        internal init(value: UnsafeMutablePointer<yyjson_val>, document: YYDocument) {
            self.value = value
            self.document = document
        }

        /// Accesses a value by index.
        ///
        /// - Parameter index: The index to access.
        /// - Returns: The value at the index, or `nil` if out of bounds.
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
        /// Creates a JSON value by parsing JSON data.
        ///
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

        /// Creates a JSON value by parsing a JSON string.
        ///
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

        /// Parses JSON data in place, consuming the provided data.
        ///
        /// This method provides the highest performance parsing by:
        /// 1. Avoiding a copy of the input data
        ///    (yyjson parses directly in the buffer)
        /// 2. Lazily converting strings to Swift `String` only when accessed
        ///
        /// The `data` parameter is consumed during parsing
        /// and retained by the returned `YYJSONValue` for its lifetime.
        /// After calling this method,
        /// the original binding is no longer valid.
        ///
        /// - Parameters:
        ///   - data: The JSON data to parse.
        ///     This data will be **consumed** by this method
        ///     and is no longer valid after the call.
        ///   - options: Options for reading the JSON.
        /// - Returns: The parsed JSON value.
        /// - Throws: `YYJSONError` if parsing fails.
        ///
        /// ## Example
        ///
        /// ```swift
        /// var data = try Data(contentsOf: fileURL)
        /// let json = try YYJSONValue.parseInPlace(consuming: &data)
        /// // `data` is now consumed — compiler prevents further use
        /// ```
        ///
        /// - Note: For most use cases,
        ///   the standard ``init(data:options:)`` initializer is sufficient.
        ///   Use this method when parsing performance is critical
        ///   and you can accept the ownership semantics.
        public static func parseInPlace(consuming data: inout Data, options: YYJSONReadOptions = .default) throws
            -> YYJSONValue
        {
            let document = try YYDocument(consuming: &data, options: options)
            guard let root = document.root else {
                throw YYJSONError.invalidData("Document has no root value")
            }
            return YYJSONValue(value: root, document: document)
        }
    }

#endif  // !YYJSON_DISABLE_READER
