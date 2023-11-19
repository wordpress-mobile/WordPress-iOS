import UIKit
import CoreData

/// A service for retrieval and caching of thumbnails for ``Media`` objects.
final class MediaImageService {
    static let shared = MediaImageService()

    private let cache: MemoryCache
    private let coreDataStack: CoreDataStackSwift
    private let mediaFileManager: MediaFileManager
    private let downloader: ImageDownloader

    init(cache: MemoryCache = .shared,
         coreDataStack: CoreDataStackSwift = ContextManager.shared,
         mediaFileManager: MediaFileManager = MediaFileManager(directory: .cache),
         downloader: ImageDownloader = .shared) {
        self.cache = cache
        self.coreDataStack = coreDataStack
        self.mediaFileManager = mediaFileManager
        self.downloader = downloader
    }

    static func migrateCacheIfNeeded() {
        let didMigrateKey = "MediaImageService-didMigrateCacheKey"
        guard !UserDefaults.standard.bool(forKey: didMigrateKey) else {
            return
        }
        UserDefaults.standard.set(true, forKey: didMigrateKey)
        DispatchQueue.global(qos: .utility).async {
            MediaFileManager.clearAllMediaCacheFiles(onCompletion: nil, onError: nil)
        }
    }

    enum Error: Swift.Error {
        case unsupportedMediaType(_ type: MediaType)
        case unsupportedThumbnailSize(_ size: ImageSize)
        case missingImageURL
    }

    /// Returns an image for the given media asset.
    ///
    /// **Performance Characteristics**
    ///
    /// The returned images are decompressed (or bitmapped) and are ready to be
    /// displayed even during scrolling.
    ///
    /// The thumbnails (``ImageSize/small`` or ``ImageSize/medium``) don't take
    /// a lot of space or memory and are used often. The app often displays
    /// multiple thumbnails on the screen at the same time. This is why the
    /// thumbnails are stored in both disk and memory cache. The disk cache
    /// has no size or time limit.
    ///
    /// The original images (``ImageSize/original``) are rarely displayed by the
    /// app and you usually preview only one image at a time. The original images
    /// are _not_ stored in the memory cache as they may take up too much space.
    /// They are stored in a custom `URLCache` instance that automatically evicts
    /// images if it reaches the size limit.
    @MainActor
    func image(for media: Media, size: ImageSize) async throws -> UIImage {
        let media = try await getSafeMedia(for: media)
        switch size {
        case .small, .medium:
            return try await thumbnail(for: media, size: size)
        case .original:
            return try await originalImage(for: media)
        }
    }

    /// Returns a thread-safe media object and materializes a stub if needed.
    @MainActor
    private func getSafeMedia(for media: Media) async throws -> SafeMedia {
        guard media.remoteStatus != .stub else {
            guard let mediaID = media.mediaID else {
                throw URLError(.unknown) // This should never happen
            }
            let blogID = TaggedManagedObjectID(media.blog)
            return try await fetchStubMedia(for: mediaID, blogID: blogID)
        }
        return SafeMedia(media)
    }

    // MARK: - Media (Original)

    /// Returns a full-size image for the given media asset.
    ///
    /// The app rarely loads full-size images, and they make take a significant
    /// amount of space and memory, so they are cached only in `URLCache`.
    private func originalImage(for media: SafeMedia) async throws -> UIImage {
        guard media.mediaType == .image else {
            assertionFailure("Unsupported media type: \(media.mediaType)")
            throw Error.unsupportedMediaType(media.mediaType)
        }
        if let localURL = media.absoluteLocalURL,
           let image = try? await ImageDecoder.makeImage(from: localURL) {
            return image
        }
        if let info = await getFullsizeImageInfo(for: media) {
            let data = try await data(for: info, isCached: true)
            return try await ImageDecoder.makeImage(from: data)
        }
        // The media has no local or remote URL – should never happen
        throw Error.missingImageURL
    }

