import Foundation

enum MaterializerError: LocalizedError {
    case securityScopedAccessDenied
    case fileNotFound
    case durationCapExceeded
    case disallowedContentType
    case heicConversionFailed
    case videoExportFailed(underlyingError: Error)
    case unknownContentType
    case remoteDownloadFailed(underlyingError: Error)

    var errorDescription: String? {
        switch self {
        case .securityScopedAccessDenied: return Strings.uploadErrorSecurityScopedAccess
        case .fileNotFound: return Strings.uploadErrorFileNotFound
        case .durationCapExceeded: return Strings.uploadErrorDurationCap
        case .disallowedContentType: return Strings.uploadErrorDisallowedType
        case .heicConversionFailed: return Strings.uploadErrorHEICConversion
        case .videoExportFailed(let underlyingError):
            return String.localizedStringWithFormat(
                Strings.uploadErrorVideoExport,
                underlyingError.localizedDescription
            )
        case .unknownContentType: return Strings.uploadErrorUnknownContentType
        case .remoteDownloadFailed(let underlyingError):
            return String.localizedStringWithFormat(
                Strings.materializerErrorRemoteDownloadFailed,
                underlyingError.localizedDescription
            )
        }
    }
}

enum VideoExportFailureReason: LocalizedError {
    case noExporterForPreset

    var errorDescription: String? {
        switch self {
        case .noExporterForPreset: return Strings.uploadErrorVideoExportNoExporter
        }
    }
}
