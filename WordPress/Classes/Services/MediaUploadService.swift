import Foundation
import WordPressData
import WordPressCore
import WordPressAPI
import WordPressAPIInternal
import UniformTypeIdentifiers

protocol MediaUploadServiceEventObserver: Sendable {
    func handle(event: MediaUploadService.Event, asset: ExportableAsset, service: MediaUploadService)
}

actor MediaUploadService {
    enum Event: Sendable {
        case overallProgress(Progress)
        case thumbnail(URL)
    }

    nonisolated static let progressUserInfoKeyThumbnail = ProgressUserInfoKey(rawValue: "MediaUploadService.thumbnail")

    private let coreDataStack: CoreDataStackSwift
    private let blog: TaggedManagedObjectID<Blog>
    private let client: WordPressClient

    init(coreDataStack: CoreDataStackSwift, blog: TaggedManagedObjectID<Blog>, client: WordPressClient) {
        self.coreDataStack = coreDataStack
        self.blog = blog
        self.client = client
    }

    /// Uploads an asset to the site media library.
    ///
    /// - Parameters:
    ///   - asset: The asset to upload.
    ///   - progress: A progress object to track the upload progress.
    /// - Returns: The saved Media instance.
    func uploadToMediaLibrary(asset: ExportableAsset, observer: MediaUploadServiceEventObserver) async throws -> TaggedManagedObjectID<Media> {
        let overallProgress = Progress.discreteProgress(totalUnitCount: 100)
        overallProgress.completedUnitCount = 0

        await MainActor.run {
            observer.handle(event: .overallProgress(overallProgress), asset: asset, service: self)
        }

        let export = try await exportAsset(asset, parentProgress: overallProgress, withPendingUnitCount: 10)

        try Task.checkCancellation()

        if let thumbnail = await thumbnail(of: export) {
            await MainActor.run {
                observer.handle(event: .thumbnail(thumbnail), asset: asset, service: self)
            }
        }

        let uploadingProgress = Progress.discreteProgress(totalUnitCount: 100)
        overallProgress.addChild(uploadingProgress, withPendingUnitCount: 90)

        let uploaded = try await withTaskCancellationHandler {
            try await client.api.uploadMedia(
                params: MediaCreateParams(from: export),
                fromLocalFileURL: export.url,
                fulfilling: uploadingProgress
            ).data
        } onCancel: {
            uploadingProgress.cancel()
        }

        try Task.checkCancellation()

        let media = try await coreDataStack.performAndSave { [blogID = blog] context in
            let blog = try context.existingObject(with: blogID)
            let media = Media.existingMediaWith(mediaID: .init(value: uploaded.id), inBlog: blog)
                ?? Media.makeMedia(blog: blog)

            self.configureMedia(media, withExport: export)
            self.updateMedia(media, with: uploaded)

            return TaggedManagedObjectID(media)
        }

        overallProgress.completedUnitCount = overallProgress.totalUnitCount
        return media
    }
}

// MARK: - Export

private extension MediaUploadService {

    func exportAsset(_ exportable: ExportableAsset, parentProgress: Progress, withPendingUnitCount unitCount: Int64) async throws -> MediaExport {
        let options = try await coreDataStack.performQuery { [blogID = blog] context in
            let blog = try context.existingObject(with: blogID)
            let allowableFileExtensions = blog.allowedFileTypes as? Set<String> ?? []
            return self.makeExportOptions(for: blog, allowableFileExtensions: allowableFileExtensions)
        }

        guard let exporter = self.makeExporter(for: exportable, options: options) else {
            preconditionFailure("No exporter found for \(exportable)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let progress = exporter.export(
                onCompletion: { export in
                    continuation.resume(returning: export)
                },
                onError: { error in
                    DDLogError("Error occurred exporting asset: \(error)")
                    continuation.resume(throwing: error)
                }
            )
            // The "export" part covers the initial 10% of the overall progress.
            parentProgress.addChild(progress, withPendingUnitCount: unitCount)
        }
    }