    private func getFullsizeImageInfo(for media: SafeMedia) async -> RemoteImageInfo? {
        guard let remoteURL = media.remoteURL.flatMap(URL.init) else {
            return nil
        }
        return try? await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: media.blogID)
            return RemoteImageInfo(imageURL: remoteURL, host: MediaHost(with: blog))
        }
    }

    // MARK: - Media (Thumbnails)

    private func thumbnail(for media: SafeMedia, size: ImageSize) async throws -> UIImage {
        guard media.mediaType == .image || media.mediaType == .video else {
            assertionFailure("Unsupported thubmnail media type: \(media.mediaType)")
            throw Error.unsupportedMediaType(media.mediaType)
        }
        guard size != .original else {
            assertionFailure("Unsupported thumbnail size: \(size)")
            throw Error.unsupportedThumbnailSize(size)
        }

        if let image = cache.getImage(forKey: makeCacheKey(for: media.mediaID, size: size)) {
            return image
        }
        let image = try await actuallyLoadThumbnail(for: media, size: size)
        cache.setImage(image, forKey: makeCacheKey(for: media.mediaID, size: size))
        return image
    }

    private func actuallyLoadThumbnail(for media: SafeMedia, size: ImageSize) async throws -> UIImage {
        if let image = await cachedThumbnail(for: media.mediaID, size: size) {
            return image
        }
        if let image = await localThumbnail(for: media, size: size) {
            return image
        }
        return try await remoteThumbnail(for: media, size: size)
    }

    // MARK: - Thumbnails (Memory Cache)

    /// Returns cached image for the given thumbnail.
    nonisolated func getCachedThumbnail(for mediaID: TaggedManagedObjectID<Media>, size: ImageSize = .small) -> UIImage? {
        cache.getImage(forKey: makeCacheKey(for: mediaID, size: size))
    }

    // MARK: - Thumbnails (Disk Cache)

    /// Returns a local thumbnail for the given media object (if available).
    private func cachedThumbnail(for mediaID: TaggedManagedObjectID<Media>, size: ImageSize) async -> UIImage? {
        guard let fileURL = getCachedThumbnailURL(for: mediaID, size: size) else { return nil }
        return try? await ImageDecoder.makeImage(from: fileURL)
    }

    private func getCachedThumbnailURL(for mediaID: TaggedManagedObjectID<Media>, size: ImageSize) -> URL? {
        let mediaID = mediaID.objectID.uriRepresentation().lastPathComponent
        return try? mediaFileManager.makeLocalMediaURL(
            withFilename: "\(mediaID)-\(size.rawValue)-thumbnail",
            fileExtension: nil, // We don't know ahead of time
            incremented: false
        )
    }

    // MARK: - Local Thumbnail

    /// Generates a thumbnail from a local asset and saves it in cache.
    private func localThumbnail(for media: SafeMedia, size: ImageSize) async -> UIImage? {
        guard let sourceURL = media.absoluteLocalURL else {
            return nil
        }

        let exporter = await makeThumbnailExporter(for: media, size: size)
        guard exporter.supportsThumbnailExport(forFile: sourceURL),
              let (_, export) = try? await exporter.exportThumbnail(forFileURL: sourceURL),
              let image = try? await ImageDecoder.makeImage(from: export.url)
        else {
            return nil
        }

        // The order is important to ensure `export.url` still exists when creating an image
        if let thumbnailURL = getCachedThumbnailURL(for: media.mediaID, size: size) {
            try? FileManager.default.moveItem(at: export.url, to: thumbnailURL)
        }

        return image
    }

    @MainActor
    private func makeThumbnailExporter(for media: SafeMedia, size: ImageSize) -> MediaThumbnailExporter {
        let exporter = MediaThumbnailExporter()
        exporter.mediaDirectoryType = .cache
        exporter.options.preferredSize = MediaImageService.getThumbnailSize(for: media, size: size)
        exporter.options.scale = 1 // In pixels
        return exporter
    }

    // MARK: - Remote Thumbnail

    /// Downloads a remote thumbnail and saves it in cache.
    private func remoteThumbnail(for media: SafeMedia, size: ImageSize) async throws -> UIImage {
        guard let info = await getRemoteThumbnailInfo(for: media, size: size) else {
            // Self-hosted WordPress sites don't have `remoteThumbnailURL`, so
            // the app generates the thumbnail by itself.
            if media.mediaType == .video {
                return try await generateThumbnailForVideo(for: media, size: size)
            }
            throw URLError(.badURL)
        }
        let data = try await data(for: info, isCached: false)
        let image = try await ImageDecoder.makeImage(from: data)
        if let fileURL = getCachedThumbnailURL(for: media.mediaID, size: size) {
            try? data.write(to: fileURL)
        }
        return image
    }

    // There are two reasons why these operations are performed in the background:
    // performance and making sure the subsystem is thread-safe and can be used
    // from the background.
    private func getRemoteThumbnailInfo(for media: SafeMedia, size: ImageSize) async -> RemoteImageInfo? {
        let targetSize = await MediaImageService.getThumbnailSize(for: media, size: size)
        return try? await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: media.blogID)
            guard let imageURL = media.getRemoteThumbnailURL(targetSize: targetSize, blog: blog) else { return nil }
            return RemoteImageInfo(imageURL: imageURL, host: MediaHost(with: blog))
        }
    }

    // MARK: - Networking

    private func data(for info: RemoteImageInfo, isCached: Bool) async throws -> Data {
        let options = ImageRequestOptions(isDiskCacheEnabled: isCached)
        return try await downloader.data(from: info.imageURL, host: info.host, options: options)
    }

    private struct RemoteImageInfo {
        let imageURL: URL
        let host: MediaHost
    }

    // MARK: - Thubmnail for Video

    private func generateThumbnailForVideo(for media: SafeMedia, size: ImageSize) async throws -> UIImage {
        guard let videoURL = media.remoteURL.flatMap(URL.init) else {
            throw URLError(.badURL)
        }
        let exporter = await makeThumbnailExporter(for: media, size: size)
        let (_, export) = try await exporter.exportThumbnail(forVideoURL: videoURL)
        let image = try await ImageDecoder.makeImage(from: export.url)

        // The order is important to ensure `export.url` exists when making an image
        if let fileURL = getCachedThumbnailURL(for: media.mediaID, size: size) {
            try? FileManager.default.moveItem(at: export.url, to: fileURL)
        }
        return image
    }

    // MARK: - Stubs

    private func fetchStubMedia(for mediaID: NSNumber, blogID: TaggedManagedObjectID<Blog>) async throws -> SafeMedia {
        let mediaRepository = MediaRepository(coreDataStack: coreDataStack)
        let objectID = try await mediaRepository.getMedia(withID: mediaID, in: blogID)
        return try await coreDataStack.performQuery { context in
            let media = try context.existingObject(with: objectID)
            return SafeMedia(media)
        }
    }
}

