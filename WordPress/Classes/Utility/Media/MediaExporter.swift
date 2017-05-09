import Foundation
import MobileCoreServices

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

/// Protocol of required default variables or values for a MediaExporter and passing those values between them.
///
protocol MediaExporter {
    /// Set a maximumImageSize for resizing images, or nil for exporting the full images.
    ///
    var maximumImageSize: CGFloat? { get set }

    /// Strip the geoLocation from assets, if needed.
    ///
    var stripsGeoLocationIfNeeded: Bool { get set }

    /// The type of MediaDirectory to use for the export destination URL.
    ///
    /// - Note: This would almost always be set to .uploads, but for unit testing we use .temporary.
    ///
    var mediaDirectoryType: MediaLibrary.MediaDirectory { get set }
}

/// Extension providing generic helper implementation particular to MediaExporters.
///
extension MediaExporter {

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

    /// The expected file extension string for a given UTType identifier.
    ///
    /// - param type: The UTType identifier
    /// - returns: The expected file extension or nil if unknown.
    ///
    func fileExtensionForUTType(_ type: String) -> String? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
        return fileExtension as String?
    }
}
