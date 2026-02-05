import Cyyjson
import Foundation

#if !YYJSON_DISABLE_WRITER

    // MARK: - Helper Functions

    @inline(__always)
    func yyFromString(_ string: String, in doc: UnsafeMutablePointer<yyjson_mut_doc>) -> UnsafeMutablePointer<
        yyjson_mut_val
    > {
        var tmp = string
        return tmp.withUTF8 { buf in
            if let ptr = buf.baseAddress {
                return yyjson_mut_strncpy(doc, ptr, buf.count)
            }
            return yyjson_mut_strn(doc, "", 0)
        }
    }

    /// An encoder that encodes Swift types into JSON data using the yyjson library.
    public struct YYJSONEncoder {
        /// Options for writing JSON.
        public var writeOptions: YYJSONWriteOptions

        /// The strategy used when encoding dates as part of a JSON object.
        public var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate

        /// The strategy that an encoder uses to encode raw data.
        public var dataEncodingStrategy: DataEncodingStrategy = .base64

        /// A dictionary you use to customize the encoding process by providing contextual information.
        public var userInfo: [CodingUserInfoKey: Any] = [:]

        /// Creates a new encoder with default options.
        public init() {
            self.writeOptions = .default
            self.dateEncodingStrategy = .deferredToDate
            self.dataEncodingStrategy = .base64
            self.userInfo = [:]
        }

        /// Encodes a value to JSON data.
        /// - Parameter value: The value to encode.
        /// - Returns: The encoded JSON data.
        /// - Throws: `YYJSONError` if encoding fails.
        public func encode<T: Encodable>(_ value: T) throws -> Data {
            guard let doc = yyjson_mut_doc_new(nil) else {
                throw YYJSONError.invalidData("Failed to create document")
            }
            defer {
                yyjson_mut_doc_free(doc)
            }

            let encoder = _YYEncoder(
                doc: doc,
                value: nil,
                codingPath: [],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )

            try value.encode(to: encoder)

            guard let root = encoder.value else {
                throw YYJSONError.invalidData("Failed to encode root value")
            }

            if writeOptions.contains(.sortedKeys) {
                try YYJSONValue.sortObjectKeys(root)
            }

            yyjson_mut_doc_set_root(doc, root)

            let flags = writeOptions.yyjsonFlags

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

    }

    // MARK: - Encoding Strategies

    /// The strategies available for formatting dates when encoding them to JSON.
    public enum DateEncodingStrategy {
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
        case custom(@Sendable (Date, Encoder) throws -> Void)
    }

    /// The strategies for encoding raw data.
    public enum DataEncodingStrategy {
        /// The strategy that encodes data using Base 64 encoding.
        case base64

        /// The strategy that encodes data using the encoding specified by the data instance itself.
        case deferredToData

        /// The strategy that encodes data using a user-defined function.
        case custom(@Sendable (Data, Encoder) throws -> Void)
    }

    // MARK: - Internal Encoder Implementation

    /// Internal encoder implementing the Encoder protocol.
    class _YYEncoder: Encoder {
        let doc: UnsafeMutablePointer<yyjson_mut_doc>
        var value: UnsafeMutablePointer<yyjson_mut_val>?
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy

        init(
            doc: UnsafeMutablePointer<yyjson_mut_doc>,
            value: UnsafeMutablePointer<yyjson_mut_val>? = nil,
            codingPath: [CodingKey] = [],
            userInfo: [CodingUserInfoKey: Any] = [:],
            dateEncodingStrategy: DateEncodingStrategy = .deferredToDate,
            dataEncodingStrategy: DataEncodingStrategy = .base64
        ) {
            self.doc = doc
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateEncodingStrategy = dateEncodingStrategy
            self.dataEncodingStrategy = dataEncodingStrategy
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            let container = _YYKeyedEncodingContainer<Key>(
                doc: doc,
                value: value,
                encoder: self,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            return KeyedEncodingContainer(container)
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            _YYUnkeyedEncodingContainer(
                doc: doc,
                value: value,
                encoder: self,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            _YYSingleValueEncodingContainer(
                doc: doc,
                value: value,
                encoder: self,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }
    }

    // MARK: - Encoding Containers

    /// Keyed encoding container for JSON objects.
    struct _YYKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let doc: UnsafeMutablePointer<yyjson_mut_doc>
        var value: UnsafeMutablePointer<yyjson_mut_val>?
        let encoder: _YYEncoder
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy

        init(
            doc: UnsafeMutablePointer<yyjson_mut_doc>,
            value: UnsafeMutablePointer<yyjson_mut_val>?,
            encoder: _YYEncoder,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            dateEncodingStrategy: DateEncodingStrategy,
            dataEncodingStrategy: DataEncodingStrategy
        ) {
            self.doc = doc
            self.encoder = encoder
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateEncodingStrategy = dateEncodingStrategy
            self.dataEncodingStrategy = dataEncodingStrategy
            if let value = value {
                self.value = value
            } else {
                self.value = yyjson_mut_obj(doc)
                encoder.value = self.value
            }
        }

        mutating func encodeNil(forKey key: Key) throws {
            guard let obj = value else { return }
            let nullVal = yyjson_mut_null(doc)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, nullVal)
        }

        mutating func encode(_ value: Bool, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let boolVal = yyjson_mut_bool(doc, value)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, boolVal)
        }

        mutating func encode(_ value: String, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let strVal = yyFromString(value, in: doc)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, strVal)
        }

        mutating func encode(_ value: Double, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let numVal = yyjson_mut_real(doc, value)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, numVal)
        }

        mutating func encode(_ value: Float, forKey key: Key) throws {
            try encode(Double(value), forKey: key)
        }

        mutating func encode(_ value: Int, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let numVal = yyjson_mut_sint(doc, Int64(value))
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, numVal)
        }

        mutating func encode(_ value: Int8, forKey key: Key) throws {
            try encode(Int(value), forKey: key)
        }

        mutating func encode(_ value: Int16, forKey key: Key) throws {
            try encode(Int(value), forKey: key)
        }

        mutating func encode(_ value: Int32, forKey key: Key) throws {
            try encode(Int(value), forKey: key)
        }

        mutating func encode(_ value: Int64, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let numVal = yyjson_mut_sint(doc, value)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, numVal)
        }

        mutating func encode(_ value: UInt, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let numVal = yyjson_mut_uint(doc, UInt64(value))
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, numVal)
        }

        mutating func encode(_ value: UInt8, forKey key: Key) throws {
            try encode(UInt(value), forKey: key)
        }

        mutating func encode(_ value: UInt16, forKey key: Key) throws {
            try encode(UInt(value), forKey: key)
        }

        mutating func encode(_ value: UInt32, forKey key: Key) throws {
            try encode(UInt(value), forKey: key)
        }

        mutating func encode(_ value: UInt64, forKey key: Key) throws {
            guard let obj = self.value else { return }
            let numVal = yyjson_mut_uint(doc, value)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, numVal)
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            guard let obj = self.value else { return }

            if let date = value as? Date {
                let encodedValue = try encodeDate(date, codingPath: codingPath + [key])
                let keyVal = yyFromString(key.stringValue, in: doc)
                _ = yyjson_mut_obj_put(obj, keyVal, encodedValue)
                return
            }

            if let data = value as? Data {
                let encodedValue = try encodeData(data, codingPath: codingPath + [key])
                let keyVal = yyFromString(key.stringValue, in: doc)
                _ = yyjson_mut_obj_put(obj, keyVal, encodedValue)
                return
            }

            let encoder = _YYEncoder(
                doc: doc,
                value: nil,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            let encodedValue = try encodeValue(value, using: encoder)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, encodedValue)
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key)
            -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey
        {
            guard let obj = self.value else {
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath + [key],
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                return encoder.container(keyedBy: type)
            }
            let nestedObj = yyjson_mut_obj(doc)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, nestedObj)
            let encoder = _YYEncoder(
                doc: doc,
                value: nestedObj,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            return encoder.container(keyedBy: type)
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            guard let obj = self.value else {
                let nestedEncoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath + [key],
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                return nestedEncoder.unkeyedContainer()
            }
            let nestedArr = yyjson_mut_arr(doc)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, nestedArr)
            let nestedEncoder = _YYEncoder(
                doc: doc,
                value: nestedArr,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            return _YYUnkeyedEncodingContainer(
                doc: doc,
                value: nestedArr,
                encoder: nestedEncoder,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        mutating func superEncoder() -> Encoder {
            _YYEncoder(
                doc: doc,
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            guard let obj = self.value else {
                return _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath + [key],
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
            }
            let nestedObj = yyjson_mut_obj(doc)
            let keyVal = yyFromString(key.stringValue, in: doc)
            _ = yyjson_mut_obj_put(obj, keyVal, nestedObj)
            return _YYEncoder(
                doc: doc,
                value: nestedObj,
                codingPath: codingPath + [key],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        private func encodeDate(_ date: Date, codingPath: [CodingKey]) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            switch dateEncodingStrategy {
            case .deferredToDate:
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try date.encode(to: encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .iso8601:
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .secondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970)

            case .millisecondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970 * 1000.0)

            case .formatted(let formatter):
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .custom(let closure):
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(date, encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }

        private func encodeData(_ data: Data, codingPath: [CodingKey]) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            switch dataEncodingStrategy {
            case .base64:
                let string = data.base64EncodedString()
                return yyFromString(string, in: doc)

            case .deferredToData:
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try data.encode(to: encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .custom(let closure):
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(data, encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }

        private func encodeValue<T: Encodable>(_ value: T, using encoder: Encoder) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            try value.encode(to: encoder)
            if let encoder = encoder as? _YYEncoder, let val = encoder.value {
                return val
            }
            throw YYJSONError.invalidData(
                "Failed to encode value",
                path: encoder.codingPath.map { $0.stringValue }.joined(separator: ".")
            )
        }
    }

    /// Unkeyed encoding container for JSON arrays.
    struct _YYUnkeyedEncodingContainer: UnkeyedEncodingContainer {
        let doc: UnsafeMutablePointer<yyjson_mut_doc>
        var value: UnsafeMutablePointer<yyjson_mut_val>?
        let encoder: _YYEncoder
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy

        var count: Int {
            guard let arr = value else { return 0 }
            return Int(yyjson_mut_arr_size(arr))
        }

        init(
            doc: UnsafeMutablePointer<yyjson_mut_doc>,
            value: UnsafeMutablePointer<yyjson_mut_val>?,
            encoder: _YYEncoder,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            dateEncodingStrategy: DateEncodingStrategy,
            dataEncodingStrategy: DataEncodingStrategy
        ) {
            self.doc = doc
            self.encoder = encoder
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateEncodingStrategy = dateEncodingStrategy
            self.dataEncodingStrategy = dataEncodingStrategy
            if let value = value {
                self.value = value
            } else {
                self.value = yyjson_mut_arr(doc)
                encoder.value = self.value
            }
        }

        mutating func encodeNil() throws {
            guard let arr = value else { return }
            let nullVal = yyjson_mut_null(doc)
            _ = yyjson_mut_arr_append(arr, nullVal)
        }

        mutating func encode(_ value: Bool) throws {
            guard let arr = self.value else { return }
            let boolVal = yyjson_mut_bool(doc, value)
            _ = yyjson_mut_arr_append(arr, boolVal)
        }

        mutating func encode(_ value: String) throws {
            guard let arr = self.value else { return }
            let strVal = yyFromString(value, in: doc)
            _ = yyjson_mut_arr_append(arr, strVal)
        }

        mutating func encode(_ value: Double) throws {
            guard let arr = self.value else { return }
            let numVal = yyjson_mut_real(doc, value)
            _ = yyjson_mut_arr_append(arr, numVal)
        }

        mutating func encode(_ value: Float) throws {
            try encode(Double(value))
        }

        mutating func encode(_ value: Int) throws {
            guard let arr = self.value else { return }
            let numVal = yyjson_mut_sint(doc, Int64(value))
            _ = yyjson_mut_arr_append(arr, numVal)
        }

        mutating func encode(_ value: Int8) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int16) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int32) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int64) throws {
            guard let arr = self.value else { return }
            let numVal = yyjson_mut_sint(doc, value)
            _ = yyjson_mut_arr_append(arr, numVal)
        }

        mutating func encode(_ value: UInt) throws {
            guard let arr = self.value else { return }
            let numVal = yyjson_mut_uint(doc, UInt64(value))
            _ = yyjson_mut_arr_append(arr, numVal)
        }

        mutating func encode(_ value: UInt8) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt16) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt32) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt64) throws {
            guard let arr = self.value else { return }
            let numVal = yyjson_mut_uint(doc, value)
            _ = yyjson_mut_arr_append(arr, numVal)
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            guard let arr = self.value else { return }

            if let date = value as? Date {
                let encodedValue = try encodeDate(date, codingPath: codingPath + [AnyCodingKey(index: count)])
                _ = yyjson_mut_arr_append(arr, encodedValue)
                return
            }

            if let data = value as? Data {
                let encodedValue = try encodeData(data, codingPath: codingPath + [AnyCodingKey(index: count)])
                _ = yyjson_mut_arr_append(arr, encodedValue)
                return
            }

            let encoder = _YYEncoder(
                doc: doc,
                value: nil,
                codingPath: codingPath + [AnyCodingKey(index: count)],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            let encodedValue = try encodeValue(value, using: encoder)
            _ = yyjson_mut_arr_append(arr, encodedValue)
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) -> KeyedEncodingContainer<
            NestedKey
        > where NestedKey: CodingKey {
            let nestedObj = yyjson_mut_obj(doc)
            if let arr = self.value {
                _ = yyjson_mut_arr_append(arr, nestedObj)
            }
            let encoder = _YYEncoder(
                doc: doc,
                value: nestedObj,
                codingPath: codingPath + [AnyCodingKey(index: count)],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            return encoder.container(keyedBy: type)
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let nestedArr = yyjson_mut_arr(doc)
            if let arr = self.value {
                _ = yyjson_mut_arr_append(arr, nestedArr)
            }
            let nestedEncoder = _YYEncoder(
                doc: doc,
                value: nestedArr,
                codingPath: codingPath + [AnyCodingKey(index: count)],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            return _YYUnkeyedEncodingContainer(
                doc: doc,
                value: nestedArr,
                encoder: nestedEncoder,
                codingPath: codingPath + [AnyCodingKey(index: count)],
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        mutating func superEncoder() -> Encoder {
            _YYEncoder(
                doc: doc,
                value: value,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
        }

        private func encodeDate(_ date: Date, codingPath: [CodingKey]) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            switch dateEncodingStrategy {
            case .deferredToDate:
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try date.encode(to: encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .iso8601:
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .secondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970)

            case .millisecondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970 * 1000.0)

            case .formatted(let formatter):
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .custom(let closure):
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(date, encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }

        private func encodeData(_ data: Data, codingPath: [CodingKey]) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            switch dataEncodingStrategy {
            case .base64:
                let string = data.base64EncodedString()
                return yyFromString(string, in: doc)

            case .deferredToData:
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try data.encode(to: encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .custom(let closure):
                let encoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(data, encoder)
                guard let val = encoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }

        private func encodeValue<T: Encodable>(_ value: T, using encoder: Encoder) throws
            -> UnsafeMutablePointer<yyjson_mut_val>
        {
            try value.encode(to: encoder)
            if let encoder = encoder as? _YYEncoder, let val = encoder.value {
                return val
            }
            throw YYJSONError.invalidData(
                "Failed to encode value",
                path: encoder.codingPath.map { $0.stringValue }.joined(separator: ".")
            )
        }
    }

    /// Single value encoding container.
    struct _YYSingleValueEncodingContainer: SingleValueEncodingContainer {
        let doc: UnsafeMutablePointer<yyjson_mut_doc>
        var value: UnsafeMutablePointer<yyjson_mut_val>?
        let encoder: _YYEncoder
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy

        init(
            doc: UnsafeMutablePointer<yyjson_mut_doc>,
            value: UnsafeMutablePointer<yyjson_mut_val>?,
            encoder: _YYEncoder,
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            dateEncodingStrategy: DateEncodingStrategy,
            dataEncodingStrategy: DataEncodingStrategy
        ) {
            self.doc = doc
            self.encoder = encoder
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.dateEncodingStrategy = dateEncodingStrategy
            self.dataEncodingStrategy = dataEncodingStrategy
        }

        mutating func encodeNil() throws {
            value = yyjson_mut_null(doc)
            encoder.value = value
        }

        mutating func encode(_ value: Bool) throws {
            self.value = yyjson_mut_bool(doc, value)
            encoder.value = self.value
        }

        mutating func encode(_ value: String) throws {
            self.value = yyFromString(value, in: doc)
            encoder.value = self.value
        }

        mutating func encode(_ value: Double) throws {
            self.value = yyjson_mut_real(doc, value)
            encoder.value = self.value
        }

        mutating func encode(_ value: Float) throws {
            try encode(Double(value))
        }

        mutating func encode(_ value: Int) throws {
            self.value = yyjson_mut_sint(doc, Int64(value))
            encoder.value = self.value
        }

        mutating func encode(_ value: Int8) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int16) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int32) throws {
            try encode(Int(value))
        }

        mutating func encode(_ value: Int64) throws {
            self.value = yyjson_mut_sint(doc, value)
            encoder.value = self.value
        }

        mutating func encode(_ value: UInt) throws {
            self.value = yyjson_mut_uint(doc, UInt64(value))
            encoder.value = self.value
        }

        mutating func encode(_ value: UInt8) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt16) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt32) throws {
            try encode(UInt(value))
        }

        mutating func encode(_ value: UInt64) throws {
            self.value = yyjson_mut_uint(doc, value)
            encoder.value = self.value
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            if let date = value as? Date {
                self.value = try encodeDate(date)
                encoder.value = self.value
                return
            }

            if let data = value as? Data {
                self.value = try encodeData(data)
                encoder.value = self.value
                return
            }

            let nestedEncoder = _YYEncoder(
                doc: doc,
                value: nil,
                codingPath: codingPath,
                userInfo: userInfo,
                dateEncodingStrategy: dateEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy
            )
            try value.encode(to: nestedEncoder)
            self.value = nestedEncoder.value
            encoder.value = self.value
        }

        private func encodeDate(_ date: Date) throws -> UnsafeMutablePointer<yyjson_mut_val> {
            switch dateEncodingStrategy {
            case .deferredToDate:
                let nestedEncoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try date.encode(to: nestedEncoder)
                guard let val = nestedEncoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .iso8601:
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .secondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970)

            case .millisecondsSince1970:
                return yyjson_mut_real(doc, date.timeIntervalSince1970 * 1000.0)

            case .formatted(let formatter):
                let string = formatter.string(from: date)
                return yyFromString(string, in: doc)

            case .custom(let closure):
                let nestedEncoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(date, nestedEncoder)
                guard let val = nestedEncoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode date with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }

        private func encodeData(_ data: Data) throws -> UnsafeMutablePointer<yyjson_mut_val> {
            switch dataEncodingStrategy {
            case .base64:
                let string = data.base64EncodedString()
                return yyFromString(string, in: doc)

            case .deferredToData:
                let nestedEncoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try data.encode(to: nestedEncoder)
                guard let val = nestedEncoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val

            case .custom(let closure):
                let nestedEncoder = _YYEncoder(
                    doc: doc,
                    value: nil,
                    codingPath: codingPath,
                    userInfo: userInfo,
                    dateEncodingStrategy: dateEncodingStrategy,
                    dataEncodingStrategy: dataEncodingStrategy
                )
                try closure(data, nestedEncoder)
                guard let val = nestedEncoder.value else {
                    throw YYJSONError.invalidData(
                        "Failed to encode data with custom strategy",
                        path: codingPath.map { $0.stringValue }.joined(separator: ".")
                    )
                }
                return val
            }
        }
    }

#endif  // !YYJSON_DISABLE_WRITER