// MARK: - MediaImageService (ThumbnailSize)

extension MediaImageService {

    enum ImageSize: String {
        /// The small thumbnail that can be used in collection view cells and
        /// similar situations.
        case small

        /// A medium thumbnail thumbnail that can typically be used to fit
        /// the entire screen on iPhone or a large portion of the sreen on iPad.
        case medium

        /// Loads an original image.
        case original
    }

    @MainActor
    fileprivate static func getThumbnailSize(for media: SafeMedia, size: ImageSize) -> CGSize {
        let mediaSize = media.size ?? CGSize(width: 1024, height: 1024) // rhs should never happen
        return MediaImageService.getThumbnailSize(for: mediaSize, size: size)

    }

    /// Returns an optimal target size in pixels for a thumbnail of the given
    /// size for the given media asset.
    @MainActor
    static func getThumbnailSize(for mediaSize: CGSize, size: ImageSize) -> CGSize {
        let targetSize = MediaImageService.getPreferredThumbnailSize(for: size)
        return MediaImageService.targetSize(forMediaSize: mediaSize, targetSize: targetSize)
    }

    /// Returns a preferred thumbnail size (in pixels) optimized for the device.
    ///
    /// - important: It makes sure the app uses the same thumbnails across
    /// different screens and presentation modes to avoid fetching and caching
    /// more than one version of the same image.
    @MainActor
    private static func getPreferredThumbnailSize(for thumbnail: ImageSize) -> CGSize {
        let minScreenSide = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        switch thumbnail {
        case .small:
            /// The size is calculated to fill a collection view cell, assuming the app
            /// displays a 4 or 5 cells in one row. The cell size can vary depending
            /// on whether the device is in landscape or portrait mode, but the thumbnail size is
            /// guaranteed to always be the same across app launches and optimized for
            /// a portraint (dominant) mode.
            let itemPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 4
            let availableWidth = minScreenSide - SiteMediaCollectionViewController.spacing * CGFloat(itemPerRow - 1)
            let targetSide = (availableWidth / CGFloat(itemPerRow)).rounded(.down)
            let targetSize = CGSize(width: targetSide, height: targetSide)
            return targetSize.scaled(by: UIScreen.main.scale)
        case .medium:
            let side = min(1024, minScreenSide * UIScreen.main.scale)
            return CGSize(width: side, height: side)
        case .original:
            assertionFailure("Unsupported thumbnail size")
            return CGSize(width: 2048, height: 2048)
        }
    }

