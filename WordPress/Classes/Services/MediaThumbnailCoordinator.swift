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
            DispatchQueue.main.async {
                onCompletion(image, nil)
            }
        }
        let failure: (Error?) -> Void = { (error) in
            DispatchQueue.main.async {
                onCompletion(nil, error)
            }
        }

        let mediaThumbnailService = MediaThumbnailService(coreDataStack: coreDataStack)
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

        let mediaRepository = MediaRepository(coreDataStack: coreDataStack)
        let blogID = TaggedManagedObjectID(media.blog)
        Task { @MainActor in
            do {
                let mediaID = try await mediaRepository.getMedia(withID: mediaID, in: blogID)
                // FIXME: Pass media object identifier to the completion block instead.
                let loadedMedia = try coreDataStack.mainContext.existingObject(with: mediaID)
                onCompletion(loadedMedia, nil)
            } catch {
                onCompletion(nil, error)
            }
        }
    }
}
