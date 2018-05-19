import Foundation

enum MediaExportProgressUnits {
    static let done: Int64 = 100
    static let halfDone: Int64 = MediaExportProgressUnits.done / 2
    static let quarterDone: Int64 = MediaExportProgressUnits.done / 4
    static let threeQuartersDone: Int64 = (MediaExportProgressUnits.done / 4) * 3
}
/// The MediaExport class represents the result of an MediaExporter.
///
class MediaExport {
    /// The resulting file URL of an export.
    ///
    let url: URL
    /// The resulting file size in bytes of the export.
    let fileSize: Int64?
    /// The pixel width of the media exported.
    let width: CGFloat?
    /// The pixel height of the media exported.
    let height: CGFloat?
    /// The duration of a media file, this is only available if the asset is a video.
    let duration: TimeInterval?
    /// A caption to be added to the media item.
    let caption: String?

    init(url: URL, fileSize: Int64?, width: CGFloat?, height: CGFloat?, duration: TimeInterval?, caption: String? = nil) {
        self.url = url
        self.fileSize = fileSize
        self.height = height
        self.width = width
        self.duration = duration
        self.caption = caption
    }
}

/// Completion block with an AssetExport.
///
typealias OnMediaExport = (MediaExport) -> Void

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

    /// Export a media to another format
    ///
    /// - Parameters:
    ///   - onCompletion: a callback to invoke when the export finish with success.
    ///   - onError: a callback to invoke when the export fails.
    /// - Returns: a progress object that indicates the progress on the export task
    ///
    @discardableResult func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress
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
