import Foundation
import CocoaLumberjack

/// Encapsulates importing assets such as PHAssets, images, videos, or files at URLs to Media objects.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContext
///   method and its corresponding thread.
///
open class MediaImportService: LocalCoreDataService {

    private static let defaultImportQueue: DispatchQueue = DispatchQueue(label: "org.wordpress.mediaImportService", autoreleaseFrequency: .workItem)

    @objc public lazy var importQueue: DispatchQueue = {
        return MediaImportService.defaultImportQueue
    }()

    /// Constant for the ideal compression quality used when images are added to the Media Library.
    ///
    /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
    ///
    @objc static let preferredImageCompressionQuality = 0.9

    /// Completion handler for a created Media object.
    ///
    public typealias MediaCompletion = (Media) -> Void

    /// Error handler.
    ///
    public typealias OnError = (Error) -> Void

    // MARK: - Instance methods

    /// Imports media from a PHAsset to the Media object, asynchronously.
    ///
    /// - parameter exportable: the exportable resource where data will be read from.
    /// - parameter media: the media object to where media will be imported to.
    /// - parameter onCompletion: Called if the Media was successfully created and the asset's data imported to the absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    @objc(importResource:toMedia:onCompletion:onError:)
    public func `import`(_ exportable: ExportableAsset, to media: Media, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        importQueue.async {
            switch exportable {
                case let asset as PHAsset:
                    self.`import`(asset, to: media, onCompletion: onCompletion, onError: onError)
                case let image as UIImage:
                    self.`import`(image, to: media, onCompletion: onCompletion, onError: onError)
                case let url as URL:
                    self.`import`(url, to: media, onCompletion: onCompletion, onError: onError)
                default:
                    onError(NSError())
            }
        }
    }

    /// Imports media from a PHAsset to the Media object, asynchronously.
    ///
    /// - parameter asset: the PHAsset media where data will be read from.
    /// - parameter media: the media object to where media will be imported to.
    /// - parameter onCompletion: Called if the Media was successfully created and the asset's data imported to the absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    @objc(importAsset:toMedia:onCompletion:onError:)
    private func `import`(_ asset: PHAsset, to media: Media, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        let exporter = MediaAssetExporter()
        exporter.imageOptions = self.exporterImageOptions
        exporter.videoOptions = self.exporterVideoOptions

        exporter.exportData(forAsset: asset, onCompletion: { (assetExport) in
            self.managedObjectContext.perform {
                self.configureMedia(media, withExport: assetExport)
                ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                    onCompletion(media)
                })
            }
        }, onError: { (error) in
            self.handleExportError(error, errorHandler: onError)
        })
    }

    /// Imports media from a UIImage to the Media object, asynchronously.
    ///
    /// The UIImage is expected to be a JPEG, PNG, or other 'normal' image.
    ///
    /// - parameter image: the UIImage where data will be read from.
    /// - parameter media: the media object to where media will be imported to.
    /// - parameter onCompletion: Called if the Media was successfully created and the image's data imported to the absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    @objc(importImage:toMedia:onCompletion:onError:)
    private func `import`(_ image: UIImage, to media: Media, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        let exporter = MediaImageExporter()
        exporter.options = self.exporterImageOptions

        exporter.exportImage(image, fileName: nil, onCompletion: { (imageExport) in
            self.managedObjectContext.perform {
                self.configureMedia(media, withExport: imageExport)
                ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                    onCompletion(media)
                })
            }
        }, onError: { (error) in
            self.handleExportError(error, errorHandler: onError)
        })
    }

    /// Imports media from a URL to the Media object, asynchronously.
    ///
    /// The file URL is expected to be a JPEG, PNG, GIF, other 'normal' image, or video.
    ///
    /// - parameter url: the URL from where data will be read from.
    /// - parameter media: the media object to where media will be imported to.
    /// - parameter onCompletion: Called if the Media was successfully created and the file's data imported to the absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    @objc(importURL:toMedia:onCompletion:onError:)
    private func `import`(_ url: URL, to media: Media, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        let exporter = MediaURLExporter()
        exporter.imageOptions = self.exporterImageOptions
        exporter.videoOptions = self.exporterVideoOptions

        exporter.exportURL(fileURL: url, onCompletion: { (urlExport) in
            self.managedObjectContext.perform {
                self.configureMedia(media, withExport: urlExport)
                ContextManager.sharedInstance().save(self.managedObjectContext, withCompletionBlock: {
                    onCompletion(media)
                })
            }
        }, onError: { (error) in
            self.handleExportError(error, errorHandler: onError)
        })
    }

    // MARK: - Helpers

    class func logExportError(_ error: MediaExportError) {
        // Write an error logging message to help track specific sources of export errors.
        var errorLogMessage = "Error occurred importing to Media"
        switch error {
        case is MediaAssetExporter.AssetExportError:
            errorLogMessage.append(" with asset export error")
        case is MediaImageExporter.ImageExportError:
            errorLogMessage.append(" with image export error")
        case is MediaURLExporter.URLExportError:
            errorLogMessage.append(" with URL export error")
        case is MediaThumbnailExporter.ThumbnailExportError:
            errorLogMessage.append(" with thumbnail export error")
        case is MediaExportSystemError:
            errorLogMessage.append(" with system error")
        default:
            errorLogMessage = " with unknown error"
        }
        let nerror = error.toNSError()
        DDLogError("\(errorLogMessage), code: \(nerror.code), error: \(nerror)")
    }

    /// Handle the OnError callback and logging any errors encountered.
    ///
    fileprivate func handleExportError(_ error: MediaExportError, errorHandler: OnError?) {
        MediaImportService.logExportError(error)
        // Return the error via the context's queue, and as an NSError to ensure it carries over the right code/message.
        if let errorHandler = errorHandler {
            self.managedObjectContext.perform {
                errorHandler(error.toNSError())
            }
        }
    }

    // MARK: - Media export configurations

    fileprivate var exporterImageOptions: MediaImageExporter.Options {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = self.exporterMaximumImageSize()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.imageCompressionQuality = MediaImportService.preferredImageCompressionQuality
        return options
    }

    fileprivate var exporterVideoOptions: MediaVideoExporter.Options {
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.exportPreset = MediaSettings().maxVideoSizeSetting.videoPreset
        return options
    }

    /// Helper method to return an optional value for a valid MediaSettings max image upload size.
    ///
    /// - Note: Eventually we'll rewrite MediaSettings.imageSizeForUpload to do this for us, but want to leave
    ///   that class alone while implementing MediaExportService.
    ///
    fileprivate func exporterMaximumImageSize() -> CGFloat? {
        let maxUploadSize = MediaSettings().imageSizeForUpload
        if maxUploadSize < Int.max {
            return CGFloat(maxUploadSize)
        }
        return nil
    }

    /// Configure Media with the AssetExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaAssetExporter.AssetExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the URLExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaURLExporter.URLExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the ImageExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaImageExport) {
        if let width = export.width {
            media.width = width as NSNumber
        }
        if let height = export.height {
            media.height = height as NSNumber
        }
        media.mediaType = .image
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media with the VideoExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaVideoExport) {
        if let duration = export.duration {
            media.length = duration as NSNumber
        }
        media.mediaType = .video
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media with the GIFExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaGIFExport) {
        media.mediaType = .image
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media via the general Export protocol.
    ///
    fileprivate func configureMedia(_ media: Media, withFileExport export: MediaExport) {
        if let fileSize = export.fileSize {
            media.filesize = fileSize as NSNumber
        }
        media.absoluteLocalURL = export.url
        media.filename = export.url.lastPathComponent
    }
}
