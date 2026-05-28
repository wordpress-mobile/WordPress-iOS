import Foundation

public enum ConnectionStatus: Hashable, Sendable {
    case ok
    case broken
    case invalid
    case refreshFailed
    /// The server has not recently tested this connection. Not an error
    /// state: a healthy connection between tests reports `nil` on the wire.
    case unknown

    public init(wireString: String?) {
        switch wireString {
        case "ok": self = .ok
        case "broken": self = .broken
        case "invalid": self = .invalid
        case "refresh-failed": self = .refreshFailed
        default: self = .unknown
        }
    }

    /// `true` only for states the server has actively confirmed are broken.
    /// `.unknown` (no recent test result) is treated as healthy-by-default.
    public var isBroken: Bool {
        switch self {
        case .broken, .invalid, .refreshFailed:
            return true
        case .ok, .unknown:
            return false
        }
    }
}
