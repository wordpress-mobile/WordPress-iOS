import Foundation
import MobileCoreServices

/// MediaLibrary export handling of thumbnail images from videos or images.
///
class MediaThumbnailExporter: MediaExporter {

    /// Directory type for the ThumbnailExporter, defaults to the .cache directory.
    ///
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .cache

    var options = Options()

    /// Available options for an thumbnail export.
    ///
    struct Options {

        /// The preferred size of the image, in points, typically for the actual display
        /// of the image within a layout's dimensions.
        ///
        /// - Note: The final size may or may not match the preferred dimensions, depending
        ///   on the original image.
        ///
        var preferredSize: CGSize?

        /// The scale for the actual pixel size of the image when resizing,
        /// generally matching a screen scale of 1.0, 2.0, 3.0, etc.
        ///
        /// - Note: Defaults to the main UIScreen scale. The final image may or may not match
        ///   the intended scale/pixels, depending on the original image.
        ///
        var scale: CGFloat = UIScreen.main.scale

        /// Computed preferred size, at scale.
        ///
        var preferredSizeAtScale: CGSize? {
            guard let size = preferredSize else {
                return nil
            }
            return CGSize(width: size.width * scale, height: size.height * scale)
        }

        /// Computed preferred maximum size, at scale.
        ///
        var preferredMaximumSizeAtScale: CGFloat? {
            guard let size = preferredSize else {
                return nil
            }
            return max(size.width, size.height) * scale
        }
    }

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

    /// The URL the exporter expects to write for the URL and configured export options.
    ///
    func expectedThumbnailURL(forFile url: URL) throws -> URL {
        var thumbnailURL = try thumbnailURLWithOptions(for: url).deletingPathExtension()
        thumbnailURL.appendPathExtension(URL.fileExtensionForUTType(kUTTypeJPEG as String)!)
        return thumbnailURL
    }

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
        if let maximumSize = options.preferredMaximumSizeAtScale {
            exporter.options.maximumImageSize = maximumSize
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
        var imageOptions: MediaImageExporter.Options?
        if let maximumSize = options.preferredMaximumSizeAtScale {
            imageOptions = MediaImageExporter.Options()
            imageOptions!.maximumImageSize = maximumSize
        }
        exporter.exportPreviewImageForVideo(atURL: url,
                                            imageOptions: imageOptions,
                                            onCompletion: { (export) in
                                                self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        },
                                            onError: onError)
    }

    /// A thumbnail URL written with the corresponding filename and export options.
    ///
    fileprivate func thumbnailURLWithOptions(for url: URL) throws -> URL {
        var filename = url.deletingPathExtension().lastPathComponent.appending("-thumbnail")
        if let preferredSize = options.preferredSizeAtScale {
            filename.append("(\(Int(preferredSize.width))x\(Int(preferredSize.height)))")
        }
        // Get a new URL for the file as a thumbnail within the cache.
        return try MediaLibrary.makeLocalMediaURL(withFilename: filename,
                                                  fileExtension: url.pathExtension,
                                                  type: mediaDirectoryType)
    }

    /// Renames and moves an exported thumbnail to the expected directory with the expected thumbnail filenaming convention.
    ///
    fileprivate func exportImageToThumbnailCache(_ export: MediaImageExport, onCompletion: OnThumbnailExport, onError: OnExportError) {
        do {
            let thumbnailURL = try thumbnailURLWithOptions(for: export.url)
            let fileManager = FileManager.default
            // Move the exported file at the url to the new URL.
            try fileManager.moveItem(at: export.url, to: thumbnailURL)
            // Configure with the new URL
            let thumbnailExport = MediaImageExport(url: thumbnailURL,
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
