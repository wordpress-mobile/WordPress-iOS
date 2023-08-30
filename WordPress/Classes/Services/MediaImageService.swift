import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
final class MediaImageService: NSObject {
    static let shared = MediaImageService()

    private let coreDataStack: CoreDataStackSwift

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
    }

    /// Returns a decompressed thumbnail for the given media asset.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - preferredSize: An ideal size of the thumbnail in pixels. If `zero`, the maximum dimension of the UIScreen is used.
    @MainActor
    func image(for media: Media, preferredSize: CGSize) async throws -> UIImage {
        guard media.remoteStatus != .stub else {
            let media = try await fetchStubMedia(for: media)
            // This should never happen, but adding it just in case to avoid recusion
            guard media.remoteStatus != .stub else {
                assertionFailure("The fetched media still has a .stub status")
                throw MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL
            }
            return try await image(for: media, preferredSize: preferredSize)
        }

        let imageURL = try await imageURL(for: media, preferredSize: preferredSize)
        return try await Task.detached {
            guard let image = UIImage(data: try Data(contentsOf: imageURL)) else {
                throw URLError(.cannotDecodeContentData)
            }
            // Forces decompression (or bitmapping) to happen in the background.
            // It's very expensive for some image formats, such as JPEG.
            return image.preparingForDisplay() ?? image
        }.value
    }

    /// Generate a URL to a thumbnail of the Media, saves it locally, and returns
    /// a URL pointing to the saved file.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - preferredSize: An ideal size of the thumbnail in pixels. If `zero`, the maximum dimension of the UIScreen is used.
    ///
    /// - Note: Images may be downloaded and resized if required, avoid requesting multiple explicit preferredSizes
    ///   as several images could be downloaded, resized, and cached, if there are several variations in size.
    ///
    @MainActor
    func imageURL(for media: Media, preferredSize: CGSize) async throws -> URL {
        do {
            return try await _imageURL(for: media, preferredSize: preferredSize)
        } catch {
            if let error = error as? MediaExportError {
                MediaImportService.logExportError(error)
            }
            throw error
        }
    }

    @MainActor
    private func _imageURL(for media: Media, preferredSize: CGSize) async throws -> URL {
        let mediaID = TaggedManagedObjectID(saved: media)
        let exporter = makeThumbnailExporter(for: media, preferredSize: preferredSize)

        // Check if there is already an exported thumbnail available
        if let identifier = media.localThumbnailIdentifier, let imageURL = await getLocalThumbnailURL(for: identifier, exporter: exporter) {
            return imageURL
        }

        // Downloads the remote thumbnail for the asset.
        @MainActor func getRemoteThumbnail() async throws -> URL {
            let image = try await downloadThumbnail(forMedia: media, preferredSize: preferredSize)
            let (identifier, export) = try await exporter.exportThumbnail(forImage: image)
            try await saveLocalIdentifier(identifier: identifier, for: mediaID)
            return export.url
        }

        // If the asset is available locally, export thumbnails from the local asset
        if let localAssetURL = media.absoluteLocalURL,
           exporter.supportsThumbnailExport(forFile: localAssetURL) {
            let (identifier, export) = try await exporter.exportThumbnail(forFileURL: localAssetURL)
            try await saveLocalIdentifier(identifier: identifier, for: mediaID)
            return export.url
        }

        // If the Media item is a video and has a remote video URL, try and export from the remote video URL.
        if media.mediaType == .video, let videoURL = media.remoteURL.flatMap(URL.init) {
            do {
                let (identifier, export) = try await exporter.exportThumbnail(forVideoURL: videoURL)
                try await saveLocalIdentifier(identifier: identifier, for: mediaID)
                return export.url
            } catch {
                // If an error occurred with the remote video URL, try and download the Media's
                // remote thumbnail instead.
                return try await getRemoteThumbnail()
            }
        }

        return try await getRemoteThumbnail()
    }

    @MainActor
    private func makeThumbnailExporter(for media: Media, preferredSize: CGSize) -> MediaThumbnailExporter {
        let exporter = MediaThumbnailExporter()
        exporter.mediaDirectoryType = .cache
        if preferredSize == CGSize.zero {
            // When using a zero size, default to the maximum screen dimension.
            let screenSize = UIScreen.main.bounds
            let screenSizeMax = max(screenSize.width, screenSize.height)
            exporter.options.preferredSize = CGSize(width: screenSizeMax, height: screenSizeMax)
        } else {
            exporter.options.preferredSize = preferredSize
        }
        if let identifier = media.localThumbnailIdentifier {
            exporter.options.identifier = identifier
        } else {
            exporter.options.identifier = media.objectID.uriRepresentation().lastPathComponent
        }
        return exporter
    }

    private func getLocalThumbnailURL(for identifier: String, exporter: MediaThumbnailExporter) async -> URL? {
        // Checking if the URL is available uses disk I/O, so moving it to background
        await Task.detached {
            exporter.availableThumbnail(with: identifier)
        }.value
    }

    /// Download a thumbnail image for a Media item, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - preferredSize: The preferred size of the image, in points, to configure remote URLs for.
    @MainActor
    private func downloadThumbnail(forMedia media: Media, preferredSize: CGSize) async throws -> UIImage {
        guard let imageURL = getRemoteThumbnailURL(for: media, preferredSize: preferredSize) else {
            throw URLError(.badURL)
        }
        let host = MediaHost(with: media.blog)
        let request = try await MediaRequestAuthenticator().authenticatedRequest(for: imageURL, host: host)
        return try await ImageDownloader.shared.image(for: request)
    }

    @MainActor
    private func getRemoteThumbnailURL(for media: Media, preferredSize: CGSize) -> URL? {
        var remoteURL: URL?
        // Check if the Media item is a video or image.
        if media.mediaType == .video {
            // If a video, ensure there is a remoteThumbnailURL
            if let remoteThumbnailURL = media.remoteThumbnailURL {
                remoteURL = URL(string: remoteThumbnailURL)
            }
        } else {
            // Check if a remote URL for the media itself is available.
            if let remoteAssetURLStr = media.remoteURL, let remoteAssetURL = URL(string: remoteAssetURLStr) {
                // Get an expected WP URL, for sizing.
                if media.blog.isPrivateAtWPCom() || (!media.blog.isHostedAtWPcom && media.blog.isBasicAuthCredentialStored()) {
                    remoteURL = WPImageURLHelper.imageURLWithSize(preferredSize, forImageURL: remoteAssetURL)
                } else {
                    let scale = 1.0 / UIScreen.main.scale
                    let preferredSize = preferredSize.applying(CGAffineTransform(scaleX: scale, y: scale))
                    remoteURL = PhotonImageURLHelper.photonURL(with: preferredSize, forImageURL: remoteAssetURL)
                }
            }
        }
        return remoteURL
    }

    private func saveLocalIdentifier(identifier: MediaThumbnailExporter.ThumbnailIdentifier, for mediaID: TaggedManagedObjectID<Media>) async throws {
        try await coreDataStack.performAndSave { context in
            let media = try context.existingObject(with: mediaID)
            if media.localThumbnailIdentifier != identifier {
                media.localThumbnailIdentifier = identifier
            }
        }
    }

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
