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
    func thumbnailURL(forMedia media: Media, preferredSize: CGSize, onCompletion: @escaping OnThumbnailURL, onError: OnError?) {
        managedObjectContext.perform {
            // Configure a thumbnail exporter.
            let exporter = MediaThumbnailExporter()
            if preferredSize == CGSize.zero {
                // When using a zero size, default to the maximum screen dimension.
                let screenSize = UIScreen.main.bounds
                let screenSizeMax = max(screenSize.width, screenSize.height)
                exporter.options.preferredSize = CGSize(width: screenSizeMax, height: screenSizeMax)
            } else {
                exporter.options.preferredSize = preferredSize
            }

            // Check if there is already an exported thumbnail available.
            if let identifier = media.localThumbnailIdentifier, let availableThumbnail = exporter.availableThumbnail(with: identifier) {
                onCompletion(availableThumbnail)
                return
            }
            // Check if a local copy of the asset is available.
            if let localAssetURL = media.absoluteLocalURL, exporter.supportsThumbnailExport(forFile: localAssetURL) {
                DispatchQueue.global(qos: .default).async {
                    exporter.exportThumbnail(forFile: localAssetURL,
                                             onCompletion: { (identifier, export) in
                                                self.managedObjectContext.perform {
                                                    self.handleThumbnailExport(media: media,
                                                                               identifier: identifier,
                                                                               export: export,
                                                                               onCompletion: onCompletion)
                                                }
                    }, onError: { (error) in
                        self.handleExportError(error, errorHandler: onError)
                    })
                }
                return
            }
            // Try and download a remote thumbnail, and export if available.
            self.downloadThumbnail(forMedia: media, preferredSize: preferredSize, onCompletion: { (image) in
                guard let image = image else {
                    onCompletion(nil)
                    return
                }
                DispatchQueue.global(qos: .default).async {
                    exporter.exportThumbnail(forImage: image,
                                             onCompletion: { (identifier, export) in
                                                self.managedObjectContext.perform {
                                                    self.handleThumbnailExport(media: media,
                                                                               identifier: identifier,
                                                                               export: export,
                                                                               onCompletion: onCompletion)
                                                }
                    }, onError: { (error) in
                        self.handleExportError(error, errorHandler: onError)
                    })
                }
            }, onError: { (error) in
                onError?(error)
            })
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
            if media.blog.isPrivate() {
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
            WPImageSource.shared().downloadImage(for: imageURL,
                                                 authToken: authToken,
                                                 withSuccess: inContextImageHandler,
                                                 failure: inContextErrorHandler)
        } else {
            WPImageSource.shared().downloadImage(for: imageURL,
                                                 withSuccess: inContextImageHandler,
                                                 failure: inContextErrorHandler)
        }
    }

    // MARK: - Helpers

    fileprivate func handleThumbnailExport(media: Media, identifier: MediaThumbnailExporter.ThumbnailIdentifier, export: MediaImageExport, onCompletion: @escaping OnThumbnailURL) {
        // Make sure the Media object hasn't been deleted.
        guard media.isDeleted == false else {
            onCompletion(nil)
            return
        }
        media.localThumbnailIdentifier = identifier
        ContextManager.sharedInstance().save(managedObjectContext)
        onCompletion(export.url)
    }

    /// Handle the OnError callback and logging any errors encountered.
    ///
    fileprivate func handleExportError(_ error: MediaExportError, errorHandler: OnError?) {
        MediaExportService.logExportError(error)
        if let errorHandler = errorHandler {
            self.managedObjectContext.perform {
                errorHandler(error.toNSError())
            }
        }
    }
}
