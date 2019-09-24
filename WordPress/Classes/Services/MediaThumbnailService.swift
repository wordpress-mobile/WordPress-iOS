import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
///
class MediaThumbnailService: LocalCoreDataService {

    /// Completion handler for a thumbnail URL.
    ///
    public typealias OnThumbnailURL = (URL?) -> Void

    /// Error handler.
    ///
    public typealias OnError = (Error) -> Void

    private static let defaultExportQueue: DispatchQueue = DispatchQueue(label: "org.wordpress.mediaThumbnailService", autoreleaseFrequency: .workItem)

    @objc public lazy var exportQueue: DispatchQueue = {
        return MediaThumbnailService.defaultExportQueue
    }()

    /// Generate a URL to a thumbnail of the Media, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object the URL should be a thumbnail of.
    ///   - preferredSize: An ideal size of the thumbnail in points. If `zero`, the maximum dimension of the UIScreen is used.
    ///   - onCompletion: Completion handler passing the URL once available, or nil if unavailable.
    ///   - onError: Error handler.
    ///
    /// - Note: Images may be downloaded and resized if required, avoid requesting multiple explicit preferredSizes
    ///   as several images could be downloaded, resized, and cached, if there are several variations in size.
    ///
    @objc func thumbnailURL(forMedia media: Media, preferredSize: CGSize, onCompletion: @escaping OnThumbnailURL, onError: OnError?) {
        managedObjectContext.perform {
            var objectInContext: NSManagedObject?
            do {
                objectInContext = try self.managedObjectContext.existingObject(with: media.objectID)
            } catch {
                onError?(error)
                return
            }
            guard let mediaInContext = objectInContext as? Media else {
                return
            }
            // Configure a thumbnail exporter.
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

            // Check if there is already an exported thumbnail available.
            if let identifier = mediaInContext.localThumbnailIdentifier, let availableThumbnail = exporter.availableThumbnail(with: identifier) {
                onCompletion(availableThumbnail)
                return
            }

            // If we already set an identifier before let's reuse it
            if let identifier = mediaInContext.localThumbnailIdentifier {
                exporter.options.identifier = identifier
            } else {
                exporter.options.identifier = media.objectID.uriRepresentation().lastPathComponent
            }

            // Configure a handler for any thumbnail exports
            let onThumbnailExport: MediaThumbnailExporter.OnThumbnailExport = { (identifier, export) in
                self.managedObjectContext.perform {
                    self.handleThumbnailExport(media: mediaInContext,
                                               identifier: identifier,
                                               export: export,
                                               onCompletion: onCompletion)
                }
            }
            // Configure an error handler
            let onThumbnailExportError: OnExportError = { (error) in
                self.handleExportError(error, errorHandler: onError)
            }

            // Configure an attempt to download a remote thumbnail and export it as a thumbnail.
            let attemptDownloadingThumbnail: () -> Void = {
                self.downloadThumbnail(forMedia: mediaInContext, preferredSize: preferredSize, onCompletion: { (image) in
                    guard let image = image else {
                        onError?(MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL)
                        return
                    }
                    self.exportQueue.async {
                        exporter.exportThumbnail(forImage: image,
                                                 onCompletion: onThumbnailExport,
                                                 onError: onThumbnailExportError)
                    }
                }, onError: { (error) in
                    onError?(error)
                })
            }

            // If the Media asset is available locally, export thumbnails from the local asset.
            if let localAssetURL = mediaInContext.absoluteLocalURL {
                if exporter.supportsThumbnailExport(forFile: localAssetURL) {
                    self.exportQueue.async {
                        exporter.exportThumbnail(forFile: localAssetURL,
                                                 onCompletion: onThumbnailExport,
                                                 onError: onThumbnailExportError)
                    }
                }
                return
            }

            // If the Media item is a video and has a remote video URL, try and export from the remote video URL.
            if mediaInContext.mediaType == .video, let remoteURLStr = mediaInContext.remoteURL, let videoURL = URL(string: remoteURLStr) {
                self.exportQueue.async {
                    exporter.exportThumbnail(forVideoURL: videoURL,
                                             onCompletion: onThumbnailExport,
                                             onError: { (error) in
                                                // If an error occurred with the remote video URL, try and download the Media's
                                                // remote thumbnail instead.
                                                self.managedObjectContext.perform {
                                                    attemptDownloadingThumbnail()
                                                }
                    })
                }
                return
            }

            // Try and download a remote thumbnail, if available.
            attemptDownloadingThumbnail()
        }
    }

