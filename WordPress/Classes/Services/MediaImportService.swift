import Foundation
import CocoaLumberjack
import PhotosUI

/// Encapsulates importing assets such as images, videos, or files at URLs to Media objects.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContext
///   method and its corresponding thread.
///
class MediaImportService: NSObject {

    private static let defaultImportQueue: DispatchQueue = DispatchQueue(label: "org.wordpress.mediaImportService", autoreleaseFrequency: .workItem)

    @objc lazy var importQueue: DispatchQueue = {
        return MediaImportService.defaultImportQueue
    }()

    /// Constant for the ideal compression quality used when images are added to the Media Library.
    ///
    /// - Note: This value may or may not be honored, depending on the export implementation and underlying data.
    ///
    @objc static let preferredImageCompressionQuality = 0.9

    static let defaultAllowableFileExtensions = Set<String>(["docx", "ppt", "mp4", "ppsx", "3g2", "mpg", "ogv", "pptx", "xlsx", "jpeg", "xls", "mov", "key", "3gp", "png", "avi", "doc", "pdf", "gif", "odt", "pps", "m4v", "wmv", "jpg"])

    /// Completion handler for a created Media object.
    ///
    typealias MediaCompletion = (Media) -> Void

    /// Error handler.
    ///
    typealias OnError = (Error) -> Void

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

    /// Create a media object using the `ExportableAsset` provided as the source of media.
    ///
    /// - Note: All blocks arguments are called from the main thread. The `Media` argument in the blocks is bound to
    ///     the main context.
    ///
    /// - Warning: This function must be called from the main thread.
    ///
    /// This functions returns a `Media` instance. To ensure the returned `Media` instance continues to be a valid
    /// instance, it can't be bound to a background context which are all temporary context. The only long living
    /// context is the main context. And the safe way to create and return an object bound to the main context is
    /// doing it from the main thread, which is why this function must be called from the main thread.
    ///
    /// - Parameters:
    ///   - exportable: an object that conforms to `ExportableAsset`
    ///   - blog: the blog object to associate to the media
    ///   - post: the optional post object to associate to the media
    ///   - thumbnailCallback: a closure that will be invoked when the thumbnail for the media object is ready
    ///   - completion: a closure that will be invoked when the media is created, on success it will return a valid `Media`
    ///         object, on failure it will return a `nil` `Media` and an error object with the details.
    ///
    /// - Returns: The new `Media` instance and a `Process` instance that tracks the progress of the export process
    ///
    /// - SeeAlso: `createMedia(with:blog:post:thumbnailCallback:completion:)`
    func createMedia(
        with exportable: ExportableAsset,
        blog: Blog,
        post: AbstractPost?,
        thumbnailCallback: ((Media, URL) -> Void)?,
        completion: @escaping (Media?, Error?) -> Void
    ) -> (Media, Progress)? {
        assert(Thread.isMainThread, "\(#function) can only be called from the main thread")

        let blogObjectID = TaggedManagedObjectID(blog)
        let postObjectID = post.map { TaggedManagedObjectID($0) }
        guard let media = try? createMedia(with: exportable, blogObjectID: blogObjectID, postObjectID: postObjectID, in: coreDataStack.mainContext) else {
            return nil
        }

        coreDataStack.saveContextAndWait(coreDataStack.mainContext)

        let blogInContext: Blog
        do {
            blogInContext = try coreDataStack.mainContext.existingObject(with: blog.objectID) as! Blog
        } catch {
            completion(nil, error)
            return nil
        }

        let createProgress = self.import(exportable, to: media, blog: blogInContext, thumbnailCallback: thumbnailCallback) {
            switch $0 {
            case let .success(media):
                completion(media, nil)
            case let .failure(error):
                completion(media, error)
            }
        }

        return (media, createProgress)
    }