    func makeExporter(for exportable: ExportableAsset, options: ExportOptions) -> MediaExporter? {
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

    func configureMedia(_ media: Media, withExport export: MediaExport) {
        media.absoluteLocalURL = export.url
        media.filename = export.filename ?? export.url.lastPathComponent
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

    struct ExportOptions {
        var imageOptions: MediaImageExporter.Options
        var videoOptions: MediaVideoExporter.Options
        var urlOptions: MediaURLExporter.Options
        var allowableFileExtensions: Set<String>
    }

    func makeExportOptions(for blog: Blog, allowableFileExtensions: Set<String>) -> ExportOptions {
        ExportOptions(imageOptions: exporterImageOptions,
                      videoOptions: makeExporterVideoOptions(for: blog),
                      urlOptions: exporterURLOptions(allowableFileExtensions: allowableFileExtensions),
                      allowableFileExtensions: allowableFileExtensions)
    }

    var exporterImageOptions: MediaImageExporter.Options {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = self.exporterMaximumImageSize()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.imageCompressionQuality = MediaSettings().imageQualityForUpload.doubleValue
        return options
    }

    func makeExporterVideoOptions(for blog: Blog) -> MediaVideoExporter.Options {
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.exportPreset = MediaSettings().maxVideoSizeSetting.videoPreset
        options.durationLimit = blog.videoDurationLimit
        return options
    }

    func exporterURLOptions(allowableFileExtensions: Set<String>) -> MediaURLExporter.Options {
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
    func exporterMaximumImageSize() -> CGFloat? {
        let maxUploadSize = MediaSettings().imageSizeForUpload
        if maxUploadSize < Int.max {
            return CGFloat(maxUploadSize)
        }
        return nil
    }

    func thumbnail(of exported: MediaExport) async -> URL? {
        let exporter = MediaThumbnailExporter()
        exporter.mediaDirectoryType = .cache
        exporter.options.preferredSize = await MediaImageService.getThumbnailSize(for: exported.size ?? CGSizeMake(100, 100), size: .small)
        exporter.options.scale = 1 // In pixels

        if exported.url.isGif {
            exporter.options.thumbnailImageType = UTType.gif.identifier
        }

        guard exporter.supportsThumbnailExport(forFile: exported.url),
              let (_, thumbnail) = try? await exporter.exportThumbnail(forFileURL: exported.url)
        else {
            return nil
        }

        return thumbnail.url
    }

    func updateMedia(_ media: Media, with remote: MediaWithEditContext) {
        media.mediaID = NSNumber(value: remote.id)
        media.remoteURL = remote.sourceUrl
        media.creationDate = remote.dateGmt
        media.postID = remote.postId.map { NSNumber(value: $0) }
        media.title = remote.title.raw
        media.caption = remote.caption.raw
        media.desc = remote.description.raw
        media.alt = remote.altText

        if let url = URL(string: remote.sourceUrl) {
            media.filename = url.lastPathComponent
            media.setMediaType(forFilenameExtension: url.pathExtension)
        }

        if case let .object(mediaDetails) = remote.mediaDetails {
            if case let .int(width) = mediaDetails["width"] {
                media.width = NSNumber(value: width)
            }
            if case let .int(height) = mediaDetails["height"] {
                media.height = NSNumber(value: height)
            }
            if case let .int(length) = mediaDetails["length"] {
                media.length = NSNumber(value: length)
            }
            if case let .string(file) = mediaDetails["file"] {
                media.filename = file
            }

            // Extract different sizes
            if case let .object(sizes) = mediaDetails["sizes"] {
                if case let .object(medium) = sizes["medium"],
                   case let .string(url) = medium["source_url"] {
                    media.remoteMediumURL = url
                }
                if case let .object(large) = sizes["large"],
                   case let .string(url) = large["source_url"] {
                    media.remoteLargeURL = url
                }
                if case let .object(thumbnail) = sizes["thumbnail"],
                   case let .string(url) = thumbnail["source_url"] {
                    media.remoteThumbnailURL = url
                }
            }
        }

        media.remoteStatus = .sync
        media.error = nil
    }
}

private extension MediaCreateParams {
    init(from export: MediaExport) {
        self.init(
            date: nil,
            dateGmt: nil,
            slug: nil,
            status: nil,
            title: export.filename ?? export.url.lastPathComponent,
            author: nil,
            commentStatus: nil,
            pingStatus: nil,
            template: nil,
            altText: nil,
            caption: export.caption,
            description: nil,
            postId: nil
        )
    }
}