    /// Download a thumbnail image for a Media item, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object.
    ///   - preferredSize: The preferred size of the image, in points, to configure remote URLs for.
    ///   - onCompletion: Completes if everything was successful, but nil if no image is available.
    ///   - onError: An error was encountered either from the server or locally, depending on the Media object or blog.
    ///
    /// - Note: based on previous implementation in MediaService.m.
    ///
    fileprivate func downloadThumbnail(forMedia media: Media,
                                       preferredSize: CGSize,
                                       onCompletion: @escaping (UIImage?) -> Void,
                                       onError: @escaping (Error) -> Void) {
        var remoteURL: URL?
        // Check if the Media item is a video or image.
        if media.mediaType == .video {
            // If a video, ensure there is a remoteThumbnailURL
            guard let remoteThumbnailURL = media.remoteThumbnailURL else {
                // No video thumbnail available.
                onCompletion(nil)
                return
            }
            remoteURL = URL(string: remoteThumbnailURL)
        } else {
            // Check if a remote URL for the media itself is available.
            guard let remoteAssetURLStr = media.remoteURL, let remoteAssetURL = URL(string: remoteAssetURLStr) else {
                // No remote asset URL available.
                onCompletion(nil)
                return
            }
            // Get an expected WP URL, for sizing.
            if media.blog.isPrivate() || (!media.blog.isHostedAtWPcom && media.blog.isBasicAuthCredentialStored()) {
                remoteURL = WPImageURLHelper.imageURLWithSize(preferredSize, forImageURL: remoteAssetURL)
            } else {
                remoteURL = PhotonImageURLHelper.photonURL(with: preferredSize, forImageURL: remoteAssetURL)
            }
        }
        guard let imageURL = remoteURL else {
            // No URL's available, no images available.
            onCompletion(nil)
            return
        }
        let inContextImageHandler: (UIImage?) -> Void = { (image) in
            self.managedObjectContext.perform {
                onCompletion(image)
            }
        }
        let inContextErrorHandler: (Error?) -> Void = { (error) in
            self.managedObjectContext.perform {
                guard let error = error else {
                    onCompletion(nil)
                    return
                }
                onError(error)
            }
        }
        if media.blog.isPrivate() {
            let accountService = AccountService(managedObjectContext: self.managedObjectContext)
            guard let authToken = accountService.defaultWordPressComAccount()?.authToken else {
                // Don't have an auth token for some reason, return nothing.
                onCompletion(nil)
                return
            }
            DispatchQueue.main.async {
                WPImageSource.shared().downloadImage(for: imageURL,
                                                     authToken: authToken,
                                                     withSuccess: inContextImageHandler,
                                                     failure: inContextErrorHandler)
            }
        } else {
            DispatchQueue.main.async {
                WPImageSource.shared().downloadImage(for: imageURL,
                                                     withSuccess: inContextImageHandler,
                                                     failure: inContextErrorHandler)
            }
        }
    }

    // MARK: - Helpers

    fileprivate func handleThumbnailExport(media: Media, identifier: MediaThumbnailExporter.ThumbnailIdentifier, export: MediaExport, onCompletion: @escaping OnThumbnailURL) {
        // Make sure the Media object hasn't been deleted.
        guard media.isDeleted == false else {
            onCompletion(nil)
            return
        }
        if media.localThumbnailIdentifier != identifier {
            media.localThumbnailIdentifier = identifier
            ContextManager.sharedInstance().save(managedObjectContext)
        }
        onCompletion(export.url)
    }

    /// Handle the OnError callback and logging any errors encountered.
    ///
    fileprivate func handleExportError(_ error: MediaExportError, errorHandler: OnError?) {
        MediaImportService.logExportError(error)
        if let errorHandler = errorHandler {
            self.managedObjectContext.perform {
                errorHandler(error.toNSError())
            }
        }
    }
}
