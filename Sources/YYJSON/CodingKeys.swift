/// A general-purpose coding key that can represent both string keys and array indices.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    init?(intValue: Int) {
        self.stringValue = "Index \(intValue)"
        self.intValue = intValue
    }
}
