import Foundation

/// Utility class for downloading a remote thumbnail for Media items.
///
class MediaThumbnailDownloader {

    /// The managed object context the utility should operate within and call closures via `performBlock`.
    ///
    let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
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
    func downloadThumbnail(forMedia media: Media,
                           preferredSize: CGSize,
                           onCompletion: @escaping (UIImage?) -> Void,
                           onError: @escaping (Error) -> Void) {

        managedObjectContext.perform {
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
    }
}
