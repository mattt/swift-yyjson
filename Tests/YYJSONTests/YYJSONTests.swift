import Testing

@testable import YYJSON

@Test func testBasicDecoding() async throws {
    let json = """
        {
            "name": "Test",
            "age": 42,
            "active": true
        }
        """
    let data = json.data(using: .utf8)!

    struct Person: Codable {
        let name: String
        let age: Int
        let active: Bool
    }

    let decoder = YYJSONDecoder()
    let person = try decoder.decode(Person.self, from: data)

    #expect(person.name == "Test")
    #expect(person.age == 42)
    #expect(person.active == true)
}

@Test func testBasicEncoding() async throws {
    struct Person: Codable {
        let name: String
        let age: Int
        let active: Bool
    }

    let person = Person(name: "Test", age: 42, active: true)
    let encoder = YYJSONEncoder()
    let data = try encoder.encode(person)

    let decoder = YYJSONDecoder()
    let decoded = try decoder.decode(Person.self, from: data)

    #expect(decoded.name == person.name)
    #expect(decoded.age == person.age)
    #expect(decoded.active == person.active)
}

@Test func testDOMLayer() async throws {
    let json = """
        {
            "users": [
                {"name": "Alice", "age": 30},
                {"name": "Bob", "age": 25}
            ]
        }
        """
    let data = json.data(using: .utf8)!

    let value = try YYJSONValue(data: data)

    #expect(value["users"] != nil)
    if let users = value["users"]?.array {
        #expect(users.count == 2)
        if let firstUser = users[0] {
            #expect(firstUser["name"]?.string == "Alice")
            #expect(firstUser["age"]?.number == 30.0)
        }
    }
}

@Test func testArrayDecoding() async throws {
    let json = """
        [1, 2, 3, 4, 5]
        """
    let data = json.data(using: .utf8)!

    let decoder = YYJSONDecoder()
    let numbers = try decoder.decode([Int].self, from: data)

    #expect(numbers == [1, 2, 3, 4, 5])
}

@Test func testNestedStructures() async throws {
    struct Address: Codable {
        let street: String
        let city: String
    }

    struct Person: Codable {
        let name: String
        let address: Address
    }

    let json = """
        {
            "name": "John",
            "address": {
                "street": "123 Main St",
                "city": "Anytown"
            }
        }
        """
    let data = json.data(using: .utf8)!

    let decoder = YYJSONDecoder()
    let person = try decoder.decode(Person.self, from: data)

    #expect(person.name == "John")
    #expect(person.address.street == "123 Main St")
    #expect(person.address.city == "Anytown")
}