    /// Create a media object using the `ExportableAsset` provided as the source of media.
    ///
    /// Unlike `createMedia(with:blog:post:thumbnailCallback:completion:)`, this function can be called from any thread.
    ///
    /// - Note: All blocks arguments are called from the main thread. The `Media` argument in the blocks is bound to
    ///     the main context.
    ///
    /// - Parameters:
    ///   - exportable: an object that conforms to `ExportableAsset`
    ///   - blog: the blog object to associate to the media
    ///   - post: the optional post object to associate to the media
    ///   - progress: a NSProgress that tracks the progress of the export process.
    ///   - receiveUpdate: a closure that will be invoked with the created `Media` instance.
    ///   - thumbnailCallback: a closure that will be invoked when the thumbnail for the media object is ready
    ///   - completion: a closure that will be invoked when the media is created, on success it will return a valid Media
    ///         object, on failure it will return a nil Media and an error object with the details.
    @objc
    @discardableResult
    func createMedia(
        with exportable: ExportableAsset,
        blog: Blog,
        post: AbstractPost?,
        receiveUpdate: ((Media) -> Void)?,
        thumbnailCallback: ((Media, URL) -> Void)?,
        completion: @escaping (Media?, Error?) -> Void
    ) -> Progress {
        let createProgress = Progress.discreteProgress(totalUnitCount: 1)
        let blogObjectID = TaggedManagedObjectID(blog)
        let postObjectID = post.map { TaggedManagedObjectID($0) }
        coreDataStack.performAndSave({ context in
            let media = try self.createMedia(with: exportable, blogObjectID: blogObjectID, postObjectID: postObjectID, in: context)
            try context.obtainPermanentIDs(for: [media])
            return media.objectID
        }, completion: { (result: Result<NSManagedObjectID, Error>) in
            let transformed = result.flatMap { mediaObjectID in
                Result {
                    (
                        try self.coreDataStack.mainContext.existingObject(with: mediaObjectID) as! Media,
                        try self.coreDataStack.mainContext.existingObject(with: blog.objectID) as! Blog
                    )
                }
            }
            switch transformed {
            case let .success((media, blog)):
                let progress = self.import(exportable, to: media, blog: blog, thumbnailCallback: thumbnailCallback) {
                    switch $0 {
                    case let .success(media):
                        completion(media, nil)
                    case let .failure(error):
                        completion(media, error)
                    }
                }
                createProgress.addChild(progress, withPendingUnitCount: 1)
                receiveUpdate?(media)
            case let .failure(error):
                completion(nil, error)
            }
        }, on: .main)
        return createProgress
    }

    private func createMedia(with exportable: ExportableAsset, blogObjectID: TaggedManagedObjectID<Blog>, postObjectID: TaggedManagedObjectID<AbstractPost>?, in context: NSManagedObjectContext) throws -> Media {
        let blogInContext = try context.existingObject(with: blogObjectID)
        let postInContext = try postObjectID.flatMap(context.existingObject(with:))

        let media = postInContext.flatMap(Media.makeMedia(post:)) ?? Media.makeMedia(blog: blogInContext)
        media.mediaType = exportable.assetMediaType
        media.remoteStatus = .processing
        return media
    }

    private func `import`(
        _ exportable: ExportableAsset,
        to media: Media,
        blog: Blog,
        thumbnailCallback: ((Media, URL) -> Void)?,
        completion: @escaping (Result<Media, Error>) -> Void
    ) -> Progress {
        assert(Thread.isMainThread)
        assert(media.managedObjectContext == coreDataStack.mainContext)
        assert(blog.managedObjectContext == coreDataStack.mainContext)

        var allowedFileTypes = blog.allowedFileTypes as? Set<String> ?? []
        // HEIC isn't supported when uploading an image, so we filter it out (http://git.io/JJAae)
        allowedFileTypes.remove("heic")

        let completion: (Error?) -> Void = { error in
            self.coreDataStack.performAndSave({ context in
                let mediaInContext = try context.existingObject(with: media.objectID) as! Media
                if let error {
                    mediaInContext.remoteStatus = .failed
                    mediaInContext.error = error
                } else {
                    mediaInContext.remoteStatus = .local
                    mediaInContext.error = nil
                }
            }, completion: { result in
                let transformed = result.flatMap {
                    Result {
                        try self.coreDataStack.mainContext.existingObject(with: media.objectID) as! Media
                    }
                }

                if case let .success(media) = transformed {
                    // Pre-generate a thumbnail image, see the method notes.
                    self.exportPlaceholderThumbnail(for: media) { url in
                        assert(Thread.isMainThread)
                        guard let url, let media = try? self.coreDataStack.mainContext.existingObject(with: media.objectID) as? Media else {
                            return
                        }
                        thumbnailCallback?(media, url)
                    }
                }
                if let error {
                    completion(.failure(error)) // Import failed
                } else {
                    completion(transformed)
                }
            }, on: .main)
        }

        let options = makeExportOptions(for: blog, allowableFileExtensions: allowedFileTypes)
        return self.import(exportable, to: media, options: options, completion: completion)
    }

