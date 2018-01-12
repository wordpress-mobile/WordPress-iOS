import Foundation
import MobileCoreServices

/// Media export handling of URLs.
///
class MediaURLExporter: MediaExporter {

    var mediaDirectoryType: MediaDirectory = .uploads

    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    public enum URLExportError: MediaExportError {
        case invalidFileURL
        case unknownFileUTI
        case unsupportedFileType

        var description: String {
            switch self {
            default:
                return NSLocalizedString("The media could not be added to the Media Library.", comment: "Message shown when an image or video failed to load while trying to add it to the Media library.")
            }
        }
    }

    /// Enums of expected export types.
    ///
    public enum URLExportExpectation {
        case image
        case video
        case gif
    }

    private let url: URL

    init(url: URL) {
        self.url = url
    }

    @discardableResult public func export(onCompletion: @escaping OnMediaExport, onError: @escaping (MediaExportError) -> Void) -> Progress {
        return exportURL(fileURL: url, onCompletion: onCompletion, onError: onError)
    }

    /// Query what the URLExporter expects to export a URL as. Throws an error if unknown or invalid.
    ///
    /// - Note: Expects a file conforming to a video, image or GIF uniform type.
    ///
    class func expectedExport(with fileURL: URL) throws -> URLExportExpectation {
        guard fileURL.isFileURL else {
            throw URLExportError.invalidFileURL
        }
        guard let typeIdentifier = fileURL.typeIdentifier as CFString? else {
            throw URLExportError.unknownFileUTI
        }
        if UTTypeEqual(typeIdentifier, kUTTypeGIF) {
            return .gif
        } else if UTTypeConformsTo(typeIdentifier, kUTTypeVideo) || UTTypeConformsTo(typeIdentifier, kUTTypeMovie) {
            return .video
        } else if UTTypeConformsTo(typeIdentifier, kUTTypeImage) {
            return .image
        }
        throw URLExportError.unsupportedFileType
    }

    /// Exports a file of a supported type, to a new Media URL.
    ///
    /// - Note: You can query the expected type via MediaURLExporter.expectedExport(with:).
    ///
    func exportURL(fileURL: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        do {
            let expected = try MediaURLExporter.expectedExport(with: fileURL)
            switch expected {
            case .image:
                return exportImage(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            case .video:
                return exportVideo(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            case .gif:
                return exportGIF(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
        return Progress.discreteCompletedProgress()
    }

    /// Exports the known image file at the URL, via MediaImageExporter.
    ///
    fileprivate func exportImage(atURL url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        // Pass the export off to the image exporter
        let exporter = MediaImageExporter(url: url)
        exporter.mediaDirectoryType = mediaDirectoryType
        if let options = imageOptions {
            exporter.options = options
        }
        return exporter.export(
            onCompletion: { (imageExport) in
                onCompletion(imageExport)
        },
            onError: onError)
    }

    /// Exports the known video file at the URL, via MediaVideoExporter.
    ///
    fileprivate func exportVideo(atURL url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        // Pass the export off to the video exporter.
        let videoExporter = MediaVideoExporter(url: url)
        videoExporter.mediaDirectoryType = mediaDirectoryType
        if let options = videoOptions {
            videoExporter.options = options
        }
        return videoExporter.export(onCompletion: { videoExport in
                                    onCompletion(videoExport)
        },
                                  onError: onError)

    }

    /// Exports the GIF file at the URL to a new Media URL, by simply copying the file.
    ///
    fileprivate func exportGIF(atURL url: URL, onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        do {
            let fileManager = FileManager.default
            let mediaURL = try mediaFileManager.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                                    fileExtension: "gif")
            try fileManager.copyItem(at: url, to: mediaURL)
            onCompletion(MediaExport(url: mediaURL,
                                    fileSize: mediaURL.fileSize,
                                    width: mediaURL.pixelSize.width,
                                    height: mediaURL.pixelSize.height,
                                    duration: nil))
        } catch {
            onError(exporterErrorWith(error: error))
        }
        return Progress.discreteCompletedProgress()
    }
}
