import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
final class MediaImageService: NSObject {
    static let shared = MediaImageService()

    private let session: URLSession
    private let coreDataStack: CoreDataStackSwift
    private let mediaFileManager: MediaFileManager
    private let ioQueue = DispatchQueue(label: "org.automattic.MediaImageService")

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
        self.mediaFileManager = MediaFileManager(directory: .cache)

        let configuration = URLSessionConfiguration.default
        // `MediaImageService` has its own disk cache, so it's important to
        // disable the native url cache which is by default set to `URLCache.shared`
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Thumbnails

    /// Returns a preferred thumbnail size (in pixels) optimized for the device.
    ///
    /// - important: It makes sure the app uses the same thumbnails across
    /// different screens and presentation modes to avoid fetching and caching
    /// more than one version of the same image.
    static let preferredThumbnailSize: CGSize = {
        let scale = UIScreen.main.scale
        let targetSize = preferredThumbnailPointSize
        return CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
    }()

    static let preferredThumbnailPointSize: CGSize = {
        let screenSide = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let itemPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 4
        let availableWidth = screenSide - MediaViewController.spacing * CGFloat(itemPerRow - 1)
        let targetSize = (availableWidth / CGFloat(itemPerRow)).rounded(.down)
        return CGSize(width: targetSize, height: targetSize)
    }()

    /// Returns a small thumbnail for the given media asset.
    ///
    /// The thumbnail size is different on different devices, but it's suitable
    /// for presentation in collection views. The returned images are decompressed
    /// (bitmapped) and are ready to be displayed.
    @MainActor
    func thumbnail(for media: Media) async throws -> UIImage {
        guard media.remoteStatus != .stub else {
            let media = try await fetchStubMedia(for: media)
            // This should never happen, but adding it just in case to avoid recusion
            guard media.remoteStatus != .stub else {
                assertionFailure("The fetched media still has a .stub status")
                throw MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL
            }
            return try await _thumbnail(for: media)
        }

        return try await _thumbnail(for: media)
    }

    @MainActor
    private func _thumbnail(for media: Media) async throws -> UIImage {
        if let image = await cachedThumbnail(for: media) {
            return image
        }
        let targetSize = MediaImageService.preferredThumbnailSize
        if let image = await localThumbnail(for: media, targetSize: targetSize) {
            return image
        }
        return try await remoteThumbnail(for: media, targetSize: targetSize)
    }

    // MARK: - Cached Thumbnail

    /// Returns a local thumbnail for the given media object (if available).
    @MainActor
    private func cachedThumbnail(for media: Media) async -> UIImage? {
        let objectID = media.objectID
        return try? await Task.detached(priority: .userInitiated) {
            let imageURL = try self.getCachedThumbnailURL(for: objectID)
            let data = try Data(contentsOf: imageURL)
            return try decompressedImage(from: data)
        }.value
    }

    private func getCachedThumbnailURL(for objectID: NSManagedObjectID) throws -> URL {
        let objectID = objectID.uriRepresentation().lastPathComponent
        return try mediaFileManager.makeLocalMediaURL(
            withFilename: "\(objectID)-small-thumbnail",
            fileExtension: nil // It can be different between local and remove thumbnails
        )
    }

    // The save is performed asynchronously to eliminate any delays. It's
    // exceedingly unlikely it'll result in any duplicated work thanks to the
    // memore caches.
    @MainActor
    private func saveThumbnail(for media: Media, _ closure: @escaping (URL) throws -> Void) {
        let objectID = media.objectID
        ioQueue.async {
            guard let targetURL = try? self.getCachedThumbnailURL(for: objectID) else { return }
            try? closure(targetURL)
        }
    }

    // MARK: - Local Thumbnail

    /// Generates a thumbnail from a local asset.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - targetSize: An ideal size of the thumbnail in pixels.
    @MainActor
    private func localThumbnail(for media: Media, targetSize: CGSize) async -> UIImage? {
        let exporter = MediaThumbnailExporter()
        exporter.mediaDirectoryType = .cache
        exporter.options.preferredSize = targetSize
        exporter.options.scale = 1

        guard let sourceURL = media.absoluteLocalURL,
              exporter.supportsThumbnailExport(forFile: sourceURL) else {
            return nil
        }

        guard let (_, export) = try? await exporter.exportThumbnail(forFileURL: sourceURL) else {
            return nil
        }

        let image = try? await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: export.url)
            return try decompressedImage(from: data)
        }.value

        // The order is important to ensure `export.url` still exists when creating an image
        saveThumbnail(for: media) { targetURL in
            try FileManager.default.moveItem(at: export.url, to: targetURL)
        }

        return image
    }

    // MARK: - Remote Thumbnail

    /// Downloads thumbnail for the given media object and saves it locally. Returns
    /// a file URL for the downloaded thumbnail.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - targetSize: An ideal size of the thumbnail in pixels.
    @MainActor
    private func remoteThumbnail(for media: Media, targetSize: CGSize) async throws -> UIImage {
        guard let imageURL = remoteThumbnailURL(for: media, targetSize: targetSize) else {
            throw URLError(.badURL)
        }

        let host = MediaHost(with: media.blog)
        let request = try await MediaRequestAuthenticator()
            .authenticatedRequest(for: imageURL, host: host)
        guard !Task.isCancelled else {
            throw CancellationError()
        }
        let (data, _) = try await session.data(for: request)

        saveThumbnail(for: media) { targetURL in
            try data.write(to: targetURL)
        }

        return try await Task.detached(priority: .userInitiated) {
            try decompressedImage(from: data)
        }.value
    }

    @MainActor
    private func remoteThumbnailURL(for media: Media, targetSize: CGSize) -> URL? {
        switch media.mediaType {
        case .image:
            guard let remoteURL = media.remoteURL.flatMap(URL.init) else {
                return nil
            }
            if media.blog.isPrivateAtWPCom() || (!media.blog.isHostedAtWPcom && media.blog.isBasicAuthCredentialStored()) {
                return WPImageURLHelper.imageURLWithSize(targetSize, forImageURL: remoteURL)
            } else {
                let scale = 1.0 / UIScreen.main.scale
                let targetSize = targetSize.applying(CGAffineTransform(scaleX: scale, y: scale))
                return PhotonImageURLHelper.photonURL(with: targetSize, forImageURL: remoteURL)
            }
        default:
            return media.remoteThumbnailURL.flatMap(URL.init)
        }
    }

    // MARK: - Stubs

    @MainActor
    private func fetchStubMedia(for media: Media) async throws -> Media {
        guard let mediaID = media.mediaID else {
            throw MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL
        }
        let mediaRepository = MediaRepository(coreDataStack: coreDataStack)
        let objectID = try await mediaRepository.getMedia(withID: mediaID, in: .init(media.blog))
        return try coreDataStack.mainContext.existingObject(with: objectID)
    }
}

// MARK: - Decompression

// Forces decompression (or bitmapping) to happen in the background.
// It's very expensive for some image formats, such as JPEG.
private func decompressedImage(from data: Data) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
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
