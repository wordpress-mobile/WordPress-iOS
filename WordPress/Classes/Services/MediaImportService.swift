import Foundation
import CocoaLumberjack

/// Encapsulates importing assets such as PHAssets, images, videos, or files at URLs to Media objects.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContext
///   method and its corresponding thread.
///
open class MediaImportService: NSObject {

    private static let defaultImportQueue: DispatchQueue = DispatchQueue(label: "org.wordpress.mediaImportService", autoreleaseFrequency: .workItem)

    @objc public lazy var importQueue: DispatchQueue = {
        return MediaImportService.defaultImportQueue
    }()

    /// Constant for the ideal compression quality used when images are added to the Media Library.
    ///
    /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
    ///
    @objc static let preferredImageCompressionQuality = 0.9

    /// Allows the caller to designate supported import file types
    @objc var allowableFileExtensions = Set<String>()

    static let defaultAllowableFileExtensions = Set<String>(["docx", "ppt", "mp4", "ppsx", "3g2", "mpg", "ogv", "pptx", "xlsx", "jpeg", "xls", "mov", "key", "3gp", "png", "avi", "doc", "pdf", "gif", "odt", "pps", "m4v", "wmv", "jpg"])

    /// Completion handler for a created Media object.
    ///
    public typealias MediaCompletion = (Media) -> Void

    /// Error handler.
    ///
    public typealias OnError = (Error) -> Void

    private let coreDataStack: CoreDataStackSwift

    /// The initialiser for Objective-C code.
    ///
    /// Using `ContextManager` as the argument becuase `CoreDataStackSwift` is not accessible from Objective-C code.
    @objc
    convenience init(contextManager: ContextManager) {
        self.init(coreDataStack: contextManager)
    }

    init(coreDataStack: CoreDataStackSwift) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Instance methods

    /// Imports media from a PHAsset to the Media object, asynchronously.
    ///
    /// - Parameters:
    ///     - exportable: the exportable resource where data will be read from.
    ///     - media: the media object to where media will be imported to.
    ///     - onCompletion: Called if the Media was successfully created and the asset's data imported to the
    ///         absoluteLocalURL. This closure is called on the main thread. The closure's `media` argument is also
    ///         bound to the main context (`CoreDataStack.mainContext`).
    ///     - onError: Called if an error was encountered during creation, error convertible to NSError with a
    ///         localized description. This closure is called on the main thread.
    ///
    /// - Returns: a progress object that report the current state of the import process.
    ///
    @objc(importResource:toMedia:onCompletion:onError:)
    func `import`(_ exportable: ExportableAsset, to media: Media, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) -> Progress? {
        let progress: Progress = Progress.discreteProgress(totalUnitCount: 1)
        importQueue.async {
            guard let exporter = self.makeExporter(for: exportable) else {
                preconditionFailure("An exporter needs to be availale")
            }
            let exportProgress = exporter.export(
                onCompletion: { export in
                    self.coreDataStack.performAndSave({ context in
                        let mediaInContext = try context.existingObject(with: media.objectID) as! Media
                        self.configureMedia(mediaInContext, withExport: export)
                    }, completion: { result in
                        let transformed = result.flatMap {
                            Result {
                                try self.coreDataStack.mainContext.existingObject(with: media.objectID) as! Media
                            }
                        }
                        switch transformed {
                        case let .success(media):
                            onCompletion(media)
                        case let .failure(error):
                            onError(error)
                        }
                    }, on: .main)
                },
                onError: { error in
                    MediaImportService.logExportError(error)
                    // Return the error via the context's queue, and as an NSError to ensure it carries over the right code/message.
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
            )
            progress.addChild(exportProgress, withPendingUnitCount: 1)
        }
        return progress
    }

    private func makeExporter(for exportable: ExportableAsset) -> MediaExporter? {
        switch exportable {
        case let asset as PHAsset:
            let exporter = MediaAssetExporter(asset: asset)
            exporter.imageOptions = self.exporterImageOptions
            exporter.videoOptions = self.exporterVideoOptions
            exporter.allowableFileExtensions = allowableFileExtensions.isEmpty ? MediaImportService.defaultAllowableFileExtensions : allowableFileExtensions
            return exporter
        case let image as UIImage:
            let exporter = MediaImageExporter(image: image, filename: nil)
            exporter.options = self.exporterImageOptions
            return exporter
        case let url as URL:
            let exporter = MediaURLExporter(url: url)
            exporter.imageOptions = self.exporterImageOptions
            exporter.videoOptions = self.exporterVideoOptions
            exporter.urlOptions = self.exporterURLOptions
            return exporter
        case let stockPhotosMedia as StockPhotosMedia:
            let exporter = MediaExternalExporter(externalAsset: stockPhotosMedia)
            return exporter
        case let tenorMedia as TenorMedia:
            let exporter = MediaExternalExporter(externalAsset: tenorMedia)
            return exporter
        default:
            return nil
        }
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

    // MARK: - Media export configurations

    private var exporterImageOptions: MediaImageExporter.Options {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = self.exporterMaximumImageSize()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.imageCompressionQuality = MediaImportService.preferredImageCompressionQuality
        return options
    }

    private var exporterVideoOptions: MediaVideoExporter.Options {
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.exportPreset = MediaSettings().maxVideoSizeSetting.videoPreset
        return options
    }

    private var exporterURLOptions: MediaURLExporter.Options {
        var options = MediaURLExporter.Options()
        options.allowableFileExtensions = allowableFileExtensions
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        return options
    }

    /// Helper method to return an optional value for a valid MediaSettings max image upload size.
    ///
    /// - Note: Eventually we'll rewrite MediaSettings.imageSizeForUpload to do this for us, but want to leave
    ///   that class alone while implementing MediaExportService.
    ///
    private func exporterMaximumImageSize() -> CGFloat? {
        let maxUploadSize = MediaSettings().imageSizeForUpload
        if maxUploadSize < Int.max {
            return CGFloat(maxUploadSize)
        }
        return nil
    }

    /// Configure Media with a MediaExport.
    ///
    private func configureMedia(_ media: Media, withExport export: MediaExport) {
        media.absoluteLocalURL = export.url
        media.filename = export.url.lastPathComponent
        media.mediaType = (export.url as NSURL).assetMediaType

        if let fileSize = export.fileSize {
            media.filesize = fileSize as NSNumber
        }

        if let width = export.width {
            media.width = width as NSNumber
        }

        if let height = export.height {
            media.height = height as NSNumber
        }

        if let duration = export.duration {
            media.length = duration as NSNumber
        }

        if let caption = export.caption {
            media.caption = caption
        }
    }

}
