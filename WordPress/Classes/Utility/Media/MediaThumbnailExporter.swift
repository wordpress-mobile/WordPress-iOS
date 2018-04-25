import Foundation
import MobileCoreServices

/// Media export handling of thumbnail images from videos or images.
///
class MediaThumbnailExporter: MediaExporter {

    /// Directory type for the ThumbnailExporter, defaults to the .cache directory.
    ///
    var mediaDirectoryType: MediaDirectory = .cache

    // MARK: Export Options

    var options = Options()

    /// Available options for an thumbnail export.
    ///
    struct Options {

        /// The preferred size of the image, in points, typically for the actual display
        /// of the image within a layout's dimensions. If nil, the image will not be resized.
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

        /// The compression quality of the thumbnail, if the image type supports compression.
        ///
        var compressionQuality = 0.90

        /// The target image type of the exported thumbnail images.
        ///
        /// - Note: Passed on to the MediaImageExporter.Options.exportImageType.
        ///
        var thumbnailImageType = kUTTypeJPEG as String

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

        lazy var identifier: String = {
           return UUID().uuidString
        }()
    }

    // MARK: - Types

    /// A generated thumbnail identifier representing a reference to the image files that
    /// result from a thumbnail export. This ensures unique files are created and URLs
    /// can be recreated as needed, relative to both the identifier and the configured
    /// options for an exporter.
    ///
    /// - Note: Media objects should store or cache these identifiers in order to reuse
    ///   previously exported Media files that match the given identifier and configured options.
    ///
    typealias ThumbnailIdentifier = String

    /// Completion block with the generated thumbnail identifier and resulting image export.
    ///
    typealias OnThumbnailExport = (ThumbnailIdentifier, MediaExport) -> Void

    /// Errors specific to exporting thumbnails.
    ///
    public enum ThumbnailExportError: MediaExportError {
        case failedToGenerateThumbnailFileURL
        case unsupportedThumbnailFromOriginalType
        var description: String {
            switch self {
            default:
                return NSLocalizedString("Thumbnail unavailable.", comment: "Message shown if a thumbnail preview of a media item unavailable.")
            }
        }
    }

    // MARK: - Public

    /// The available file URL of a thumbnail, if it exists, relative to the identifier
    /// and exporter's configured options.
    ///
    /// - Note: Consider using this URL for cacheing exported images located at the URL.
    ///
    func availableThumbnail(with identifier: ThumbnailIdentifier) -> URL? {
        guard let thumbnail = try? thumbnailURL(withIdentifier: identifier) else {
            return nil
        }
        guard let type = thumbnail.typeIdentifier, UTTypeConformsTo(type as CFString, options.thumbnailImageType as CFString) else {
            return nil
        }
        return thumbnail
    }

    /// Check for whether or not a file URL supports a thumbnail export.
    ///
    func supportsThumbnailExport(forFile url: URL) -> Bool {
        do {
            let expected = try MediaURLExporter.expectedExport(with: url)
            switch expected {
            case .image, .video, .gif:
                return true
            case .other:
                return false
            }
        } catch {
            return false
        }
    }

    let url: URL?

    init(url: URL? = nil) {
        self.url = url
    }

    public func export(onCompletion: @escaping OnMediaExport, onError: @escaping OnExportError) -> Progress {
        guard let fileURL = url else {
            onError(exporterErrorWith(error: ThumbnailExportError.failedToGenerateThumbnailFileURL))
            return Progress.discreteCompletedProgress()
        }
        return exportThumbnail(forFile: fileURL, onCompletion: { (identifier, export) in
            onCompletion(export)
        }, onError: onError)
    }

    /// Export a thumbnail image for a file at the URL, with an expected type of an image or video.
    ///
    /// - Note: GIFs are currently unsupported and throw the .gifThumbnailsUnsupported error.
    ///
    @discardableResult func exportThumbnail(forFile url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) -> Progress {
        do {
            let expected = try MediaURLExporter.expectedExport(with: url)
            switch expected {
            case .image, .gif:
                return exportImageThumbnail(at: url, onCompletion: onCompletion, onError: onError)
            case .video:
                return exportVideoThumbnail(at: url, onCompletion: onCompletion, onError: onError)
            case .other:
                return Progress.discreteCompletedProgress()
            }
        } catch {
            onError(exporterErrorWith(error: error))
            return Progress.discreteCompletedProgress()
        }
    }

