# YYJSON

A fast JSON library for Swift,
powered by [yyjson](https://github.com/ibireme/yyjson).

YYJSON provides API-compatible alternatives for
`JSONEncoder`, `JSONDecoder`, and `JSONSerialization`.
It supports configurable compile-time options via
[Swift package traits](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/packagetraits/)
for further optimization.

## Requirements

- Swift 6.1+ / Xcode 16+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+ / visionOS 1+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/mattt/swift-yyjson.git", from: "0.3.0")
]
```

## Usage

### Decoding with Codable

Use `YYJSONDecoder` as an alternative to `JSONDecoder`:

```swift
import YYJSON

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

let json = #"{"id": 1, "name": "Alice", "email": "alice@example.com"}"#
let data = json.data(using: .utf8)!

let decoder = YYJSONDecoder()
let user = try decoder.decode(User.self, from: data)
print(user.name) // "Alice"
```

`YYJSONDecoder` supports the same decoding strategies as `JSONDecoder`:

```swift
let decoder = YYJSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .iso8601
decoder.dataDecodingStrategy = .base64
```

### JSON5 Support

Enable JSON5 parsing for more flexible input:

```swift
let decoder = YYJSONDecoder()
decoder.allowsJSON5 = true  // Enable all JSON5 features
```

Or configure individual JSON5 features:

```swift
decoder.allowsJSON5 = .init(
    trailingCommas: true,   // Allow [1, 2, 3,]
    comments: true,         // Allow // and /* */ comments
    infAndNaN: true,        // Allow Infinity and NaN literals
    singleQuotedStrings: true  // Allow 'single quotes'
)
```

> [!NOTE]
> JSON5 support is unavailable when the `strictStandardJSON` trait is enabled.
> The `allowsJSON5` property and `JSON5DecodingOptions` type are conditionally compiled
> and will not be available at compile time.

### Encoding with Codable

Use `YYJSONEncoder` as an alternative to `JSONEncoder`:

```swift
import YYJSON

let user = User(id: 1, name: "Alice", email: "alice@example.com")

let encoder = YYJSONEncoder()
let data = try encoder.encode(user)
print(String(data: data, encoding: .utf8)!)
// {"id":1,"name":"Alice","email":"alice@example.com"}
```

Configure output formatting:

```swift
var encoder = YYJSONEncoder()
encoder.writeOptions = [.prettyPrinted, .escapeUnicode]
```

`YYJSONEncoder` supports date encoding strategies:

```swift
var encoder = YYJSONEncoder()
encoder.dateEncodingStrategy = .iso8601
// Or: .secondsSince1970, .millisecondsSince1970, .formatted(formatter), .custom(closure)
```

### DOM-Style Access

Parse JSON and access values directly without defining types:

```swift
import YYJSON

let json = #"{"users": [{"name": "Alice"}, {"name": "Bob"}]}"#
let value = try YYJSONValue(string: json)

// Access nested values with subscripts
if let name = value["users"]?[0]?["name"]?.string {
    print(name) // "Alice"
}
```

### In-Place Parsing

For maximum performance with large JSON files,
use in-place parsing to avoid copying the input data:

```swift
var data = try Data(contentsOf: fileURL)
let json = try YYJSONValue.parseInPlace(consuming: &data)
// `data` is now consumed and should not be used
```

In-place parsing allows yyjson to parse directly within the input buffer,
avoiding memory allocation for string storage.
The `inout` parameter makes it clear that the data is consumed by this operation.

> [!NOTE]
> For most use cases, the standard `YYJSONValue(data:)` initializer is sufficient.
> Use in-place parsing only when performance is critical
> and you can accept the ownership semantics.

### JSONSerialization Alternative

Use `YYJSONSerialization` with the same API as Foundation's `JSONSerialization`:

```swift
import YYJSON

let json = #"{"message": "Hello, World!"}"#
let data = json.data(using: .utf8)!

let object = try YYJSONSerialization.jsonObject(with: data)
if let dict = object as? [String: Any] {
    print(dict["message"] as? String ?? "") // "Hello, World!"
}
```

## Read and Write Options

### Reading Options

Configure parsing behavior with `YYJSONReadOptions`:

```swift
let value = try YYJSONValue(data: data, options: [.allowComments, .allowTrailingCommas])
```

Available options:

- `.stopWhenDone` — Stop after first complete JSON document
- `.numberAsRaw` — Read all numbers as raw strings
- `.allowInvalidUnicode` — Allow reading invalid unicode
- `.bigNumberAsRaw` — Read big numbers as raw strings

Non-standard options (unavailable when `strictStandardJSON` trait is enabled):

- `.allowTrailingCommas` — Allow `[1, 2, 3,]`
- `.allowComments` — Allow `//` and `/* */` comments
- `.allowInfAndNaN` — Allow `Infinity`, `-Infinity`, `NaN`
- `.allowBOM` — Allow UTF-8 BOM
- `.allowExtendedNumbers` — Allow hex, leading `.`, trailing `.`, leading `+`
- `.allowExtendedEscapes` — Allow `\a`, `\e`, `\v`, `\xNN`, etc.
- `.allowExtendedWhitespace` — Allow extended whitespace characters
- `.allowSingleQuotedStrings` — Allow `'single quotes'`
- `.allowUnquotedKeys` — Allow `{key: value}`
- `.json5` — Enable all JSON5 features

### Writing Options

Configure output with `YYJSONWriteOptions`:

```swift
var encoder = YYJSONEncoder()
encoder.writeOptions = [.prettyPrinted, .escapeSlashes]
```

Available options:

