import Cyyjson

#if !YYJSON_DISABLE_WRITER

    /// Recursively sort object keys in-place using UTF-8 lexicographical comparison (strcmp).
    /// This matches Apple's JSONEncoder behavior for typical keys, but embedded null bytes
    /// may compare differently due to C string semantics.
    ///
    /// - Note: Uses direct C string comparison via `strcmp` for optimal performance,
    ///   avoiding Swift String allocations during sorting.
    func sortObjectKeys(_ val: UnsafeMutablePointer<yyjson_mut_val>) throws {
        typealias MutVal = UnsafeMutablePointer<yyjson_mut_val>

        if yyjson_mut_is_obj(val) {
            var pairs: [(keyVal: MutVal, val: MutVal, keyStr: UnsafePointer<CChar>)] = []
            pairs.reserveCapacity(Int(yyjson_mut_obj_size(val)))

            var iter = yyjson_mut_obj_iter()
            guard yyjson_mut_obj_iter_init(val, &iter) else {
                throw YYJSONError.invalidData("Failed to initialize object iterator during key sorting")
            }

            while let keyPtr = yyjson_mut_obj_iter_next(&iter) {
                guard let valPtr = yyjson_mut_obj_iter_get_val(keyPtr) else {
                    throw YYJSONError.invalidData("Object key has no associated value during key sorting")
                }
                guard let keyStr = yyjson_mut_get_str(keyPtr) else {
                    throw YYJSONError.invalidData("Object key is not a string during key sorting")
                }
                pairs.append((keyPtr, valPtr, keyStr))
            }

            pairs.sort { pair1, pair2 in
                return strcmp(pair1.keyStr, pair2.keyStr) < 0
            }

            guard yyjson_mut_obj_clear(val) else {
                throw YYJSONError.invalidData("Failed to clear object during key sorting")
            }

            for pair in pairs {
                try sortObjectKeys(pair.val)
                guard yyjson_mut_obj_add(val, pair.keyVal, pair.val) else {
                    throw YYJSONError.invalidData("Failed to add key back to object during key sorting")
                }
            }
        } else if yyjson_mut_is_arr(val) {
            var iter = yyjson_mut_arr_iter()
            guard yyjson_mut_arr_iter_init(val, &iter) else {
                throw YYJSONError.invalidData("Failed to initialize array iterator during key sorting")
            }
            while let elem = yyjson_mut_arr_iter_next(&iter) {
                try sortObjectKeys(elem)
            }
        }
    }
#endif  // !YYJSON_DISABLE_WRITER
