/// Allows automatic defaulting to `unknown` for any Enum that conforms to `UnknownCaseRepresentable`
/// Credits: https://www.latenightswift.com/2019/02/04/unknown-enum-cases/
protocol UnknownCaseRepresentable: RawRepresentable, CaseIterable where RawValue: Equatable {
    static var unknownCase: Self { get }
}

extension UnknownCaseRepresentable {
    public init(rawValue: RawValue) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? Self.unknownCase
    }
}