- `.prettyPrinted` — Pretty print with 4-space indent
- `.prettyPrintedTwoSpaces` — Pretty print with 2-space indent
- `.escapeUnicode` — Escape non-ASCII as `\uXXXX`
- `.escapeSlashes` — Escape `/` as `\/`
- `.allowInvalidUnicode` — Allow invalid unicode when encoding
- `.newlineAtEnd` — Add trailing newline

Non-standard options (unavailable when `strictStandardJSON` trait is enabled):

- `.allowInfAndNaN` — Write `Infinity` and `NaN` literals
- `.infAndNaNAsNull` — Write `Infinity` and `NaN` as `null`

## Package Traits

Customize the underlying yyjson library at compile time using package traits:

```swift
.package(
    url: "https://github.com/mattt/swift-yyjson.git",
    from: "0.3.0",
    traits: ["noWriter", "strictStandardJSON"]
)
```

By default, no traits are enabled —
you get full functionality with all features and validations included.
Enable traits only when you have specific size or performance requirements.

> [!NOTE]
> When traits are enabled,
> the corresponding Swift APIs are conditionally compiled
> and become unavailable at compile time.
> For example, enabling the `noReader` trait makes unavailable
> `YYJSONDecoder`, `YYJSONValue`, and `YYJSONSerialization.jsonObject(with:options:)`.
> Similarly, enabling the `noWriter` trait makes unavailable
> `YYJSONEncoder` and `YYJSONSerialization.data(withJSONObject:options:)`.

### `noReader`

Disables JSON reader functionality at compile-time
(functions with "read" in their name).
**Reduces binary size by about 60%.**
Use this if your application only needs to write JSON, not parse it.

When this trait is enabled, the following APIs become unavailable:

- `YYJSONDecoder`
- `YYJSONValue`, `YYJSONObject`, `YYJSONArray`
- `YYJSONSerialization.jsonObject(with:options:)`

### `noWriter`

Disables JSON writer functionality at compile-time
(functions with "write" in their name).
**Reduces binary size by about 30%.**
Use this if your application only needs to parse JSON, not generate it.

When this trait is enabled, the following APIs become unavailable:

- `YYJSONEncoder`
- `YYJSONSerialization.data(withJSONObject:options:)`

### `noIncrementalReader`

Disables the incremental JSON reader at compile-time.
Use this if you don't need to parse JSON in streaming/chunked mode.

### `noUtilities`

Disables support for
[JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901),
[JSON Patch](https://datatracker.ietf.org/doc/html/rfc6902/), and
[JSON Merge Patch](https://datatracker.ietf.org/doc/html/rfc7386).
Use this if you don't need these utilities for querying or modifying JSON documents.

### `noFastFloatingPoint`

Disables yyjson's fast floating-point number conversion
and uses libc's `strtod`/`snprintf` instead.
**Reduces binary size by about 30%, but significantly slows down floating-point read/write speed.**
Use this only if binary size is critical
and you don't process many floating-point values.

### `strictStandardJSON`

Disables non-standard JSON features at compile-time
(such as allowing comments, trailing commas, or infinity/NaN values).
**Reduces binary size by about 10% and slightly improves performance.**
Use this if you only need to handle strictly conformant JSON.

When this trait is enabled, the following APIs become unavailable:

- `YYJSONReadOptions.allowTrailingCommas`
- `YYJSONReadOptions.allowComments`
- `YYJSONReadOptions.allowInfAndNaN`
- `YYJSONReadOptions.allowBOM`
- `YYJSONReadOptions.allowExtendedNumbers`
- `YYJSONReadOptions.allowExtendedEscapes`
- `YYJSONReadOptions.allowExtendedWhitespace`
- `YYJSONReadOptions.allowSingleQuotedStrings`
- `YYJSONReadOptions.allowUnquotedKeys`
- `YYJSONReadOptions.json5`
- `YYJSONWriteOptions.allowInfAndNaN`
- `YYJSONWriteOptions.infAndNaNAsNull`
- `YYJSONDecoder.allowsJSON5`
- `JSON5DecodingOptions`
- `YYJSONSerialization.ReadingOptions.json5Allowed`

### `noUTF8Validation`

Disables UTF-8 validation at compile-time.
**Improves performance for non-ASCII strings by about 3% to 7%.**
Use this only if all input strings are guaranteed to be valid UTF-8.

> [!CAUTION]
> If this trait is enabled while passing invalid UTF-8 data,
> parsing errors may be silently ignored,
> strings may merge unexpectedly,
> or out-of-bounds memory access may occur.

## Differences from Foundation

`YYJSONDecoder` and `YYJSONEncoder` are designed to be API-compatible with
Foundation's `JSONDecoder` and `JSONEncoder` for common use cases.
However, there are some differences:

- **Error types**: Throws `YYJSONError` instead of `DecodingError`/`EncodingError`.
  `YYJSONSerialization` also throws `YYJSONError` rather than `NSError`.
- **Encoder strategies**: `YYJSONEncoder` does not yet support
  `keyEncodingStrategy` or `nonConformingFloatEncodingStrategy`

- **Output formatting**: Uses `writeOptions` instead of `outputFormatting`
- **Number precision**: yyjson parses numbers as 64-bit integers or doubles;
  extremely large integers may lose precision

## Thread Safety

- `YYJSONDecoder` and `YYJSONEncoder` are value types and safe to use from
  multiple threads, as long as each `encode`/`decode` call is not shared concurrently.
- `YYJSONValue`, `YYJSONObject`, and `YYJSONArray` are safe to share across threads
  for read-only access; they wrap an immutable yyjson document.
- The `number` property on `YYJSONValue` returns a `Double`. For exact representation
  of very large numbers, parse using `.bigNumberAsRaw` and read them as strings.

## License

This project is available under the MIT license.
See the LICENSE file for more info.

The underlying [yyjson](https://github.com/ibireme/yyjson) library
is also available under the MIT license.
