import Foundation
import MobileCoreServices

/// MediaLibrary export handling of URLs.
///
class MediaURLExporter: MediaExporter {

    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    var imageOptions: MediaImageExporter.Options?
    var videoOptions: MediaVideoExporter.Options?

    /// Enumerable type value for a URLExport, typed according to the resulting export of the file at the URL.
    ///
    public enum URLExport {
        case exportedImage(MediaImageExport)
        case exportedVideo(MediaVideoExport)
        case exportedGIF(MediaGIFExport)
    }

    /// Completion block with a URLExport.
    ///
    typealias OnURLExport = (URLExport) -> Void

    public enum URLExportError: MediaExportError {
        case invalidFileURL
        case unknownFileUTI

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

    /// Query what the URLExporter expects to export a URL as. Throws an error if unknown or invalid.
    ///
    /// - Note: Expects a file conforming to a video, image or GIF uniform type.
    ///
    class func expectedExport(with fileURL: URL) throws -> URLExportExpectation {
        guard fileURL.isFileURL else {
            throw URLExportError.invalidFileURL
        }
        guard let typeIdentifier = fileURL.resourceTypeIdentifier as CFString? else {
            throw URLExportError.unknownFileUTI
        }
        if UTTypeEqual(typeIdentifier, kUTTypeGIF) {
            return .gif
        } else if UTTypeConformsTo(typeIdentifier, kUTTypeVideo) || UTTypeConformsTo(typeIdentifier, kUTTypeMovie) {
            return .video
        } else if UTTypeConformsTo(typeIdentifier, kUTTypeImage) {
            return .image
        }
        throw URLExportError.unknownFileUTI
    }

    /// Exports a file of a supported type, to a new Media URL.
    ///
    /// - Note: You can query the expected type via MediaURLExporter.expectedExport(with:).
    ///
    func exportURL(fileURL: URL, onCompletion: @escaping OnURLExport, onError: @escaping OnExportError) {
        do {
            let expected = try MediaURLExporter.expectedExport(with: fileURL)
            switch expected {
            case .image:
                exportImage(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            case .video:
                exportVideo(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            case .gif:
                exportGIF(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports the known image file at the URL, via MediaImageExporter.
    ///
    fileprivate func exportImage(atURL url: URL, onCompletion: @escaping OnURLExport, onError: @escaping OnExportError) {
        // Pass the export off to the image exporter
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = mediaDirectoryType
        if let options = imageOptions {
            exporter.options = options
        }
        exporter.exportImage(atFile: url,
                             onCompletion: { (imageExport) in
                                onCompletion(URLExport.exportedImage(imageExport))
        },
                             onError: onError)
    }

    /// Exports the known video file at the URL, via MediaVideoExporter.
    ///
    fileprivate func exportVideo(atURL url: URL, onCompletion: @escaping OnURLExport, onError: @escaping OnExportError) {
        // Pass the export off to the video exporter.
        let videoExporter = MediaVideoExporter()
        videoExporter.mediaDirectoryType = mediaDirectoryType
        if let options = videoOptions {
            videoExporter.options = options
        }
        videoExporter.exportVideo(atURL: url,
                                  onCompletion: { videoExport in
                                    onCompletion(URLExport.exportedVideo(videoExport))
        },
                                  onError: onError)
    }

    /// Exports the GIF file at the URL to a new Media URL, by simply copying the file.
    ///
    fileprivate func exportGIF(atURL url: URL, onCompletion: @escaping OnURLExport, onError: @escaping OnExportError) {
        do {
            let fileManager = FileManager.default
            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                              fileExtension: "gif",
                                                              type: mediaDirectoryType)
            try fileManager.copyItem(at: url, to: mediaURL)
            onCompletion(URLExport.exportedGIF(MediaGIFExport(url: mediaURL,
                                                              fileSize: mediaURL.resourceFileSize)))
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }
}
