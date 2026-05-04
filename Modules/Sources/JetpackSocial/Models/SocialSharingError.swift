import Foundation

public enum SocialSharingError: Error, Sendable {
    case network(Error)
    case notAuthenticated
    case connectionNotFound(id: String)
    case keyringNotFound(id: Int64)
    case noKeyringForService(serviceLabel: String)
    case decoding(Error)
    case unknown(Error)
}

extension SocialSharingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network:
            return Strings.Errors.network
        case .notAuthenticated:
            return Strings.Errors.notAuthenticated
        case .connectionNotFound(let id):
            return String.localizedStringWithFormat(Strings.Errors.connectionNotFoundFormat, id)
        case .keyringNotFound(let id):
            return String.localizedStringWithFormat(Strings.Errors.keyringNotFoundFormat, String(id))
        case .noKeyringForService(let label):
            return String.localizedStringWithFormat(Strings.Errors.noKeyringForServiceFormat, label)
        case .decoding:
            return Strings.Errors.decoding
        case .unknown:
            return Strings.Errors.unknown
        }
    }
}
