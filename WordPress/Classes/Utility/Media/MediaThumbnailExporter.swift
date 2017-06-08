import Foundation

/// MediaLibrary export handling of thumbnail images from videos or images.
///
class MediaThumbnailExporter: MediaExporter {

    /// Directory type for the ThumbnailExporter, defaults to the .cache directory.
    ///
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .cache

    var options: MediaImageExporter.Options?

    public enum ThumbnailExportError: MediaExportError {
        case gifThumbnailsUnsupported

        var description: String {
            switch self {
            default:
                return NSLocalizedString("GIF preview unavailable.", comment: "Message shown if a preview of a GIF media item is unavailable.")
            }
        }
    }

    typealias OnThumbnailExport = (MediaImageExport) -> Void

    /// Export a thumbnail image for a file at the URL, with an expected type of an image or video.
    ///
    /// - Note: GIFs are currently unsupported and throw the .gifThumbnailsUnsupported error.
    ///
    func exportThumbnail(forFile url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) {
        do {
            let expected = try MediaURLExporter.expectedExport(with: url)
            switch expected {
            case .image:
                exportImageThumbnail(at: url, onCompletion: onCompletion, onError: onError)
            case .video:
                exportVideoThumbnail(at: url, onCompletion: onCompletion, onError: onError)
            case .gif:
                throw ThumbnailExportError.gifThumbnailsUnsupported
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Export a thumbnail for a known image at the URL, using self.options for ImageExporter options.
    ///
    fileprivate func exportImageThumbnail(at url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) {
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = .temporary
        if let options = options {
            exporter.options = options
        }
        exporter.exportImage(atURL: url,
                             onCompletion: { (export) in
                                self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        },
                             onError: onError)
    }

    /// Export a thumbnail for a known video at the URL, using self.options for ImageExporter options.
    ///
    fileprivate func exportVideoThumbnail(at url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) {
        let exporter = MediaVideoExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.exportPreviewImageForVideo(atURL: url,
                                            imageOptions: options,
                                            onCompletion: { (export) in
                                                self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        },
                                            onError: onError)
    }

    /// Renames and moves an exported thumbnail to the expected directory with the expected thumbnail filenaming convention.
    ///
    fileprivate func exportImageToThumbnailCache(_ export: MediaImageExport, onCompletion: OnThumbnailExport, onError: OnExportError) {
        do {
            // Get a new thumbnail filename
            let thumbnailFilename = MediaLibrary.mediaFilenameAppendingThumbnail(export.url.lastPathComponent)
            // Get a new URL for the file as a thumbnail within the cache.
            let cacheURL = try MediaLibrary.makeLocalMediaURL(withFilename: thumbnailFilename,
                                                              fileExtension: nil,
                                                              type: mediaDirectoryType)
            let fileManager = FileManager.default
            // Move the exported file at the url to the new URL.
            try fileManager.moveItem(at: export.url, to: cacheURL)
            // Configure with the new URL
            let thumbnailExport = MediaImageExport(url: cacheURL,
                                                   fileSize: export.fileSize,
                                                   width: export.width,
                                                   height: export.height)
            // And return.
            onCompletion(thumbnailExport)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }
}
