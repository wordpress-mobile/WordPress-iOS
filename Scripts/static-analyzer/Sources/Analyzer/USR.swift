import Foundation

/// A type represent "Unified Symbol Resolution" string.
///
/// From [this random API doc in clang](https://libclang.readthedocs.io/en/latest/#clang.cindex.Cursor.get_usr):
/// > A Unified Symbol Resolution (USR) is a string that identifies a particular entity (function, class, variable, etc.) within a program.
public struct USR: ExpressibleByStringLiteral, RawRepresentable {
    public var rawValue: String

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
}
