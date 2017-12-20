import Foundation

/// MediaUploadCoordinator is responsible for creating and uploading new media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaUploadCoordinator: MediaProgressCoordinatorDelegate {

    static let shared = MediaUploadCoordinator()

    private let queue = DispatchQueue(label: "org.wordpress.mediauploadcoordinator")

    private lazy var mediaProgressCoordinator: MediaProgressCoordinator = {
        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    // Init marked private to ensure use of shared singleton.
    private init() {}

    // MARK: - Adding Media

    /// Adds the specified media asset to the specified blog. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter blog: The blog that the asset should be added to.
    ///
    func addMedia(from asset: ExportableAsset, to blog: Blog) {
        guard let asset = asset as? PHAsset else {
            return
        }
        let mediaID = UUID().uuidString
        mediaProgressCoordinator.track(numberOfItems: 1)
        let context = ContextManager.sharedInstance().mainContext
        let service = MediaService(managedObjectContext: context)
        service.createMedia(with: asset,
                            objectID: blog.objectID,
                            thumbnailCallback: nil,
                            completion: { media, error in
                                guard let media = media else {
                                    return
                                }
                                self.begin(media)

                                var progress: Progress? = nil
                                service.uploadMedia(media,
                                                    progress: &progress,
                                                    success: {
                                                        self.end(media)
                                }, failure: { error in
                                    if let error = error {
                                        self.mediaProgressCoordinator.attach(error: error as NSError, toMediaID: mediaID)
                                    }
                                    self.end(media)
                                })
                                if let taskProgress = progress {
                                    self.mediaProgressCoordinator.track(progress: taskProgress, of: media, withIdentifier: mediaID)
                                }
        })
    }

    // MARK: - Observing

    typealias ObserverBlock = (Media, MediaState) -> Void

    private var mediaObservers = [UUID: MediaObserver]()

    /// Add an observer to receive updates when media items are updated.
    ///
    /// - parameter onUpdate: A block that will be called whenever media items
    ///                       (or a specific media item) are updated. The update
    ///                       block will always be called on the main queue.
    /// - parameter media: An optional specific media item to receive updates for.
    ///                    If provided, the `onUpdate` block will only be called
    ///                    for updates to this media item, otherwise it will be
    ///                    called when changes occur to _any_ media item.
    /// - returns: A UUID that can be used to unregister the observer block at a later time.
    ///
    func addObserver(_ onUpdate: @escaping ObserverBlock, for media: Media? = nil) -> UUID {
        let uuid = UUID()

        let observer = MediaObserver(media: media, onUpdate: onUpdate)

        queue.sync {
            mediaObservers[uuid] = observer
        }

        return uuid
    }

    /// Removes the observer block for the specified UUID.
    ///
    /// - parameter uuid: The UUID that matches the observer to be removed.
    ///
    func removeObserver(withUUID uuid: UUID) {
        queue.sync {
            mediaObservers[uuid] = nil
        }
    }

    /// Encapsulates the state of a media item.
    ///
    enum MediaState: CustomDebugStringConvertible {
        case uploading
        case ended
        case progress(value: Double)

        var debugDescription: String {
            switch self {
            case .uploading:
                return "Uploading"
            case .ended:
                return "Ended"
            case .progress(let value):
                return "Progress: \(value)"
            }
        }
    }

    /// Encapsulates an observer block and an optional observed media item.
    struct MediaObserver {
        let media: Media?
        let onUpdate: ObserverBlock
    }

    /// Utility method to return all observers for a specific media item,
    /// including any 'wildcard' observers that are observing _all_ media items.
    ///
    private func observersForMedia(_ media: Media) -> [MediaObserver] {
        let values = mediaObservers.values.filter({ $0.media?.mediaID == media.mediaID })
        return values + wildcardObservers
    }

    /// Utility method to return all 'wildcard' observers that are
    /// observing _all_ media items.
    ///
    private var wildcardObservers: [MediaObserver] {
        return mediaObservers.values.filter({ $0.media == nil })
    }

    // MARK: - Notifying observers

    /// Notifies observers that a media item has begun uploading.
    ///
    func begin(_ media: Media) {
        queue.async {
            self.observersForMedia(media).forEach({ observer in
                DispatchQueue.main.sync {
                    observer.onUpdate(media, .uploading)
                }
            })
        }
    }

    /// Notifies observers that a media item has ended uploading.
    ///
    func end(_ media: Media) {
        queue.async {
            self.observersForMedia(media).forEach({ observer in
                DispatchQueue.main.sync {
                    observer.onUpdate(media, .ended)
                }
            })
        }
    }

    /// Notifies observers that a media item has ended uploading.
    ///
    func progress(_ value: Double, media: Media) {
        queue.async {
            self.observersForMedia(media).forEach({ observer in
                DispatchQueue.main.sync {
                    observer.onUpdate(media, .progress(value: value))
                }
            })
        }
    }

    // MARK: - MediaProgressCoordinatorDelegate

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange totalProgress: Double) {
        for (mediaID, mediaProgress) in mediaProgressCoordinator.mediaInProgress {
            guard let media = mediaProgressCoordinator.media(withIdentifier: mediaID) else {
                continue
            }
            if media.remoteStatus == .pushing {
                progress(mediaProgress.fractionCompleted, media: media)
            }
        }
    }

    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator) {

    }

    func mediaProgressCoordinatorDidFinishUpload(_ mediaProgressCoordinator: MediaProgressCoordinator) {

    }
}
