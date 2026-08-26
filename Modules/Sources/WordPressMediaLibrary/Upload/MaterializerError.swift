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