    /// Export an existing image as a thumbnail image, based on the exporter options.
    ///
    @discardableResult func exportThumbnail(forImage image: UIImage, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) -> Progress {
        let exporter = MediaImageExporter(image: image, filename: UUID().uuidString)
        exporter.mediaDirectoryType = .temporary
        exporter.options = imageExporterOptions
        return exporter.export(onCompletion: { (export) in
                                self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        }, onError: onError)
    }

    /// Export a known video at the URL, being either a file URL or a remote URL.
    ///
    @discardableResult func exportThumbnail(forVideoURL url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) -> Progress {
        if url.isFileURL {
            return exportThumbnail(forFile: url, onCompletion: onCompletion, onError: onError)
        } else {
            return exportVideoThumbnail(at: url, onCompletion: onCompletion, onError: onError)
        }
    }

    // MARK: - Private

    /// Export a thumbnail for a known image at the URL, using self.options for ImageExporter options.
    ///
    @discardableResult fileprivate func exportImageThumbnail(at url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) -> Progress {
        let exporter = MediaImageExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        exporter.options = imageExporterOptions
        return exporter.export(onCompletion: { (export) in
            self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        },
                        onError: onError)
    }

    /// Export a thumbnail for a known video at the URL, using self.options for ImageExporter options.
    ///
    @discardableResult fileprivate func exportVideoThumbnail(at url: URL, onCompletion: @escaping OnThumbnailExport, onError: @escaping OnExportError) -> Progress {
        let exporter = MediaVideoExporter(url: url)
        exporter.mediaDirectoryType = .temporary
        return exporter.exportPreviewImageForVideo(atURL: url,
                                            imageOptions: imageExporterOptions,
                                            onCompletion: { (export) in
                                                self.exportImageToThumbnailCache(export, onCompletion: onCompletion, onError: onError)
        },
                                            onError: onError)
    }

    /// The default options to use for exporting images based on the thumbnail exporter's options.
    ///
    fileprivate var imageExporterOptions: MediaImageExporter.Options {
        var imageOptions = MediaImageExporter.Options()
        if let maximumSize = options.preferredMaximumSizeAtScale {
            imageOptions.maximumImageSize = maximumSize
        }
        imageOptions.imageCompressionQuality = options.compressionQuality
        imageOptions.exportImageType = options.thumbnailImageType
        return imageOptions
    }

    /// A thumbnail URL written with the corresponding identifier and configured export options.
    ///
    fileprivate func thumbnailURL(withIdentifier identifier: ThumbnailIdentifier) throws -> URL {
        var filename = "thumbnail-\(identifier)"
        if let preferredSize = options.preferredSizeAtScale {
            filename.append("-\(Int(preferredSize.width))x\(Int(preferredSize.height))")
        }
        // Get a new URL for the file as a thumbnail within the cache.
        return try mediaFileManager.makeLocalMediaURL(withFilename: filename,
                                                        fileExtension: URL.fileExtensionForUTType(options.thumbnailImageType),
                                                        incremented: false)
    }

    /// Renames and moves an exported thumbnail to the expected directory with the expected thumbnail filenaming convention.
    ///
    fileprivate func exportImageToThumbnailCache(_ export: MediaExport, onCompletion: OnThumbnailExport, onError: OnExportError) {
        do {
            // Generate a unique ID
            let identifier = options.identifier
            let thumbnail = try thumbnailURL(withIdentifier: identifier)
            let fileManager = FileManager.default
            // Move the exported file at the url to the new URL.
            try? fileManager.removeItem(at: thumbnail)
            try fileManager.moveItem(at: export.url, to: thumbnail)
            // Configure with the new URL
            let thumbnailExport = MediaExport(url: thumbnail,
                                                   fileSize: export.fileSize,
                                                   width: export.width,
                                                   height: export.height,
                                                   duration: nil)
            // And return.
            onCompletion(identifier, thumbnailExport)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }
}
