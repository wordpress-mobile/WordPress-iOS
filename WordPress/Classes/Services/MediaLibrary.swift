import Foundation
import CocoaLumberjack

/// Encapsulates interfacing with Media objects and their assets, whether locally on disk or remotely.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContext
///   method and its corresponding thread.
///
open class MediaLibrary: LocalCoreDataService {

    /// Completion handler for a created Media object.
    ///
    public typealias MediaCompletion = (Media) -> Void

    /// Error handler.
    ///
    public typealias OnError = (Error) -> Void

    // MARK: - Instance methods

    /// Creates a Media object with an absoluteLocalURL for a PHAsset's data, asynchronously.
    ///
    /// - parameter onCompletion: Called if the Media was successfully created and the asset's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, asset: PHAsset, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        DispatchQueue.global(qos: .default).async {

            let exporter = MediaAssetExporter()
            exporter.imageOptions = self.exporterImageOptions
            exporter.videoOptions = self.exporterVideoOptions

            exporter.exportData(forAsset: asset, onCompletion: { (assetExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: assetExport)
                    onCompletion(media)
                }
            }, onError: { (error) in
                self.handleExportError(error, errorHandler: onError)
            })
        }
    }

    /// Creates a Media object with a UIImage, asynchronously.
    ///
    /// The UIImage is expected to be a JPEG, PNG, or other 'normal' image.
    ///
    /// - parameter onCompletion: Called if the Media was successfully created and the image's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, image: UIImage, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        DispatchQueue.global(qos: .default).async {

            let exporter = MediaImageExporter()
            exporter.options = self.exporterImageOptions

            exporter.exportImage(image, fileName: nil, onCompletion: { (imageExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: imageExport)
                    onCompletion(media)
                }
            }, onError: { (error) in
                self.handleExportError(error, errorHandler: onError)
            })
        }
    }

    /// Creates a Media object with a file at a URL, asynchronously.
    ///
    /// The file URL is expected to be a JPEG, PNG, GIF, other 'normal' image, or video.
    ///
    /// - parameter onCompletion: Called if the Media was successfully created and the file's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, url: URL, onCompletion: @escaping MediaCompletion, onError: @escaping OnError) {
        DispatchQueue.global(qos: .default).async {

            let exporter = MediaURLExporter()
            exporter.imageOptions = self.exporterImageOptions
            exporter.videoOptions = self.exporterVideoOptions

            exporter.exportURL(fileURL: url, onCompletion: { (urlExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: urlExport)
                    onCompletion(media)
                }
            }, onError: { (error) in
                self.handleExportError(error, errorHandler: onError)
            })
        }
    }

    // MARK: Thumbnails

    /// Completion handler for a thumbnail URL.
    ///
    public typealias OnThumbnailURL = (URL?) -> Void

    /// Generate a URL to a thumbnail of the Media, if available.
    ///
    /// - Parameters:
    ///   - media: The Media object the URL should be a thumbnail of.
    ///   - preferredSize: An ideal size of the thumbnail in points.
    ///   - onCompletion: Completion handler passing the URL once available, or nil if unavailable.
    ///   - onError: Error handler.
    ///
    /// - Note: Images may be downloaded and resized if required, avoid requesting multiple explicit preferredSizes
    ///   as several images could be downloaded, resized, and cached, if there are several variations in size.
    ///
    func thumbnailURL(forMedia media: Media, preferredSize: CGSize, onCompletion: @escaping OnThumbnailURL, onError: @escaping OnError) {
        // Configure a thumbnail exporter.
        let exporter = MediaThumbnailExporter()
        exporter.options.preferredSize = preferredSize

        // Check if there is already an exported thumbnail available.
        if let identifier = media.localThumbnailIdentifier, let availableThumbnail = exporter.availableThumbnail(with: identifier) {
            onCompletion(availableThumbnail)
            return
        }
        // Check if a local copy of the asset is available.
        if let localAssetURL = media.absoluteLocalURL {
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
        downloadRemoteThumbnail(forMedia: media, preferredSize: preferredSize, onCompletion: { (image) in
            guard let image = image else {
                self.managedObjectContext.perform {
                    onCompletion(nil)
                }
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
            self.managedObjectContext.perform {
                onError(error)
            }
        })
    }

    /// Download a thumbnail image for the Media item, if available.
    ///
    fileprivate func downloadRemoteThumbnail(forMedia media: Media, preferredSize: CGSize, onCompletion: @escaping (UIImage?) -> Void, onError: @escaping OnError) {
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
                remoteURL = PhotonImageURLHelper.photonURL(with: preferredSize, forImageURL: remoteAssetURL)
            } else {
                remoteURL = WPImageURLHelper.imageURLWithSize(preferredSize, forImageURL: remoteAssetURL)
            }
        }
        guard let imageURL = remoteURL else {
            // No URL's available, no images available.
            onCompletion(nil)
            return
        }
        if media.blog.isPrivate() {
            let accountService = AccountService(managedObjectContext: managedObjectContext)
            guard let authToken = accountService.defaultWordPressComAccount()?.authToken else {
                // Don't have an auth token for some reason, return nothing.
                onCompletion(nil)
                return
            }
            WPImageSource.shared().downloadImage(for: imageURL,
                                                 authToken: authToken,
                                                 withSuccess: onCompletion,
                                                 failure: { (error) in
                                                    guard let error = error else {
                                                        onCompletion(nil)
                                                        return
                                                    }
                                                    onError(error)
            })
        } else {
            WPImageSource.shared().downloadImage(for: imageURL,
                                                 withSuccess: onCompletion,
                                                 failure: { (error) in
                                                    guard let error = error else {
                                                        onCompletion(nil)
                                                        return
                                                    }
                                                    onError(error)
            })
        }
    }

    fileprivate func handleThumbnailExport(media: Media, identifier: MediaThumbnailExporter.ThumbnailIdentifier, export: MediaImageExport, onCompletion: @escaping OnThumbnailURL) {
        // Make sure the Media object hasn't been deleted.
        guard media.isDeleted == false else {
            onCompletion(nil)
            return
        }
        media.localThumbnailIdentifier = identifier
        onCompletion(export.url)
        ContextManager.sharedInstance().save(managedObjectContext)
    }

    // MARK: - Helpers

    /// Handle the OnError callback and logging any errors encountered.
    ///
    fileprivate func handleExportError(_ error: MediaExportError, errorHandler: OnError?) {
        // Write an error logging message to help track specific sources of export errors.
        var errorLogMessage = "Error occurred exporting Media"
        switch error {
        case is MediaAssetExporter.AssetExportError:
            errorLogMessage.append(" with asset error")
        case is MediaImageExporter.ImageExportError:
            errorLogMessage.append(" with image error")
        case is MediaURLExporter.URLExportError:
            errorLogMessage.append(" with URL export error")
        case is MediaThumbnailExporter.ThumbnailExportError:
            errorLogMessage.append(" with thumbnail export error")
        case is MediaExportSystemError:
            errorLogMessage.append(" with system error")
        default:
            errorLogMessage = " with unknown error"
        }
        let nerror = error.toNSError()
        DDLogError("\(errorLogMessage), code: \(nerror.code), error: \(nerror)")

        // Return the error via the context's queue, and as an NSError to ensure it carries over the right code/message.
        if let errorHandler = errorHandler {
            self.managedObjectContext.perform {
                errorHandler(nerror)
            }
        }
    }

    // MARK: - Media export configurations

    fileprivate var exporterImageOptions: MediaImageExporter.Options {
        var options = MediaImageExporter.Options()
        options.maximumImageSize = self.exporterMaximumImageSize()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        options.imageCompressionQuality = 0.9
        return options
    }

    fileprivate var exporterVideoOptions: MediaVideoExporter.Options {
        var options = MediaVideoExporter.Options()
        options.stripsGeoLocationIfNeeded = MediaSettings().removeLocationSetting
        return options
    }

    /// Helper method to return an optional value for a valid MediaSettings max image upload size.
    ///
    /// - Note: Eventually we'll rewrite MediaSettings.imageSizeForUpload to do this for us, but want to leave
    ///   that class alone while implementing MediaLibrary.
    ///
    fileprivate func exporterMaximumImageSize() -> CGFloat? {
        let maxUploadSize = MediaSettings().imageSizeForUpload
        if maxUploadSize < Int.max {
            return CGFloat(maxUploadSize)
        }
        return nil
    }

    /// Configure Media with the AssetExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaAssetExporter.AssetExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the URLExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaURLExporter.URLExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the ImageExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaImageExport) {
        if let width = export.width {
            media.width = width as NSNumber
        }
        if let height = export.height {
            media.height = height as NSNumber
        }
        media.mediaType = .image
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media with the VideoExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaVideoExport) {
        if let duration = export.duration {
            media.length = duration as NSNumber
        }
        media.mediaType = .video
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media with the GIFExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaGIFExport) {
        media.mediaType = .image
        configureMedia(media, withFileExport: export)
    }

    /// Configure Media via the general Export protocol.
    ///
    fileprivate func configureMedia(_ media: Media, withFileExport export: MediaExport) {
        if let fileSize = export.fileSize {
            media.filesize = fileSize as NSNumber
        }
        media.absoluteLocalURL = export.url
        media.filename = export.url.lastPathComponent
    }
}
