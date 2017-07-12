import Foundation

/// General MediaExport protocol, and its requirements.
///
protocol MediaExport {
    /// The resulting file URL of an export.
    ///
    var url: URL { get }
    var fileSize: Int? { get }
}

/// Struct of an image export.
///
struct MediaImageExport: MediaExport {
    let url: URL
    let fileSize: Int?
    let width: CGFloat?
    let height: CGFloat?
}

/// Struct of a video export.
///
struct MediaVideoExport: MediaExport {
    let url: URL
    let fileSize: Int?
    let duration: TimeInterval?
}

/// Struct of a GIF export.
///
struct MediaGIFExport: MediaExport {
    let url: URL
    let fileSize: Int?
}

/// Generic Error protocol for detecting and type classifying known errors that occur while exporting.
///
protocol MediaExportError: Error, CustomStringConvertible {
    /// Convert an Error to an NSError with a localizedDescription available.
    ///
    func toNSError() -> NSError
}

/// MediaExportError default implementation.
///
extension MediaExportError {
    /// Default implementation for ensuring a MediaExportError converts to an NSError with localized string.
    ///
    func toNSError() -> NSError {
        return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
    }
}

/// Generic MediaExportError tied to a system generated Error.
///
enum MediaExportSystemError: MediaExportError {
    case failedWith(systemError: Error)
    public var description: String {
        switch self {
        case .failedWith(let systemError):
            return String(describing: systemError)
        }
    }
    func toNSError() -> NSError {
        switch self {
        case .failedWith(let systemError):
            return systemError as NSError
        }
    }
}

/// Failure block with an ExportError.
///
typealias OnExportError = (MediaExportError) -> Void

/// Protocol of required default variables or values for a MediaExporter and passing those values between them.
///
protocol MediaExporter {

    /// The type of MediaDirectory to use for the export destination URL.
    ///
    /// - Note: This would generally be set to .uploads or .cache, but for unit testing we use .temporary.
    ///
    var mediaDirectoryType: MediaDirectory { get set }
}

/// Extension providing generic helper implementation particular to MediaExporters.
///
extension MediaExporter {

    /// A MediaFileManager configured with the exporter's set MediaDirectory type.
    ///
    var mediaFileManager: MediaFileManager {
        return MediaFileManager(directory: mediaDirectoryType)
    }

    /// Handles wrapping into MediaExportError value types when the encountered Error value type is unknown.
    ///
    /// - param error: Error with an unknown value type, or nil for easy conversion.
    /// - returns: The ExporterError value type itself, or an ExportError.failedWith
    ///
    func exporterErrorWith(error: Error) -> MediaExportError {
        switch error {
        case let error as MediaExportError:
            return error
        default:
            return MediaExportSystemError.failedWith(systemError: error)
        }
    }
}

/// Protocol of general options available for an export, typically corresponding to a user setting.
///
protocol MediaExportingOptions {

    /// Strip the geoLocation from exported media, if needed.
    ///
    var stripsGeoLocationIfNeeded: Bool { get set }
}
