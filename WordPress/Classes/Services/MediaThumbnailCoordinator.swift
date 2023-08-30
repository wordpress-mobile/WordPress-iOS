import Foundation
import UIKit

/// MediaThumbnailCoordinator is responsible for generating thumbnails for media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaThumbnailCoordinator: NSObject {

    @objc static let shared = MediaThumbnailCoordinator()

    private var coreDataStack: CoreDataStackSwift {
        ContextManager.shared
    }

    private let queue = DispatchQueue(label: "org.wordpress.media_thumbnail_coordinator", qos: .default)

    typealias ThumbnailBlock = (UIImage?, Error?) -> Void
    typealias LoadStubMediaCompletionBlock = (Media?, Error?) -> Void

    /// Tries to generate a thumbnail for the specified media object with the size requested
    ///
    /// - Parameters:
    ///   - media: The media object to generate the thumbnail representation.
    ///   - size: The size of the thumbnail in pixels.
    ///   - onCompletion: a block that is invoked when the thumbnail generation is completed with success or failure.
    @objc func thumbnail(for media: Media, with size: CGSize, onCompletion: @escaping ThumbnailBlock) {
        if media.remoteStatus == .stub {
            fetchThumbnailForMediaStub(for: media, with: size, onCompletion: onCompletion)
            return
        }

        let success: (URL?) -> Void = { (url) in
            guard let imageURL = url else {
                DispatchQueue.main.async {
                    onCompletion(nil, MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL)
                }
                return
            }
            let image = UIImage(contentsOfFile: imageURL.path)
            // Decompression is expensive and has to happen in the background
            let decompressedImage = image?.preparingForDisplay() ?? image
            DispatchQueue.main.async {
                onCompletion(decompressedImage, nil)
            }
        }
        let failure: (Error?) -> Void = { (error) in
            DispatchQueue.main.async {
                onCompletion(nil, error)
            }
        }

        let mediaThumbnailService = LegacyMediaThumbnailService(coreDataStack: coreDataStack)
        mediaThumbnailService.exportQueue = self.queue
        mediaThumbnailService.thumbnailURL(forMedia: media, preferredSize: size, onCompletion: success, onError: failure)
    }

    /// Tries to generate a thumbnail for the specified media object that is stub with the size requested
    ///
    /// - Parameters:
    ///   - media: the media object to generate the thumbnail representation
    ///   - size: The size of the thumbnail in pixels.
    ///   - onCompletion: a block that is invoked when the thumbnail generation is completed with success or failure.
    func fetchThumbnailForMediaStub(for media: Media, with size: CGSize, onCompletion: @escaping ThumbnailBlock) {
        fetchStubMedia(for: media) { [weak self] (fetchedMedia, error) in
            if let fetchedMedia = fetchedMedia {
                self?.thumbnail(for: fetchedMedia, with: size, onCompletion: onCompletion)
            }
        }
    }

    /// Fetch a media from a stub media
    ///
    /// - Parameters:
    ///   - media: the media object to fetch
    ///   - onCompletion: a block that is invoked when the media is loaded and fetched with success or failure.
    func fetchStubMedia(for media: Media, onCompletion: @escaping LoadStubMediaCompletionBlock) {
        guard let mediaID = media.mediaID else {
            onCompletion(nil, MediaThumbnailExporter.ThumbnailExportError.failedToGenerateThumbnailFileURL)
            return
        }

        // It's only safe to use the main context as this MediaService instance's context because a Media object is
        // leaked out of MediaService's lifecycle (MediaService.managedObjectContext's to be exact).
        let mediaService = MediaService(managedObjectContext: coreDataStack.mainContext)
        mediaService.getMediaWithID(mediaID, in: media.blog, success: { loadedMedia in
            onCompletion(loadedMedia, nil)
        }, failure: { (error) in
            onCompletion(nil, error)
        })
    }
}
