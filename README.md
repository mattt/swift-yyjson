# YYJSON

A fast JSON library for Swift,
powered by [yyjson](https://github.com/ibireme/yyjson).

YYJSON provides API-compatible alternatives for
`JSONEncoder`, `JSONDecoder`, and `JSONSerialization`.
It supports configurable compile-time options via
[Swift package traits](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/packagetraits/)
for further optimization.

## Benchmarks

YYJSON delivers significant performance improvements
over Foundation's JSON APIs.
These benchmarks compare parsing times
using standard JSON test fixtures from
[nativejson-benchmark](https://github.com/miloyip/nativejson-benchmark).

| Fixture                      |  YYJSON | Foundation | Speedup |
| :--------------------------- | ------: | ---------: | ------: |
| `twitter.json` (~632KB)      | ~180 μs |    ~2.9 ms |    ~16× |
| `citm_catalog.json` (~1.7MB) | ~425 μs |    ~4.3 ms |    ~10× |
| `canada.json` (~2.2MB)       | ~2.3 ms |   ~36.0 ms |    ~16× |

YYJSON also uses significantly less memory.
Parsing twitter.json requires only 3 allocations compared to over 6,600 for Foundation,
with peak memory of 19 MB versus up to 378 MB.
For maximum efficiency,
[in-place parsing](#in-place-parsing)
eliminates allocations entirely by operating directly on the input buffer.

The performance advantage is most pronounced for large files,
access-heavy workloads where YYJSON's value-based API avoids repeated type casting,
and number-heavy data like GeoJSON that benefits from optimized floating-point parsing.

For detailed methodology and additional benchmarks,
see [swift-yyjson-benchmark](https://github.com/mattt/swift-yyjson-benchmark).

<details>

<summary>Raw Results</summary>

```shell
swift package benchmark --format markdown --filter "Fixture/.+" --time-units microseconds
```

```console
Host 'MacBook-Pro.local' with 16 'arm64' processors with 48 GB memory, running:
Darwin Kernel Version 25.2.0: Tue Nov 18 21:09:56 PST 2025; root:xnu-12377.61.12~1/RELEASE_ARM64_T6041
```

### Fixture/canada.json/Access/Foundation

| Metric                     |    p0 |   p25 |   p50 |   p75 |   p90 |   p99 |  p100 | Samples |
| :------------------------- | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ------: |
| Instructions (M) \*        |   971 |   972 |   972 |   972 |   974 |   978 |   978 |      29 |
| Malloc (total) (K) \*      |   224 |   224 |   224 |   224 |   224 |   224 |   224 |      29 |
| Memory (resident peak) (M) |    31 |    79 |   128 |   176 |   210 |   224 |   224 |      29 |
| Throughput (# / s) (#)     |    29 |    29 |    28 |    28 |    28 |    26 |    26 |      29 |
| Time (total CPU) (μs) \*   | 34183 | 34800 | 35455 | 35619 | 36078 | 37996 | 37996 |      29 |
| Time (wall clock) (μs) \*  | 34180 | 34800 | 35455 | 35586 | 36045 | 37976 | 37976 |      29 |

### Fixture/canada.json/Access/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   58 |   58 |   58 |   58 |   58 |   58 |   59 |     455 |
| Malloc (total) \*          |    6 |    6 |    6 |    6 |    6 |    6 |    6 |     455 |
| Memory (resident peak) (M) |   17 |   22 |   22 |   22 |   22 |   22 |   22 |     455 |
| Throughput (# / s) (#)     |  481 |  462 |  458 |  455 |  451 |  435 |  419 |     455 |
| Time (total CPU) (μs) \*   | 2082 | 2167 | 2185 | 2202 | 2224 | 2300 | 2403 |     455 |
| Time (wall clock) (μs) \*  | 2080 | 2167 | 2183 | 2200 | 2220 | 2298 | 2387 |     455 |

### Fixture/canada.json/Parse/Foundation

| Metric                     |    p0 |   p25 |   p50 |   p75 |   p90 |   p99 |  p100 | Samples |
| :------------------------- | ----: | ----: | ----: | ----: | ----: | ----: | ----: | ------: |
| Instructions (M) \*        |   308 |   308 |   308 |   308 |   309 |   312 |   312 |      85 |
| Malloc (total) (K) \*      |   167 |   167 |   167 |   167 |   167 |   167 |   167 |      85 |
| Memory (resident peak) (M) |    17 |   148 |   274 |   394 |   478 |   524 |   524 |      85 |
| Throughput (# / s) (#)     |    88 |    85 |    85 |    84 |    83 |    82 |    82 |      85 |
| Time (total CPU) (μs) \*   | 11425 | 11731 | 11821 | 11969 | 12034 | 12234 | 12234 |      85 |
| Time (wall clock) (μs) \*  | 11419 | 11723 | 11821 | 11969 | 12034 | 12227 | 12227 |      85 |

### Fixture/canada.json/Parse/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   35 |   35 |   35 |   35 |   35 |   35 |   35 |     790 |
| Malloc (total) \*          |    3 |    3 |    3 |    3 |    3 |    3 |    3 |     790 |
| Memory (resident peak) (M) |   17 |   22 |   22 |   22 |   22 |   22 |   22 |     790 |
| Throughput (# / s) (#)     |  861 |  810 |  802 |  795 |  787 |  760 |  745 |     790 |
| Time (total CPU) (μs) \*   | 1163 | 1236 | 1249 | 1261 | 1274 | 1318 | 1344 |     790 |
| Time (wall clock) (μs) \*  | 1162 | 1234 | 1247 | 1258 | 1271 | 1316 | 1342 |     790 |

### Fixture/canada.json/Parse/YYJSON+in-place

| Metric                     |  p0 | p25 | p50 | p75 | p90 | p99 | p100 | Samples |
| :------------------------- | --: | --: | --: | --: | --: | --: | ---: | ------: |
| Instructions (K) \*        |  35 |  35 |  35 |  35 |  35 |  35 |   35 |       1 |
| Malloc (total) \*          |   0 |   0 |   0 |   0 |   0 |   0 |    0 |       1 |
| Memory (resident peak) (M) |  24 |  24 |  24 |  24 |  24 |  24 |   24 |       1 |
| Throughput (# / s) (K)     | 792 | 792 | 792 | 792 | 792 | 792 |  792 |       1 |
| Time (total CPU) (μs) \*   |   1 |   1 |   1 |   1 |   1 |   1 |    1 |       1 |
| Time (wall clock) (μs) \*  |   1 |   1 |   1 |   1 |   1 |   1 |    1 |       1 |

### Fixture/citm_catalog.json/Access/Foundation

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   94 |   94 |   94 |   94 |   94 |   95 |   96 |     238 |
| Malloc (total) (K) \*      |   15 |   15 |   15 |   15 |   15 |   15 |   15 |     238 |
| Memory (resident peak) (M) |   19 |   76 |  132 |  189 |  226 |  246 |  246 |     238 |
| Throughput (# / s) (#)     |  246 |  241 |  239 |  237 |  235 |  229 |  228 |     238 |
| Time (total CPU) (μs) \*   | 4061 | 4155 | 4192 | 4231 | 4260 | 4362 | 4380 |     238 |
| Time (wall clock) (μs) \*  | 4060 | 4153 | 4190 | 4227 | 4260 | 4362 | 4378 |     238 |

### Fixture/citm_catalog.json/Access/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   12 |   12 |   12 |   12 |   12 |   12 |   13 |    2311 |
| Malloc (total) \*          | 1640 | 1640 | 1640 | 1640 | 1640 | 1640 | 1640 |    2311 |
| Memory (resident peak) (M) |   18 |   22 |   22 |   22 |   22 |   22 |   22 |    2311 |
| Throughput (# / s) (#)     | 2599 | 2439 | 2409 | 2383 | 2361 | 2265 | 2094 |    2311 |
| Time (total CPU) (μs) \*   |  386 |  412 |  417 |  421 |  425 |  443 |  479 |    2311 |
| Time (wall clock) (μs) \*  |  385 |  410 |  415 |  420 |  424 |  442 |  478 |    2311 |

### Fixture/citm_catalog.json/Parse/Foundation

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   73 |   73 |   73 |   73 |   73 |   73 |   74 |     297 |
| Malloc (total) (K) \*      |   14 |   14 |   14 |   14 |   14 |   14 |   14 |     297 |
| Memory (resident peak) (M) |   18 |   90 |  161 |  230 |  276 |  301 |  301 |     297 |
| Throughput (# / s) (#)     |  312 |  304 |  301 |  296 |  284 |  276 |  273 |     297 |
| Time (total CPU) (μs) \*   | 3205 | 3293 | 3330 | 3383 | 3521 | 3633 | 3660 |     297 |
| Time (wall clock) (μs) \*  | 3203 | 3291 | 3328 | 3381 | 3518 | 3629 | 3659 |     297 |

### Fixture/citm_catalog.json/Parse/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 |  p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ----: | ------: |
| Instructions (K) \*        | 9850 | 9855 | 9855 | 9855 | 9855 | 9871 | 10528 |    2871 |
| Malloc (total) \*          |    3 |    3 |    3 |    3 |    3 |    3 |     3 |    2871 |
| Memory (resident peak) (M) |   18 |   22 |   22 |   22 |   22 |   22 |    22 |    2871 |
| Throughput (# / s) (#)     | 3253 | 3075 | 3025 | 2973 | 2929 | 2801 |  2590 |    2871 |
| Time (total CPU) (μs) \*   |  309 |  327 |  332 |  338 |  343 |  359 |   392 |    2871 |
| Time (wall clock) (μs) \*  |  307 |  325 |  331 |  336 |  342 |  357 |   386 |    2871 |

### Fixture/citm_catalog.json/Parse/YYJSON+in-place

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions \*            | 9862 | 9863 | 9863 | 9863 | 9863 | 9863 | 9863 |       3 |
| Malloc (total) \*          |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       3 |
| Memory (resident peak) (M) |   21 |   21 |   23 |   23 |   23 |   23 |   23 |       3 |
| Throughput (# / s) (K)     | 3186 | 3186 | 3009 | 2857 | 2857 | 2857 | 2857 |       3 |
| Time (total CPU) (μs) \*   |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       3 |
| Time (wall clock) (μs) \*  |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       3 |

### Fixture/twitter.json/Access/Foundation

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   63 |   64 |   64 |   64 |   65 |   66 |   66 |     344 |
| Malloc (total) \*          | 6938 | 6939 | 6939 | 6939 | 6939 | 6939 | 6939 |     344 |
| Memory (resident peak) (M) |   19 |   79 |  142 |  204 |  240 |  262 |  265 |     344 |
| Throughput (# / s) (#)     |  364 |  353 |  348 |  343 |  338 |  310 |  298 |     344 |
| Time (total CPU) (μs) \*   | 2750 | 2836 | 2871 | 2914 | 2963 | 3232 | 3365 |     344 |
| Time (wall clock) (μs) \*  | 2749 | 2832 | 2869 | 2912 | 2961 | 3228 | 3356 |     344 |

### Fixture/twitter.json/Access/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (K) \*        | 4657 | 4657 | 4657 | 4657 | 4657 | 4674 | 5102 |    4986 |
| Malloc (total) \*          |  604 |  604 |  604 |  604 |  604 |  604 |  604 |    4986 |
| Memory (resident peak) (M) |   17 |   19 |   19 |   19 |   19 |   19 |   19 |    4986 |
| Throughput (# / s) (#)     | 5930 | 5843 | 5691 | 5383 | 5219 | 4727 | 3976 |    4986 |
| Time (total CPU) (μs) \*   |  170 |  173 |  177 |  187 |  194 |  214 |  257 |    4986 |
| Time (wall clock) (μs) \*  |  169 |  171 |  176 |  186 |  192 |  212 |  252 |    4986 |

### Fixture/twitter.json/Parse/Foundation

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (M) \*        |   44 |   44 |   44 |   44 |   44 |   44 |   44 |     501 |
| Malloc (total) \*          | 6636 | 6637 | 6637 | 6637 | 6637 | 6637 | 6637 |     501 |
| Memory (resident peak) (M) |   18 |  108 |  198 |  285 |  342 |  374 |  378 |     501 |
| Throughput (# / s) (#)     |  531 |  514 |  510 |  505 |  492 |  455 |  436 |     501 |
| Time (total CPU) (μs) \*   | 1887 | 1946 | 1964 | 1985 | 2032 | 2198 | 2296 |     501 |
| Time (wall clock) (μs) \*  | 1883 | 1945 | 1962 | 1982 | 2032 | 2198 | 2294 |     501 |

### Fixture/twitter.json/Parse/YYJSON

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions (K) \*        | 3509 | 3510 | 3510 | 3510 | 3510 | 3527 | 3941 |    6785 |
| Malloc (total) \*          |    3 |    3 |    3 |    3 |    3 |    3 |    3 |    6785 |
| Memory (resident peak) (M) |   17 |   19 |   19 |   19 |   19 |   19 |   19 |    6785 |
| Throughput (# / s) (#)     | 8544 | 8179 | 7791 | 7399 | 7267 | 6687 | 2383 |    6785 |
| Time (total CPU) (μs) \*   |  118 |  124 |  130 |  137 |  139 |  152 |  339 |    6785 |
| Time (wall clock) (μs) \*  |  117 |  122 |  128 |  135 |  138 |  150 |  420 |    6785 |

### Fixture/twitter.json/Parse/YYJSON+in-place

| Metric                     |   p0 |  p25 |  p50 |  p75 |  p90 |  p99 | p100 | Samples |
| :------------------------- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ------: |
| Instructions \*            | 3520 | 3522 | 3522 | 3522 | 3522 | 3522 | 3522 |       7 |
| Malloc (total) \*          |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       7 |
| Memory (resident peak) (M) |   19 |   20 |   20 |   20 |   20 |   20 |   20 |       7 |
| Throughput (# / s) (K)     | 8197 | 8087 | 7567 | 7419 | 7219 | 7219 | 7216 |       7 |
| Time (total CPU) (μs) \*   |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       7 |
| Time (wall clock) (μs) \*  |    0 |    0 |    0 |    0 |    0 |    0 |    0 |       7 |

</details>

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