    /// Imports media from exportable assets to the Media object, asynchronously.
    ///
    /// - Parameters:
    ///     - exportable: the exportable resource where data will be read from.
    ///     - media: the media object to where media will be imported to.
    ///     - onCompletion: Called if the Media was successfully created and the asset's data imported to the
    ///         `absoluteLocalURL`. This closure is called on the main thread. The closure's `media` argument is also
    ///         bound to the main context (`CoreDataStack.mainContext`).
    ///     - onError: Called if an error was encountered during creation, error convertible to `NSError` with a
    ///         localized description. This closure is called on the main thread.
    ///
    /// - Returns: a progress object that report the current state of the import process.
    ///
    private func `import`(_ exportable: ExportableAsset, to media: Media, options: ExportOptions, completion: @escaping (Error?) -> Void) -> Progress {
        let progress: Progress = Progress.discreteProgress(totalUnitCount: 1)
        importQueue.async {
            guard let exporter = self.makeExporter(for: exportable, options: options) else {
                preconditionFailure("An exporter needs to be availale")
            }
            let exportProgress = exporter.export(
                onCompletion: { export in
                    self.coreDataStack.performAndSave({ context in
                        let mediaInContext = try context.existingObject(with: media.objectID) as! Media
                        self.configureMedia(mediaInContext, withExport: export)
                    }, completion: { result in
                        if case let .failure(error) = result {
                            completion(error)
                        } else {
                            completion(nil)
                        }
                    }, on: .main)
                },
                onError: { error in
                    MediaImportService.logExportError(error)
                    // Return the error via the context's queue, and as an NSError to ensure it carries over the right code/message.
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            )
            progress.addChild(exportProgress, withPendingUnitCount: 1)
        }
        return progress
    }

    private func makeExporter(for exportable: ExportableAsset, options: ExportOptions) -> MediaExporter? {
        switch exportable {
        case let provider as NSItemProvider:
            let exporter = ItemProviderMediaExporter(provider: provider)
            exporter.imageOptions = options.imageOptions
            exporter.videoOptions = options.videoOptions
            return exporter
        case let image as UIImage:
            let exporter = MediaImageExporter(image: image, filename: nil)
            exporter.options = options.imageOptions
            return exporter
        case let url as URL:
            let exporter = MediaURLExporter(url: url)
            exporter.imageOptions = options.imageOptions
            exporter.videoOptions = options.videoOptions
            exporter.urlOptions = options.urlOptions
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

    /// Generate a thumbnail image for the `Media` so that consumers of the `absoluteThumbnailLocalURL` property
    /// will have an image ready to load, without using the async methods provided via `MediaThumbnailService`.
    ///
    /// This is primarily used as a placeholder image throughout the code-base, particulary within the editors.
    ///
    /// Note: Ideally we wouldn't need this at all, but the synchronous usage of `absoluteThumbnailLocalURL` across the code-base
    ///       to load a thumbnail image is relied on quite heavily. In the future, transitioning to asynchronous thumbnail loading
    ///       via the new thumbnail service methods is much preferred, but would indeed take a good bit of refactoring away from
    ///       using `absoluteThumbnailLocalURL`.
    func exportPlaceholderThumbnail(for media: Media, completion: ((URL?) -> Void)?) {
        MediaImageService.shared.getThumbnailURL(for: media) { url in
            self.coreDataStack.performAndSave({ context in
                let mediaInContext = try context.existingObject(with: media.objectID) as! Media
                // Set the absoluteThumbnailLocalURL with the generated thumbnail's URL.
                mediaInContext.absoluteThumbnailLocalURL = url
            }, completion: { _ in
                completion?(url)
            }, on: .main)
        }
    }

    // MARK: - Helpers

    class func logExportError(_ error: MediaExportError) {
        // Write an error logging message to help track specific sources of export errors.
        var errorLogMessage = "Error occurred importing to Media"
        switch error {
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

    private func makeExportOptions(for blog: Blog, allowableFileExtensions: Set<String>) -> ExportOptions {
        ExportOptions(imageOptions: exporterImageOptions,
                      videoOptions: makeExporterVideoOptions(for: blog),
                      urlOptions: exporterURLOptions(allowableFileExtensions: allowableFileExtensions),
                      allowableFileExtensions: allowableFileExtensions)
    }

    private struct ExportOptions {
        var imageOptions: MediaImageExporter.Options
        var videoOptions: MediaVideoExporter.Options
        var urlOptions: MediaURLExporter.Options
        var allowableFileExtensions: Set<String>
    }

    private var exporterImageOptions: MediaImageExporter.Options {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = self.exporterMaximumImageSize()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.imageCompressionQuality = MediaSettings().imageQualityForUpload.doubleValue
        return options
    }

    private func makeExporterVideoOptions(for blog: Blog) -> MediaVideoExporter.Options {
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.exportPreset = MediaSettings().maxVideoSizeSetting.videoPreset
        options.durationLimit = blog.videoDurationLimit
        return options
    }

    private func exporterURLOptions(allowableFileExtensions: Set<String>) -> MediaURLExporter.Options {
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
