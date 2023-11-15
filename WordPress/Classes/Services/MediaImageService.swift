import UIKit
import CoreData

/// A service for retrieval and caching of thumbnails for Media objects.
actor MediaImageService: NSObject {
    static let shared = MediaImageService()

    private let session: URLSession
    private let cache: MemoryCache
    private let coreDataStack: CoreDataStackSwift
    private let mediaFileManager: MediaFileManager

    init(cache: MemoryCache = .shared,
         coreDataStack: CoreDataStackSwift = ContextManager.shared,
         mediaFileManager: MediaFileManager = MediaFileManager(directory: .cache)) {
        self.cache = cache
        self.coreDataStack = coreDataStack
        self.mediaFileManager = mediaFileManager

        let configuration = URLSessionConfiguration.default
        // `MediaImageService` has its own disk cache, so it's important to
        // disable the native url cache which is by default set to `URLCache.shared`
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
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

    // MARK: - Images (Fullsize)

    /// Returns a full-size image for the given media asset.
    ///
    /// The app rarely loads full-size images, and they make take a significant
    /// amount of space and memory, so they are cached only in `URLCache`.
    @MainActor
    func image(for media: Media) async throws -> UIImage {
        let media = try await getSafeMedia(for: media)

        if let localURL = media.absoluteLocalURL,
           let image = try? await makeImage(from: localURL) {
            return image
        }
        if let info = await getFullsizeImageInfo(for: media) {
            let data = try await loadData(with: info, using: session)
            return try await makeImage(from: data)
        }
        // The media has no local or remote URL – should never happen
        throw URLError(.unknown)
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

    // MARK: - Thumbnails

    /// Returns a thumbnail for the given media asset. The images are decompressed
    /// (or bitmapped) and are ready to be displayed.
    ///
    /// The thumbnails are stored in both disk and memory cache. They don't take
    /// a lot of space and are used often. The memory cache holds decompressed
    /// images ready to be displayed.
    @MainActor
    func thumbnail(for media: Media, size: ThumbnailSize = .small) async throws -> UIImage {
        let media = try await getSafeMedia(for: media)
        return try await _thumbnail(for: media, size: size)
    }

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

    private func _thumbnail(for media: SafeMedia, size: ThumbnailSize) async throws -> UIImage {
        if let image = cache.getImage(forKey: makeCacheKey(for: media.mediaID, size: size)) {
            return image
        }
        let image = try await actuallyLoadThumbnail(for: media, size: size)
        cache.setImage(image, forKey: makeCacheKey(for: media.mediaID, size: size))
        return image
    }

    private func actuallyLoadThumbnail(for media: SafeMedia, size: ThumbnailSize) async throws -> UIImage {
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
    nonisolated func getCachedThumbnail(for mediaID: TaggedManagedObjectID<Media>, size: ThumbnailSize = .small) -> UIImage? {
        cache.getImage(forKey: makeCacheKey(for: mediaID, size: size))
    }

    // MARK: - Thumbnails (Disk Cache)

    /// Returns a local thumbnail for the given media object (if available).
    private func cachedThumbnail(for mediaID: TaggedManagedObjectID<Media>, size: ThumbnailSize) async -> UIImage? {
        guard let fileURL = getCachedThumbnailURL(for: mediaID, size: size) else { return nil }
        return try? await makeImage(from: fileURL)
    }

    private func getCachedThumbnailURL(for mediaID: TaggedManagedObjectID<Media>, size: ThumbnailSize) -> URL? {
        let mediaID = mediaID.objectID.uriRepresentation().lastPathComponent
        return try? mediaFileManager.makeLocalMediaURL(
            withFilename: "\(mediaID)-\(size.rawValue)-thumbnail",
            fileExtension: nil, // We don't know ahead of time
            incremented: false
        )
    }

    // MARK: - Local Thumbnail

    /// Generates a thumbnail from a local asset and saves it in cache.
    private func localThumbnail(for media: SafeMedia, size: ThumbnailSize) async -> UIImage? {
        guard let sourceURL = media.absoluteLocalURL else {
            return nil
        }

        let exporter = await makeThumbnailExporter(for: media, size: size)
        guard exporter.supportsThumbnailExport(forFile: sourceURL),
              let (_, export) = try? await exporter.exportThumbnail(forFileURL: sourceURL),
              let image = try? await makeImage(from: export.url)
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
    private func makeThumbnailExporter(for media: SafeMedia, size: ThumbnailSize) -> MediaThumbnailExporter {
        let exporter = MediaThumbnailExporter()
        exporter.mediaDirectoryType = .cache
        exporter.options.preferredSize = MediaImageService.getThumbnailSize(for: media, size: size)
        exporter.options.scale = 1 // In pixels
        return exporter
    }

    // MARK: - Remote Thumbnail

    /// Downloads a remote thumbnail and saves it in cache.
    private func remoteThumbnail(for media: SafeMedia, size: ThumbnailSize) async throws -> UIImage {
        guard let info = await getRemoteThumbnailInfo(for: media, size: size) else {
            // Self-hosted WordPress sites don't have `remoteThumbnailURL`, so
            // the app generates the thumbnail by itself.
            if media.mediaType == .video {
                return try await generateThumbnailForVideo(for: media, size: size)
            }
            throw URLError(.badURL)
        }
        let data = try await loadData(with: info, using: session)
        let image = try await makeImage(from: data)
        if let fileURL = getCachedThumbnailURL(for: media.mediaID, size: size) {
            try? data.write(to: fileURL)
        }
        return image
    }

    // There are two reasons why these operations are performed in the background:
    // performance and making sure the subsystem is thread-safe and can be used
    // from the background.
    private func getRemoteThumbnailInfo(for media: SafeMedia, size: ThumbnailSize) async -> RemoteImageInfo? {
        let targetSize = await MediaImageService.getThumbnailSize(for: media, size: size)
        return try? await coreDataStack.performQuery { context in
            let blog = try context.existingObject(with: media.blogID)
            guard let imageURL = media.getRemoteThumbnailURL(targetSize: targetSize, blog: blog) else { return nil }
            return RemoteImageInfo(imageURL: imageURL, host: MediaHost(with: blog))
        }
    }

    // MARK: - Networking

    private func loadData(with info: RemoteImageInfo, using session: URLSession) async throws -> Data {
        let request = try await MediaRequestAuthenticator()
            .authenticatedRequest(for: info.imageURL, host: info.host)
        let (data, response) = try await session.data(for: request)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              (200..<400).contains(statusCode) else {
            throw URLError(.unknown)
        }
        return data
    }

    private struct RemoteImageInfo {
        let imageURL: URL
        let host: MediaHost
    }

    // MARK: - Thubmnail for Video

    private func generateThumbnailForVideo(for media: SafeMedia, size: ThumbnailSize) async throws -> UIImage {
        guard let videoURL = media.remoteURL.flatMap(URL.init) else {
            throw URLError(.badURL)
        }
        let exporter = await makeThumbnailExporter(for: media, size: size)
        let (_, export) = try await exporter.exportThumbnail(forVideoURL: videoURL)
        let image = try await makeImage(from: export.url)

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

    enum ThumbnailSize: String {
        /// The small thumbnail that can be used in collection view cells and
        /// similar situations.
        case small

        /// A medium thumbnail thumbnail that can typically be used to fit
        /// the entire screen on iPhone or a large portion of the sreen on iPad.
        case medium
    }

    @MainActor
    fileprivate static func getThumbnailSize(for media: SafeMedia, size: ThumbnailSize) -> CGSize {
        let mediaSize = media.size ?? CGSize(width: 1024, height: 1024) // rhs should never happen
        return MediaImageService.getThumbnailSize(for: mediaSize, size: size)

    }

    /// Returns an optimal target size in pixels for a thumbnail of the given
    /// size for the given media asset.
    @MainActor
    static func getThumbnailSize(for mediaSize: CGSize, size: ThumbnailSize) -> CGSize {
        let targetSize = MediaImageService.getPreferredThumbnailSize(for: size)
        return MediaImageService.targetSize(forMediaSize: mediaSize, targetSize: targetSize)
    }

    /// Returns a preferred thumbnail size (in pixels) optimized for the device.
    ///
    /// - important: It makes sure the app uses the same thumbnails across
    /// different screens and presentation modes to avoid fetching and caching
    /// more than one version of the same image.
    @MainActor
    private static func getPreferredThumbnailSize(for thumbnail: ThumbnailSize) -> CGSize {
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

private func makeCacheKey(for mediaID: TaggedManagedObjectID<Media>, size: MediaImageService.ThumbnailSize) -> String {
    "\(mediaID.objectID)-\(size.rawValue)"
}

// MARK: - Helpers (Decompression)

private func makeImage(from fileURL: URL) async throws -> UIImage {
    try await Task.detached {
        let data = try Data(contentsOf: fileURL)
        return try _makeImage(from: data)
    }.value
}

private func makeImage(from data: Data) async throws -> UIImage {
    try await Task.detached {
        return try _makeImage(from: data)
    }.value
}

// Forces decompression (or bitmapping) to happen in the background.
// It's very expensive for some image formats, such as JPEG.
private func _makeImage(from data: Data) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
    }
    if data.isMatchingMagicNumbers(Data.gifMagicNumbers) {
        return AnimatedImageWrapper(gifData: data) ?? image
    }
    guard isDecompressionNeeded(for: data) else {
        return image
    }
    return image.preparingForDisplay() ?? image
}

private func isDecompressionNeeded(for data: Data) -> Bool {
    // This check is required to avoid the following error messages when
    // using `preparingForDisplay`:
    //
    //    [Decompressor] Error -17102 decompressing image -- possibly corrupt
    //
    // More info: https://github.com/SDWebImage/SDWebImage/issues/3365
    data.isMatchingMagicNumbers(Data.jpegMagicNumbers)
}

private extension Data {
    // JPEG magic numbers https://en.wikipedia.org/wiki/JPEG
    static let jpegMagicNumbers: [UInt8] = [0xFF, 0xD8, 0xFF]

    // GIF magic numbers https://en.wikipedia.org/wiki/GIF
    static let gifMagicNumbers: [UInt8] = [0x47, 0x49, 0x46]

    func isMatchingMagicNumbers(_ numbers: [UInt8?]) -> Bool {
        guard self.count >= numbers.count else {
            return false
        }
        return zip(numbers.indices, numbers).allSatisfy { index, number in
            guard let number = number else { return true }
            return self[index] == number
        }
    }
}
