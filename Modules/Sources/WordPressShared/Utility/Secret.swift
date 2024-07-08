import Foundation

/// Wraps a value that contains sensitive information to prevent accidental logging
///
/// Usage example
///
/// ```
/// let password = Secret("my secret password")
/// print(password)             // Prints "--redacted--"
/// print(password.secretValue) // Prints "my secret password"
/// ```
///
public struct Secret<T> {
    public let secretValue: T

    public init(_ secretValue: T) {
        self.secretValue = secretValue
    }
}

extension Secret: RawRepresentable {
    public typealias RawValue = T

    public init?(rawValue: Self.RawValue) {
        self.init(rawValue)
    }

    public var rawValue: T {
        return secretValue
    }
}

extension Secret: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    private static var redacted: String {
        return "--redacted--"
    }

    public var description: String {
        return Secret.redacted
    }

    public var debugDescription: String {
        return Secret.redacted
    }

    public var customMirror: Mirror {
        return Mirror(reflecting: Secret.redacted)
    }
}
