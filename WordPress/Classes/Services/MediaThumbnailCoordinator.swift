import Foundation
import UIKit

/// MediaThumbnailCoordinator is responsible for generating thumbnails for media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaThumbnailCoordinator: NSObject {

    @objc static let shared = MediaThumbnailCoordinator()

    private(set) var backgroundContext: NSManagedObjectContext = {
        let context = ContextManager.sharedInstance().newDerivedContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    private let queue = DispatchQueue(label: "org.wordpress.media_thumbnail_coordinator", qos: .default)

    typealias ThumbnailBlock = (UIImage?, Error?) -> Void

    private lazy var mediaThumbnailService: MediaThumbnailService = {
        let mediaThumbnailService = MediaThumbnailService(managedObjectContext: backgroundContext)
        mediaThumbnailService.exportQueue = queue
        return mediaThumbnailService
    }()

    /// Tries to generate a thumbnail for the specified media object with the size requested
    ///
    /// - Parameters:
    ///   - media: the media object to generate the thumbail representation
    ///   - size: the size of the thumbnail
    ///   - onCompletion: a block that is invoked when the thumbnail generatio is completed with success or failure.
    @objc func thumbnail(for media: Media, with size: CGSize, onCompletion: @escaping ThumbnailBlock) {
        mediaThumbnailService.thumbnailURL(forMedia: media, preferredSize: size, onCompletion: { (url) in
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
        }) { (error) in
            DispatchQueue.main.async {
                onCompletion(nil, error)
            }
        }
    }

}
