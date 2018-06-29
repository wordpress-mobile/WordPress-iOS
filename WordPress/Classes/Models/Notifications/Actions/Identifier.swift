struct Identifier: Equatable, Hashable {
    private let rawValue: String

    init(value: String) {
        rawValue = value
    }
}

extension Identifier: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}
