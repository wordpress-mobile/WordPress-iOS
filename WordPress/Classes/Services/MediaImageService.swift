import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
final class MediaImageService: NSObject {
    static let shared = MediaImageService()

    private let session: URLSession
    private let coreDataStack: CoreDataStackSwift
    private let ioQueue = DispatchQueue(label: "org.automattic.MediaImageService")

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack

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

    /// Returns a decompressed thumbnail optimized for the device.
    ///
    /// For local images added to the library, it expects the `absoluteThumbnailLocalURL`
    /// to be set by `MediaImportService`.
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
        if let fileURL = media.absoluteThumbnailLocalURL,
           let image = try? await decompressedImage(forFileURL: fileURL) {
            return image
        }
        let targetSize = MediaImageService.preferredThumbnailSize
        return try await remoteThumbnail(for: media, targetSize: targetSize)
    }

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

        // Saves the thumbnail and records `absoluteThumbnailLocalURL` asynchronously.
        // The service doesn't wait for the completion to eliminate any delays
        // for image display. This includes writing data to disk, which is relatively
        // fast, and updating `absoluteThumbnailLocalURL` on the media object.
        // The latter can be slow because there is only one background context
        // and it's often busy with long operations that could delay the image
        // display by seconds.
        let mediaID = TaggedManagedObjectID(media)
        ioQueue.async {
            if let fileURL = try? self.saveThumbnail(data, for: imageURL) {
                self.setLocalThumbnailURL(fileURL, for: mediaID)
            }
        }

        return try await Task.detached(priority: .userInitiated) {
            try decompressedImage(from: data, fileExtension: imageURL.pathExtension)
        }.value
    }

    private func saveThumbnail(_ data: Data, for imageURL: URL) throws -> URL {
        let fileURL = try MediaFileManager.cache.directoryURL()
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension(imageURL.pathExtension)
        try data.write(to: fileURL)
        return fileURL
    }

    private func setLocalThumbnailURL(_ fileURL: URL, for mediaID: TaggedManagedObjectID<Media>) {
        coreDataStack.performAndSave({ context in
            let media = try context.existingObject(with: mediaID)
            if media.absoluteThumbnailLocalURL != fileURL {
                media.absoluteThumbnailLocalURL = fileURL
            }
        }, completion: nil, on: .main)
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
        return try await withUnsafeThrowingContinuation { continuation in
            let mediaService = MediaService(managedObjectContext: coreDataStack.mainContext)
            mediaService.getMediaWithID(mediaID, in: media.blog, success: {
                continuation.resume(returning: $0)
            }, failure: {
                continuation.resume(throwing: $0)
            })
        }
    }
}

// MARK: - Decompression

// Forces decompression (or bitmapping) to happen in the background.
// It's very expensive for some image formats, such as JPEG.
private func decompressedImage(forFileURL fileURL: URL) async throws -> UIImage {
    assert(fileURL.isFileURL, "Unsupported URL: \(fileURL)")
    return try await Task.detached(priority: .userInitiated) {
        let data = try Data(contentsOf: fileURL)
        return try decompressedImage(from: data, fileExtension: fileURL.pathExtension)
    }.value
}

private func decompressedImage(from data: Data, fileExtension: String) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
    }
    guard isDecompressionNeeded(for: fileExtension) else {
        return image
    }
    return image.preparingForDisplay() ?? image
}

private func isDecompressionNeeded(for fileExtension: String) -> Bool {
    // This check is required to avoid the following error messages when
    // using `preparingForDisplay`:
    //
    //    [Decompressor] Error -17102 decompressing image -- possibly corrupt
    //
    // More info: https://github.com/SDWebImage/SDWebImage/issues/3365
    return fileExtension == "jpeg" || fileExtension == "jpg"
}
