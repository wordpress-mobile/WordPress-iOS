import Foundation

/// A service for handling the process of retrieving and generating thumbnail images
/// for existing Media objects, whether remote or locally available.
///
final class LegacyMediaThumbnailService: NSObject {
    private static let defaultExportQueue: DispatchQueue = DispatchQueue(label: "org.wordpress.mediaThumbnailService", autoreleaseFrequency: .workItem)

    @objc public lazy var exportQueue: DispatchQueue = {
        return LegacyMediaThumbnailService.defaultExportQueue
    }()

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

    /// Generate a URL to a thumbnail of the Media, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object the URL should be a thumbnail of.
    ///   - preferredSize: An ideal size of the thumbnail in points. If `zero`, the maximum dimension of the UIScreen is used.
    ///   - onCompletion: Completion handler passing the URL once available, or nil if unavailable. This closure is called on the `exportQueue`.
    ///   - onError: Error handler. This closure is called on the `exportQueue`.
    ///
    /// - Note: Images may be downloaded and resized if required, avoid requesting multiple explicit preferredSizes
    ///   as several images could be downloaded, resized, and cached, if there are several variations in size.
    ///
    @objc func thumbnailURL(forMedia media: Media, preferredSize: CGSize, onCompletion: @escaping (URL?) -> Void, onError: ((Error) -> Void)?) {
        let mediaID = TaggedManagedObjectID(saved: media)

        // We can use the main context here because we only read the `Media` instance, without changing it, and all
        // the time consuming work is done in background queues.
        let context = coreDataStack.mainContext
        context.perform {
            let mediaInContext: Media
            do {
                mediaInContext = try context.existingObject(with: mediaID)
            } catch {
                self.exportQueue.async {
                    onError?(error)
                }
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
                self.exportQueue.async {
                    onCompletion(availableThumbnail)
                }
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
                self.handleThumbnailExport(mediaID: mediaID,
                                           identifier: identifier,
                                           export: export,
                                           onCompletion: onCompletion)
            }
            // Configure an error handler
            let onThumbnailExportError: OnExportError = { (error) in
                self.handleExportError(error, errorHandler: onError)
            }

            // Configure an attempt to download a remote thumbnail and export it as a thumbnail.
            let attemptDownloadingThumbnail: () -> Void = {
                self.downloadThumbnail(forMedia: mediaInContext, preferredSize: preferredSize, callbackQueue: self.exportQueue, onCompletion: { (image) in
                    guard let image = image else {
                        onError?(MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL)
                        return
                    }
                    exporter.exportThumbnail(forImage: image, onCompletion: onThumbnailExport, onError: onThumbnailExportError)
                }, onError: { (error) in
                    onError?(error)
                })
            }

            // If the Media asset is available locally, export thumbnails from the local asset.
            if let localAssetURL = mediaInContext.absoluteLocalURL,
                exporter.supportsThumbnailExport(forFile: localAssetURL) {
                    self.exportQueue.async {
                        exporter.exportThumbnail(forFile: localAssetURL,
                                                 onCompletion: onThumbnailExport,
                                                 onError: onThumbnailExportError)
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
                                                context.perform {
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
    ///   - callbackQueue: The queue to execute the `onCompletion` or the `onError` callback.
    ///   - onCompletion: Completes if everything was successful, but nil if no image is available.
    ///   - onError: An error was encountered either from the server or locally, depending on the Media object or blog.
    ///
    /// - Note: based on previous implementation in MediaService.m.
    ///
    private func downloadThumbnail(
        forMedia media: Media,
        preferredSize: CGSize,
        callbackQueue: DispatchQueue,
        onCompletion: @escaping (UIImage?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
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
        guard let imageURL = remoteURL else {
            // No URL's available, no images available.
            callbackQueue.async {
                onCompletion(nil)
            }
            return
        }

        let download = AuthenticatedImageDownload(url: imageURL, mediaHost: MediaHost(with: media.blog), callbackQueue: callbackQueue, onSuccess: onCompletion, onFailure: onError)

        download.start()
    }

    // MARK: - Helpers

    private func handleThumbnailExport(mediaID: TaggedManagedObjectID<Media>, identifier: MediaThumbnailExporter.ThumbnailIdentifier, export: MediaExport, onCompletion: @escaping (URL?) -> Void) {
        coreDataStack.performAndSave({ context in
            let media = try context.existingObject(with: mediaID)
            if media.localThumbnailIdentifier != identifier {
                media.localThumbnailIdentifier = identifier
            }
        }, completion: { (result: Result<Void, Error>) in
            switch result {
            case .success:
                onCompletion(export.url)
            case .failure:
                onCompletion(nil)
            }
        }, on: exportQueue)
    }

    /// Handle the OnError callback and logging any errors encountered.
    ///
    private func handleExportError(_ error: MediaExportError, errorHandler: ((Error) -> Void)?) {
        MediaImportService.logExportError(error)
        exportQueue.async {
            errorHandler?(error.toNSError())
        }
    }
}