    /// Image CDN (Photon) and `MediaImageExporter` both don't support "aspect-fill"
    /// resizing mode, so the service performs the necessary calculations by itself.
    ///
    /// Example: if media size is 2000x3000 px and targetSize is 200x200 px, the
    /// returned value will be 200x300 px. For more examples, see `MediaImageServiceTests`.
    static func targetSize(forMediaSize mediaSize: CGSize, targetSize originalTargetSize: CGSize) -> CGSize {
        guard mediaSize.width > 0 && mediaSize.height > 0 else {
            return originalTargetSize
        }
        // Scale image to fill the target size but avoid upscaling
        let scale = min(1, max(
            originalTargetSize.width / mediaSize.width,
            originalTargetSize.height / mediaSize.height
        ))
        let targetSize = mediaSize.scaled(by: scale).rounded()

        // Sanitize the size to make sure ultra-wide panoramas are still resized
        // to fit the target size, but increase it a bit for an acceptable size.
        let threshold: CGFloat = 4
        if targetSize.width > originalTargetSize.width * threshold || targetSize.height > originalTargetSize.height * threshold {
            return CGSize(
                width: min(targetSize.width, originalTargetSize.width * threshold),
                height: min(targetSize.height, originalTargetSize.height * threshold)
            )
        }
        return targetSize
    }
}

// MARK: - SafeMedia

/// A thread-safe media wrapper for use by `MediaImageService`.
private final class SafeMedia {
    let mediaID: TaggedManagedObjectID<Media>
    let blogID: TaggedManagedObjectID<Blog>
    let mediaType: MediaType
    let absoluteLocalURL: URL?
    let remoteThumbnailURL: String?
    let remoteURL: String?
    let size: CGSize?

    init(_ media: Media) {
        self.mediaID = TaggedManagedObjectID(media)
        self.blogID = TaggedManagedObjectID(media.blog)
        self.mediaType = media.mediaType
        self.absoluteLocalURL = media.absoluteLocalURL
        self.remoteURL = media.remoteURL
        self.remoteThumbnailURL = media.remoteThumbnailURL
        if let width = media.width?.floatValue, let height = media.height?.floatValue {
            self.size = CGSize(width: CGFloat(width), height: CGFloat(height))
        } else {
            self.size = nil
        }
    }

    /// Returns the thumbnail remote URL with a given target size. It uses
    /// Image CDN (formerly Photon) if available.
    ///
    /// - parameter targetSize: Target size in pixels.
    func getRemoteThumbnailURL(targetSize: CGSize, blog: Blog) -> URL? {
        switch mediaType {
        case .image:
            guard let remoteURL = remoteURL.flatMap(URL.init) else {
                return nil
            }
            // Download a non-retina version for GIFs: makes a massive difference
            // in terms of size. Example: 2.4 MB -> 350 KB.
            let scale = UIScreen.main.scale
            var targetSize = targetSize
            if remoteURL.isGif {
                targetSize = targetSize
                    .scaled(by: 1.0 / scale)
                    .scaled(by: min(2, scale))
            }
            if !blog.isEligibleForPhoton {
                return WPImageURLHelper.imageURLWithSize(targetSize, forImageURL: remoteURL)
            } else {
                let targetSize = targetSize.scaled(by: 1.0 / UIScreen.main.scale)
                return PhotonImageURLHelper.photonURL(with: targetSize, forImageURL: remoteURL)
            }
        default:
            return remoteThumbnailURL.flatMap(URL.init)
        }
    }
}

private extension Blog {
    var isEligibleForPhoton: Bool {
        !(isPrivateAtWPCom() || (!isHostedAtWPcom && isBasicAuthCredentialStored()))
    }
}

private func makeCacheKey(for mediaID: TaggedManagedObjectID<Media>, size: MediaImageService.ImageSize) -> String {
    "\(mediaID.objectID)-\(size.rawValue)"
}
