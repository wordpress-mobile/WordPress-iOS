import Foundation

enum MaterializerError: LocalizedError {
    case securityScopedAccessDenied
    case fileNotFound
    case durationCapExceeded
    case disallowedContentType
    case invalidImageData
    case imageEncodeFailed
    case locationStripFailed
    case videoExportFailed(underlyingError: Error)
    case videoExportSessionUnavailable
    case unknownContentType
    case remoteDownloadFailed(underlyingError: Error)

    var errorDescription: String? {
        switch self {
        case .securityScopedAccessDenied: return Strings.uploadErrorSecurityScopedAccess
        case .fileNotFound: return Strings.uploadErrorFileNotFound
        case .durationCapExceeded: return Strings.uploadErrorDurationCap
        case .disallowedContentType: return Strings.uploadErrorDisallowedType
        case .invalidImageData: return Strings.uploadErrorInvalidImage
        case .imageEncodeFailed: return Strings.uploadErrorImageEncode
        case .locationStripFailed: return Strings.uploadErrorLocationStripFailed
        case .videoExportFailed(let underlyingError):
            return String.localizedStringWithFormat(
                Strings.uploadErrorVideoExport,
                underlyingError.localizedDescription
            )
        case .videoExportSessionUnavailable: return Strings.uploadErrorVideoExportNoExporter
        case .unknownContentType: return Strings.uploadErrorUnknownContentType
        case .remoteDownloadFailed(let underlyingError):
            return String.localizedStringWithFormat(
                Strings.materializerErrorRemoteDownloadFailed,
                underlyingError.localizedDescription
            )
        }
    }
}

extension MaterializerError {
    /// Photos providers and remote downloads can wrap a URL-loading error.
    /// Unknown errors and content/policy failures stay remove-only.
    static func isTransientPreparationFailure(_ error: Error) -> Bool {
        var current = error
        // Bound traversal in case an NSError has a cyclic underlying error.
        for _ in 0..<8 {
            if let materializerError = current as? MaterializerError {
                switch materializerError {
                case .remoteDownloadFailed(let underlying), .videoExportFailed(let underlying):
                    current = underlying
                    continue
                default:
                    return false
                }
            }
            let underlying = current as NSError
            if underlying.domain == NSURLErrorDomain {
                switch underlying.code {
                case URLError.timedOut.rawValue, URLError.networkConnectionLost.rawValue,
                    URLError.notConnectedToInternet.rawValue, URLError.cannotFindHost.rawValue,
                    URLError.cannotConnectToHost.rawValue, URLError.dnsLookupFailed.rawValue:
                    return true
                default:
                    return false
                }
            }
            guard let next = underlying.userInfo[NSUnderlyingErrorKey] as? Error else { return false }
            current = next
        }
        return false
    }
}
