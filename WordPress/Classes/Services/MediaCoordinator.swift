import Foundation
import WordPressFlux

/// MediaCoordinator is responsible for creating and uploading new media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaCoordinator: NSObject {

    @objc static let shared = MediaCoordinator()

    private(set) var backgroundContext = ContextManager.sharedInstance().newDerivedContext()
    private let mainContext = ContextManager.sharedInstance().mainContext

    private let queue = DispatchQueue(label: "org.wordpress.mediauploadcoordinator")

    private lazy var mediaProgressCoordinator: MediaProgressCoordinator = {
        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    // MARK: - Adding Media

    /// Adds the specified media asset to the specified blog. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter blog: The blog that the asset should be added to.
    ///
    @discardableResult
    func addMedia(from asset: ExportableAsset, to blog: Blog) -> Media {
        return self.addMedia(from: asset, to: blog.objectID)
    }

    /// Adds the specified media asset to the specified post. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter post: The post that the asset should be added to.
    ///
    @discardableResult
    func addMedia(from asset: ExportableAsset, to post: AbstractPost) -> Media {
        return self.addMedia(from: asset, to: post.objectID)
    }

    @discardableResult
    private func addMedia(from asset: ExportableAsset, to objectID: NSManagedObjectID) -> Media {
        mediaProgressCoordinator.track(numberOfItems: 1)
        let service = MediaService(managedObjectContext: backgroundContext)
        let totalProgress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        var creationProgress: Progress? = nil
        let media = service.createMedia(with: asset,
                            objectID: objectID,
                            progress: &creationProgress,
                            thumbnailCallback: { [weak self] media, url in
                                self?.thumbnailReady(url: url, for: media)
                            },
                            completion: { [weak self] media, error in
                                guard let strongSelf = self else {
                                    return
                                }
                                if let error = error {
                                    if let media = media {
                                        strongSelf.mediaProgressCoordinator.attach(error: error as NSError, toMediaID: media.uploadID)
                                        strongSelf.fail(error as NSError, media: media)
                                    } else {
                                        // If there was an error and we don't have a media object we just say to the coordinator that one item was finished
                                        strongSelf.mediaProgressCoordinator.finishOneItem()
                                    }
                                    return
                                }
                                guard let media = media, !media.isDeleted else {
                                    return
                                }

                                let uploadProgress = strongSelf.uploadMedia(media)
                                totalProgress.addChild(uploadProgress, withPendingUnitCount: MediaExportProgressUnits.threeQuartersDone)
        })
        processing(media)
        if let creationProgress = creationProgress {
            totalProgress.addChild(creationProgress, withPendingUnitCount: MediaExportProgressUnits.quarterDone)
            mediaProgressCoordinator.track(progress: totalProgress, of: media, withIdentifier: media.uploadID)
        }
        return media
    }

    func retryMedia(_ media: Media) {
        guard media.remoteStatus == .failed else {
            DDLogError("Can't retry Media upload that hasn't failed. \(String(describing: media))")
            return
        }
        mediaProgressCoordinator.track(numberOfItems: 1)
        uploadMedia(media)
    }

    /// Starts the upload of an already existing local media object
    ///
    /// - Parameter media: the media to upload
    ///
    func addMedia(_ media: Media) {
        guard media.remoteStatus == .local else {
            DDLogError("Can't try to upload Media that isn't local only. \(String(describing: media))")
            return
        }
        mediaProgressCoordinator.track(numberOfItems: 1)
        uploadMedia(media)
    }

    /// Cancels any ongoing upload of the Media and deletes it.
    ///
    /// - Parameter media: the object to cancel and delete
    ///
    func cancelUploadAndDeleteMedia(_ media: Media) {
        cancelUpload(of: media)
        delete(media: media)
    }

    /// Cancels any ongoing upload for the media object
    ///
    /// - Parameter media: the media object to cancel the upload
    ///
    func cancelUpload(of media: Media) {
        mediaProgressCoordinator.cancelAndStopTrack(of: media.uploadID)
    }

    /// Cancels all ongoing uploads
    ///
    func cancelUploadOfAllMedia() {
        mediaProgressCoordinator.cancelAndStopAllInProgressMedia()
    }

    /// Deletes a media object from the storage
    ///
    /// - Parameter media: the media object to delete
    ///
    func delete(media: Media) {
        let service = MediaService(managedObjectContext: backgroundContext)
        service.delete(media, success: nil, failure: nil)
    }

    @discardableResult private func uploadMedia(_ media: Media) -> Progress {
        let service = MediaService(managedObjectContext: backgroundContext)

        var progress: Progress? = nil
        uploading(media)
        service.uploadMedia(media,
                            progress: &progress,
                            success: {
                                self.end(media)
        }, failure: { error in
            guard let nserror = error as NSError? else {
                return
            }
            self.mediaProgressCoordinator.attach(error: nserror, toMediaID: media.uploadID)
            self.fail(nserror, media: media)
        })
        if let taskProgress = progress {
            return taskProgress
        } else {
            return Progress.discreteCompletedProgress()
        }
    }

    // MARK: - Progress

    /// - returns: The current progress for the specified media object.
    ///
    func progress(for media: Media) -> Progress? {
        return mediaProgressCoordinator.progress(forMediaID: media.uploadID)
    }

    /// The global value of progress for all tasks running on the coordinator.
    ///
    var totalProgress: Double {
        return mediaProgressCoordinator.totalProgress
    }

    /// Returns the error associated to media if any
    ///
    /// - Parameter media: the media object from where to  fetch the associated error.
    /// - Returns: the error associated to media if any
    ///
    func error(for media: Media) -> NSError? {
        return mediaProgressCoordinator.error(forMediaID: media.uploadID)
    }

    /// Returns the media object for the specified uploadID.
    ///
    /// - Parameter uploadID: the identifier for an ongoing upload
    /// - Returns: The media object for the specified uploadID.
    ///
    func media(withIdentifier uploadID: String) -> Media? {
        return mediaProgressCoordinator.media(withIdentifier: uploadID)
    }

    /// Returns true if any media is being processed or uploading
    ///
    var isUploading: Bool {
        return mediaProgressCoordinator.isRunning
    }

    /// Returns true if there is any media with a fail state
    ///
    var hasFailedMedia: Bool {
        return mediaProgressCoordinator.hasFailedMedia
    }

    /// Return an array with all failed media IDs
    ///
    var failedMediaIDs: [String] {
        return mediaProgressCoordinator.failedMediaIDs
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

        queue.async {
            self.mediaObservers[uuid] = observer
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
        case processing
        case thumbnailReady(url: URL)
        case uploading
        case ended
        case failed(error: NSError)
        case progress(value: Double)

        var debugDescription: String {
            switch self {
            case .processing:
                return "Processing"
            case .thumbnailReady(let url):
                return "Thumbnail Ready: \(url)"
            case .uploading:
                return "Uploading"
            case .ended:
                return "Ended"
            case .failed(let error):
                return "Failed: \(error)"
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

    /// Notifies observers that a media item is processing/importing.
    ///
    func processing(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .processing)
    }
    /// Notifies observers that a media item has begun uploading.
    ///
    func uploading(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .uploading)
    }

    /// Notifies observers that a thumbnail is ready for the media item
    ///
    func thumbnailReady(url: URL, for media: Media) {
        notifyObserversForMedia(media, ofStateChange: .thumbnailReady(url: url))
    }

    /// Notifies observers that a media item has ended uploading.
    ///
    func end(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .ended)
    }

    /// Notifies observers that a media item has failed to upload.
    ///
    func fail(_ error: NSError, media: Media) {
        notifyObserversForMedia(media, ofStateChange: .failed(error: error))
    }

    /// Notifies observers that a media item is in progress.
    ///
    func progress(_ value: Double, media: Media) {
        notifyObserversForMedia(media, ofStateChange: .progress(value: value))
    }

    func notifyObserversForMedia(_ media: Media, ofStateChange state: MediaState) {
        queue.async {
            self.observersForMedia(media).forEach({ observer in
                DispatchQueue.main.sync {
                    if let media = self.mainContext.object(with: media.objectID) as? Media {
                        observer.onUpdate(media, state)
                    }
                }
            })
        }
    }

    /// Sync the specified blog media library.
    ///
    /// - parameter blog: The blog from where to sync the media library from.
    ///
    @objc func syncMedia(for blog: Blog, success: (() -> Void)? = nil, failure: ((Error) ->Void)? = nil) {
        let service = MediaService(managedObjectContext: backgroundContext)
        service.syncMediaLibrary(for: blog, success: success, failure: failure)
    }

    /// This method checks the status of all media objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of media are happening.
    ///
    @objc func refreshMediaStatus() {
        let service = MediaService(managedObjectContext: backgroundContext)
        service.refreshMediaStatus()
    }
}

// MARK: - MediaProgressCoordinatorDelegate
extension MediaCoordinator: MediaProgressCoordinatorDelegate {

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange totalProgress: Double) {
        for (mediaID, mediaProgress) in mediaProgressCoordinator.mediaInProgress {
            guard let media = mediaProgressCoordinator.media(withIdentifier: mediaID) else {
                continue
            }
            if media.remoteStatus == .pushing || media.remoteStatus == .processing {
                progress(mediaProgress.fractionCompleted, media: media)
            }
        }
    }

    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator) {

    }

    func mediaProgressCoordinatorDidFinishUpload(_ mediaProgressCoordinator: MediaProgressCoordinator) {
        let model = MediaProgressCoordinatorNoticeViewModel(mediaProgressCoordinator: mediaProgressCoordinator)
        if let notice = model?.notice {
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }

        mediaProgressCoordinator.stopTrackingOfAllMedia()
    }
}

extension Media {
    var uploadID: String {
        return objectID.uriRepresentation().absoluteString
    }
}
