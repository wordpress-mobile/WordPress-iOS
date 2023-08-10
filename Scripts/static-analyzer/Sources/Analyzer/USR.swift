import Foundation

public struct USR: ExpressibleByStringLiteral, RawRepresentable {
    public var rawValue: String

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
}
