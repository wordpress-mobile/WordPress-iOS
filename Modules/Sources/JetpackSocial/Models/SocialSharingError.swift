import Foundation

public enum SocialSharingError: Error, Sendable {
    case network(Error)
    case notAuthenticated
    case connectionNotFound(id: String)
    case keyringNotFound(id: Int64)
    case noKeyringForService(serviceLabel: String)
    /// Surfaced after a successful Facebook OAuth when the keyring exposes no
    /// Pages — Publicize cannot post to a personal Facebook profile, so the
    /// connection cannot be completed. Distinct from `noKeyringForService` so
    /// the UI can offer the dedicated "Learn more" link.
    case noPagesForFacebook
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
        case .noPagesForFacebook:
            return Strings.Errors.noPagesForFacebook
        case .decoding:
            return Strings.Errors.decoding
        case .unknown:
            return Strings.Errors.unknown
        }
    }
}

extension SocialSharingError {
    /// URL pointing at user-facing documentation that explains how to recover
    /// from this error, when one exists.
    public var helpURL: URL? {
        switch self {
        case .noPagesForFacebook:
            return URL(string: "https://en.support.wordpress.com/publicize/#facebook-pages")
        default:
            return nil
        }
    }
}
