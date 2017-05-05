import Foundation
import MobileCoreServices

/// General MediaExport protocol, and its requirements.
///
protocol MediaExport {
    /// The resulting file URL of an export.
    ///
    var url: URL { get }
    var fileSize: Int64? { get }
}

/// Struct of an image export.
///
struct MediaImageExport: MediaExport {
    let url: URL
    let fileSize: Int64?
    let width: CGFloat?
    let height: CGFloat?
}

/// Struct of a video export.
///
struct MediaVideoExport: MediaExport {
    let url: URL
    let fileSize: Int64?
    let duration: TimeInterval?
}

/// Struct of a GIF export.
///
struct MediaGIFExport: MediaExport {
    let url: URL
    let fileSize: Int64?
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

protocol MediaExporter {
    /// Set a maximumImageSize for resizing images, or nil for exporting the full images.
    ///
    var maximumImageSize: CGFloat? { get set }

    /// Strip the geoLocation from assets, if needed.
    ///
    var stripsGeoLocationIfNeeded: Bool { get set }

    /// The type of MediaDirectory to use for the export destination URL.
    ///
    /// - Note: This would almost always be set to .uploads, but for unit testing we use .temporary.almost
    ///
    var mediaDirectoryType: MediaLibrary.MediaDirectoryType { get set }
}

extension MediaExporter {

    /// Handles wrapping into MediaExportError type values when the encountered Error type value is unknown.
    ///
    /// - param error: Error with an unknown type value, or nil for easy conversion.
    /// - returns: The ExporterError type value itself, or an ExportError.failedWith
    ///
    func exporterErrorWith(error: Error) -> MediaExportError {
        switch error {
        case let error as MediaExportError:
            return error
        default:
            return MediaExportSystemError.failedWith(systemError: error)
        }
    }

    /// Returns the size of the file at the URL, if available.
    ///
    /// - param URL: A file URL.
    /// - returns: The size in bytes, or nil if unavailable.
    ///
    func fileSizeAtURL(_ url: URL) -> Int64? {
        guard url.isFileURL else {
            return nil
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64
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
