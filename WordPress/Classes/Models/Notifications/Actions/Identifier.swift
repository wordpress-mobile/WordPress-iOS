struct Identifier: Equatable, Hashable {
    private let rawValue: String

    init(value: String) {
        rawValue = value
    }
}
