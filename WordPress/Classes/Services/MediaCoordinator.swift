import Foundation
import WordPressFlux

/// MediaCoordinator is responsible for creating and uploading new media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaCoordinator: NSObject {

    @objc static let shared = MediaCoordinator()

    private(set) var backgroundContext: NSManagedObjectContext = {
        let context = ContextManager.sharedInstance().newDerivedContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    private let mainContext = ContextManager.sharedInstance().mainContext

    private let queue = DispatchQueue(label: "org.wordpress.mediauploadcoordinator")

    // MARK: - Progress Coordinators

    private let progressCoordinatorQueue = DispatchQueue(label: "org.wordpress.mediaprogresscoordinator", attributes: .concurrent)

    /// Tracks uploads that don't belong to a specific post
    private lazy var mediaLibraryProgressCoordinator: MediaProgressCoordinator = {
        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    /// Tracks uploads of media for specific posts
    private var postMediaProgressCoordinators = [AbstractPost: MediaProgressCoordinator]()

    /// - returns: The progress coordinator for the specified post. If a coordinator
    ///            does not exist, one will be created.
    private func coordinator(for post: AbstractPost) -> MediaProgressCoordinator {
        var cachedCoordinator: MediaProgressCoordinator?

        progressCoordinatorQueue.sync {
            cachedCoordinator = postMediaProgressCoordinators[post]
        }

        if let cachedCoordinator = cachedCoordinator {
            return cachedCoordinator
        }

        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self

        progressCoordinatorQueue.async(flags: .barrier) {
            self.postMediaProgressCoordinators[post] = coordinator
        }

        return coordinator
    }

    /// - returns: The progress coordinator for the specified media item. Either
    ///            returns a post coordinator if the media item has a post, otherwise
    ///            returns the general media library coordinator.
    private func coordinator(for media: Media) -> MediaProgressCoordinator {
        // Media which is just being uploaded should only belong to at most one post
        if let post = media.posts?.first as? AbstractPost {
            return coordinator(for: post)
        }

        return mediaLibraryProgressCoordinator
    }

    private func removeCoordinator(_ progressCoordinator: MediaProgressCoordinator) {
        if let index = postMediaProgressCoordinators.index(where: { $0.value == progressCoordinator }) {
            progressCoordinatorQueue.async(flags: .barrier) {
                self.postMediaProgressCoordinators.remove(at: index)
            }
        }
    }

    // MARK: - Adding Media

    /// Adds the specified media asset to the specified blog. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter blog: The blog that the asset should be added to.
    /// - parameter origin: The location in the app where the upload was initiated (optional).
    ///
    @discardableResult
    func addMedia(from asset: ExportableAsset, to blog: Blog, origin: MediaUploadOrigin? = nil) -> Media {
        let coordinator = mediaLibraryProgressCoordinator
        return self.addMedia(from: asset, to: blog.objectID, coordinator: coordinator, origin: origin)
    }

    /// Adds the specified media asset to the specified post. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter post: The post that the asset should be added to.
    /// - parameter origin: The location in the app where the upload was initiated (optional).
    ///
    @discardableResult
    func addMedia(from asset: ExportableAsset, to post: AbstractPost, origin: MediaUploadOrigin? = nil) -> Media {
        let coordinator = self.coordinator(for: post)
        return self.addMedia(from: asset, to: post.objectID, coordinator: coordinator, origin: origin)
    }

    @discardableResult
    private func addMedia(from asset: ExportableAsset, to objectID: NSManagedObjectID, coordinator: MediaProgressCoordinator, origin: MediaUploadOrigin? = nil) -> Media {
        coordinator.track(numberOfItems: 1)
        let service = MediaService(managedObjectContext: mainContext)
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
                                if let error = error as NSError? {
                                    if let media = media {
                                        coordinator.attach(error: error as NSError, toMediaID: media.uploadID)
                                        strongSelf.fail(error as NSError, media: media)
                                    } else {
                                        // If there was an error and we don't have a media object we just say to the coordinator that one item was finished
                                        coordinator.finishOneItem()
                                    }
                                    return
                                }
                                guard let media = media, !media.isDeleted else {
                                    return
                                }

                                let uploadProgress = strongSelf.uploadMedia(media, origin: origin)
                                totalProgress.addChild(uploadProgress, withPendingUnitCount: MediaExportProgressUnits.threeQuartersDone)
        })
        processing(media)
        if let creationProgress = creationProgress {
            totalProgress.addChild(creationProgress, withPendingUnitCount: MediaExportProgressUnits.quarterDone)
            coordinator.track(progress: totalProgress, of: media, withIdentifier: media.uploadID)
        }
        return media
    }

    /// Retry the upload of a media object that previously has failed.
    ///
    /// - Parameter media: the media object to retry the upload
    ///
    func retryMedia(_ media: Media) {
        guard media.remoteStatus == .failed else {
            DDLogError("Can't retry Media upload that hasn't failed. \(String(describing: media))")
            return
        }

        let coordinator = self.coordinator(for: media)
        coordinator.track(numberOfItems: 1)
        let uploadProgress = uploadMedia(media)
        coordinator.track(progress: uploadProgress, of: media, withIdentifier: media.uploadID)
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

        let coordinator = self.coordinator(for: media)
        coordinator.track(numberOfItems: 1)
        let uploadProgress = uploadMedia(media)
        coordinator.track(progress: uploadProgress, of: media, withIdentifier: media.uploadID)
    }

    /// Cancels any ongoing upload of the Media and deletes it.
    ///
    /// - Parameter media: the object to cancel and delete
    ///
    func cancelUploadAndDeleteMedia(_ media: Media) {
        cancelUpload(of: media)
        delete(media: [media])
    }

    /// Cancels any ongoing upload for the media object
    ///
    /// - Parameter media: the media object to cancel the upload
    ///
    func cancelUpload(of media: Media) {
        coordinator(for: media).cancelAndStopTrack(of: media.uploadID)
    }

    /// Cancels all ongoing uploads
    ///
    func cancelUploadOfAllMedia(for post: AbstractPost) {
        coordinator(for: post).cancelAndStopAllInProgressMedia()
    }

    /// Deletes a single Media object. If the object is currently being uploaded,
    /// the upload will be cancelled.
    ///
    /// - Parameter media: The media object to delete
    /// - Parameter onProgress: Optional progress block, called after each media item is deleted
    /// - Parameter success: Optional block called after all media items are deleted successfully
    /// - Parameter failure: Optional block called if deletion failed for any media items,
    ///                      after attempted deletion of all media items
    ///
    func delete(_ media: Media, onProgress: ((Progress?) -> Void)? = nil, success: (() -> Void)? = nil, failure: (() -> Void)? = nil) {
        delete(media: [media], onProgress: onProgress, success: success, failure: failure)
    }

    /// Deletes media objects. If the objects are currently being uploaded,
    /// the uploads will be cancelled.
    ///
    /// - Parameter media: The media objects to delete
    /// - Parameter onProgress: Optional progress block, called after each media item is deleted
    /// - Parameter success: Optional block called after all media items are deleted successfully
    /// - Parameter failure: Optional block called if deletion failed for any media items,
    ///                      after attempted deletion of all media items
    ///
    func delete(media: [Media], onProgress: ((Progress?) -> Void)? = nil, success: (() -> Void)? = nil, failure: (() -> Void)? = nil) {
        media.forEach({ self.cancelUpload(of: $0) })

        let service = MediaService(managedObjectContext: backgroundContext)
        service.deleteMedia(media,
                            progress: { onProgress?($0) },
                            success: success,
                            failure: failure)
    }

    @discardableResult private func uploadMedia(_ media: Media, origin: MediaUploadOrigin? = nil) -> Progress {
        let service = MediaService(managedObjectContext: backgroundContext)

        var progress: Progress? = nil
        uploading(media)
        service.uploadMedia(media,
                            progress: &progress,
                            success: {
                                self.trackUploadOf(media, origin: origin)
                                self.end(media)
        }, failure: { error in
            guard let nserror = error as NSError? else {
                return
            }
            self.coordinator(for: media).attach(error: nserror, toMediaID: media.uploadID)
            self.fail(nserror, media: media)
        })
        if let taskProgress = progress {
            return taskProgress
        } else {
            return Progress.discreteCompletedProgress()
        }
    }

    private func trackUploadOf(_ media: Media, origin: MediaUploadOrigin?) {
        guard let origin = origin,
            let event = origin.eventForMediaType(media.mediaType) else {
            return
        }

        let properties = WPAppAnalytics.properties(for: media)
        WPAppAnalytics.track(event,
                             withProperties: properties,
                             with: media.blog)
    }

    // MARK: - Progress

    /// - returns: The current progress for the specified media object.
    ///
    func progress(for media: Media) -> Progress? {
        return coordinator(for: media).progress(forMediaID: media.uploadID)
    }

    /// The global value of progress for all tasks running on the coordinator for the specified post.
    ///
    func totalProgress(for post: AbstractPost) -> Double {
        return coordinator(for: post).totalProgress
    }

    /// Returns the error associated to media if any
    ///
    /// - Parameter media: the media object from where to  fetch the associated error.
    /// - Returns: the error associated to media if any
    ///
    func error(for media: Media) -> NSError? {
        return coordinator(for: media).error(forMediaID: media.uploadID)
    }

    /// Returns the media object for the specified uploadID.
    ///
    /// - Parameter uploadID: the identifier for an ongoing upload
    /// - Returns: The media object for the specified uploadID.
    ///
    func media(withIdentifier uploadID: String, for post: AbstractPost) -> Media? {
        return coordinator(for: post).media(withIdentifier: uploadID)
    }

    /// Returns an existing media objcect with the specificed objectID
    ///
    /// - Parameter objectID: the object unique ID
    /// - Returns: an media object if it exists.
    ///
    func media(withObjectID objectID: String) -> Media? {
        guard let storeCoordinator = mainContext.persistentStoreCoordinator,
            let url = URL(string: objectID),
            let managedObjectID = storeCoordinator.managedObjectID(forURIRepresentation: url),
            let media = try? mainContext.existingObject(with: managedObjectID) as? Media else {
            return nil
        }
        return media
    }

    /// Returns true if any media is being processed or uploading
    ///
    func isUploadingMedia(for post: AbstractPost) -> Bool {
        return coordinator(for: post).isRunning
    }

    /// Returns true if there is any media with a fail state
    ///
    func hasFailedMedia(for post: AbstractPost) -> Bool {
        return coordinator(for: post).hasFailedMedia
    }

    /// Return an array with all failed media IDs
    ///
    func failedMediaIDs(for post: AbstractPost) -> [String] {
        return coordinator(for: post).failedMediaIDs
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

    /// Add an observer to receive updates when media items for a post are updated.
    ///
    /// - parameter onUpdate: A block that will be called whenever media items
    ///                       associated with the specified post are updated.
    ///                       The update block will always be called on the main queue.
    /// - parameter post: The post to receive updates for. The `onUpdate` block
    ///                   for any upload progress changes for any media associated
    ///                   with this post via its media relationship.
    /// - returns: A UUID that can be used to unregister the observer block at a later time.
    ///
    func addObserver(_ onUpdate: @escaping ObserverBlock, forMediaFor post: AbstractPost) -> UUID {
        let uuid = UUID()

        let observer = MediaObserver(post: post, onUpdate: onUpdate)

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
        queue.async {
            self.mediaObservers[uuid] = nil
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

    /// Encapsulates an observer block and an optional observed media item or post.
    struct MediaObserver {
        let media: Media?
        let post: AbstractPost?
        let onUpdate: ObserverBlock

        init(onUpdate: @escaping ObserverBlock) {
            self.media = nil
            self.post = nil
            self.onUpdate = onUpdate
        }

        init(media: Media?, onUpdate: @escaping ObserverBlock) {
            self.media = media
            self.post = nil
            self.onUpdate = onUpdate
        }

        init(post: AbstractPost, onUpdate: @escaping ObserverBlock) {
            self.media = nil
            self.post = post
            self.onUpdate = onUpdate
        }
    }

    /// Utility method to return all observers for a specific media item,
    /// including any 'wildcard' observers that are observing _all_ media items.
    ///
    private func observersForMedia(_ media: Media) -> [MediaObserver] {
        let mediaObservers = self.mediaObservers.values.filter({ $0.media?.mediaID == media.mediaID })

        let postObservers = self.mediaObservers.values.filter({
            guard let posts = media.posts,
                let post = $0.post else { return false }

            return posts.contains(post)
        })

        return mediaObservers + postObservers + wildcardObservers
    }

    /// Utility method to return all 'wildcard' observers that are
    /// observing _all_ media items.
    ///
    private var wildcardObservers: [MediaObserver] {
        return mediaObservers.values.filter({ $0.media == nil && $0.post == nil })
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
                DispatchQueue.main.async {
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
        // Currently, we only want to show a successful upload notice for uploads
        // initiated within the media library.
        if mediaProgressCoordinator == mediaLibraryProgressCoordinator {
            let model = MediaProgressCoordinatorNoticeViewModel(mediaProgressCoordinator: mediaProgressCoordinator)
            if let notice = model?.notice {
                ActionDispatcher.dispatch(NoticeAction.post(notice))
            }
        }

        mediaProgressCoordinator.stopTrackingOfAllMedia()

        if mediaProgressCoordinator != mediaLibraryProgressCoordinator {
            removeCoordinator(mediaProgressCoordinator)
        }
    }
}

extension Media {
    var uploadID: String {
        return objectID.uriRepresentation().absoluteString
    }
}

/// Used for analytics to track where an upload was started within the app.
/// Currently only supports media library, but we'll add editor support
/// when we bring async there.
///
enum MediaUploadOrigin {
    case mediaLibrary

    func eventForMediaType(_ mediaType: MediaType) -> WPAnalyticsStat? {
        switch (self, mediaType) {
        case (.mediaLibrary, .image):
            return .mediaLibraryAddedPhoto
        case (.mediaLibrary, .video):
            return .mediaLibraryAddedVideo
        default: return nil
        }
    }
}
