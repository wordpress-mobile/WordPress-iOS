import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
final class MediaImageService: NSObject {
    static let shared = MediaImageService()

    private let session: URLSession
    private let coreDataStack: CoreDataStackSwift

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack

        let configuration = URLSessionConfiguration.default
        // `MediaImageService` has its own disk cache, so it's important to
        // disable the native url cache which is by default set to `URLCache.shared`
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Thumbnails

    /// Returns a preferred thumbnail size optimized for the device.
    ///
    /// - important: It makes sure the app uses the same thumbnails across
    /// different screens and presentation modes to avoid fetching and caching
    /// more than one version of the same image.
    private static let preferredThumbnailSize: CGSize = {
        let screenSide = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let itemPerRow = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 4
        let availableWidth = screenSide - MediaViewController.spacing * CGFloat(itemPerRow - 1)
        let scale = UIScreen.main.scale
        let targetSize = (availableWidth / CGFloat(itemPerRow)).rounded(.down) * scale
        return CGSize(width: targetSize, height: targetSize)
    }()

    /// Returns a decompressed thumbnail optimized for the device.
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
        let fileURL = try await fetchRemoteThumbnail(for: media, targetSize: targetSize)
        return try await decompressedImage(forFileURL: fileURL)
    }

    /// Downloads thumbnail for the given media object and saves it locally.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - targetSize: An ideal size of the thumbnail in pixels.
    @MainActor
    private func fetchRemoteThumbnail(for media: Media, targetSize: CGSize) async throws -> URL {
        do {
            let fileURL = try await _fetchRemoteThumbnail(for: media, targetSize: targetSize)
            try await saveLocalThumbnailURL(fileURL, for: TaggedManagedObjectID(media))
            return fileURL
        } catch {
            if let error = error as? MediaExportError {
                MediaImportService.logExportError(error)
            }
            throw error
        }
    }

    /// Download a thumbnail image for a Media item, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - targetSize: The preferred size of the image, in points, to configure remote URLs for.
    @MainActor
    private func _fetchRemoteThumbnail(for media: Media, targetSize: CGSize) async throws -> URL {
        guard let imageURL = getRemoteThumbnailURL(for: media, targetSize: targetSize) else {
            throw URLError(.badURL)
        }
        let host = MediaHost(with: media.blog)
        let request = try await MediaRequestAuthenticator().authenticatedRequest(for: imageURL, host: host)
        let (data, _) = try await session.data(for: request)
        return try await Task.detached {
            let fileURL = try MediaFileManager.cache.directoryURL()
                .appendingPathComponent(UUID().uuidString, isDirectory: false)
                .appendingPathExtension(imageURL.pathExtension)
            try data.write(to: fileURL)
            return fileURL
        }.value
    }

    @MainActor
    private func getRemoteThumbnailURL(for media: Media, targetSize: CGSize) -> URL? {
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

    private func saveLocalThumbnailURL(_ fileURL: URL, for mediaID: TaggedManagedObjectID<Media>) async throws {
        try await coreDataStack.performAndSave { context in
            let media = try context.existingObject(with: mediaID)
            if media.absoluteThumbnailLocalURL != fileURL {
                media.absoluteThumbnailLocalURL = fileURL
            }
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

    return try await Task.detached {
        let data = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        guard isDecompressionNeeded(for: fileURL) else {
            return image
        }
        return image.preparingForDisplay() ?? image
    }.value
}

private func isDecompressionNeeded(for url: URL) -> Bool {
    let fileExtension = url.pathExtension
    // This check is required to avoid the following error messages when
    // using `preparingForDisplay`:
    //
    //    [Decompressor] Error -17102 decompressing image -- possibly corrupt
    //
    // More info: https://github.com/SDWebImage/SDWebImage/issues/3365
    return fileExtension == "jpeg" || fileExtension == "jpg"
}
