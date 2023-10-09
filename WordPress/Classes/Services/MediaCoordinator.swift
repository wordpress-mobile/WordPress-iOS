import Foundation
import WordPressFlux

import class AutomatticTracks.CrashLogging
import enum Alamofire.AFError

/// MediaCoordinator is responsible for creating and uploading new media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaCoordinator: NSObject {
    @objc static let shared = MediaCoordinator()

    private let coreDataStack: CoreDataStackSwift

    private var mainContext: NSManagedObjectContext {
        coreDataStack.mainContext
    }

    private let syncOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "org.wordpress.mediauploadcoordinator.sync"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

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

    private let mediaServiceFactory: MediaService.Factory

    init(_ mediaServiceFactory: MediaService.Factory = MediaService.Factory(), coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.mediaServiceFactory = mediaServiceFactory
        self.coreDataStack = coreDataStack

        super.init()

        addObserverForDeletedFiles()
    }

    /// Uploads all failed media for the post, and returns `true` if it was possible to start
    /// uploads for all of the existing media for the post.
    ///
    /// - Parameters:
    ///     - post: the post to get the media to upload from.
    ///     - automatedRetry: true if this call is the result of an automated upload-retry attempt.
    ///
    /// - Returns: `true` if all media in the post is uploading or was uploaded, `false` otherwise.
    ///
    func uploadMedia(for post: AbstractPost, automatedRetry: Bool = false) -> Bool {
        let failedMedia: [Media] = post.media.filter({ $0.remoteStatus == .failed })
        let mediasToUpload: [Media]

        if automatedRetry {
            mediasToUpload = Media.failedForUpload(in: post, automatedRetry: automatedRetry)
        } else {
            mediasToUpload = failedMedia
        }

        mediasToUpload.forEach { mediaObject in
            retryMedia(mediaObject, automatedRetry: automatedRetry)
        }

        let isPushingAllPendingMedia = mediasToUpload.count == failedMedia.count
        return isPushingAllPendingMedia
    }

    /// - returns: The progress coordinator for the specified post. If a coordinator
    ///            does not exist, one will be created.
    private func coordinator(for post: AbstractPost) -> MediaProgressCoordinator {
        if let cachedCoordinator = cachedCoordinator(for: post) {
            return cachedCoordinator
        }

        // Use the original post so we don't create new coordinators for post revisions
        let original = post.original ?? post

        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self

        progressCoordinatorQueue.async(flags: .barrier) {
            self.postMediaProgressCoordinators[original] = coordinator
        }

        return coordinator
    }

    /// - returns: The progress coordinator for the specified post, or nil
    ///            if one does not exist.
    private func cachedCoordinator(for post: AbstractPost) -> MediaProgressCoordinator? {
        // Use the original post so we don't create new coordinators for post revisions
        let original = post.original ?? post

        return progressCoordinatorQueue.sync {
            return postMediaProgressCoordinators[original]
        }
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
        progressCoordinatorQueue.async(flags: .barrier) {
            if let index = self.postMediaProgressCoordinators.firstIndex(where: { $0.value == progressCoordinator }) {
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
    func addMedia(from asset: ExportableAsset, to blog: Blog, analyticsInfo: MediaAnalyticsInfo? = nil) {
        addMedia(from: asset, blog: blog, post: nil, coordinator: mediaLibraryProgressCoordinator, analyticsInfo: analyticsInfo)
    }

    /// Adds the specified media asset to the specified post. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter post: The post that the asset should be added to.
    /// - parameter origin: The location in the app where the upload was initiated (optional).
    ///
    @discardableResult
    func addMedia(from asset: ExportableAsset, to post: AbstractPost, analyticsInfo: MediaAnalyticsInfo? = nil) -> Media? {
        addMedia(from: asset, post: post, coordinator: coordinator(for: post), analyticsInfo: analyticsInfo)
    }

    /// Create a `Media` instance from the main context and upload the asset to the Meida Library.
    ///
    /// - Warning: This function must be called from the main thread.
    ///
    /// - SeeAlso: `MediaImportService.createMedia(with:blog:post:thumbnailCallback:completion:)`
    private func addMedia(from asset: ExportableAsset, post: AbstractPost, coordinator: MediaProgressCoordinator, analyticsInfo: MediaAnalyticsInfo? = nil) -> Media? {
        coordinator.track(numberOfItems: 1)
        let service = MediaImportService(coreDataStack: coreDataStack)
        let totalProgress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        let result = service.createMedia(
            with: asset,
            blog: post.blog,
            post: post,
            thumbnailCallback: { [weak self] media, url in
                self?.thumbnailReady(url: url, for: media)
            },
            completion: { [weak self] media, error in
                self?.handleMediaImportResult(coordinator: coordinator, totalProgress: totalProgress, analyticsInfo: analyticsInfo, media: media, error: error)
            }
        )
        guard let (media, creationProgress) = result else {
            return nil
        }

        processing(media)

        totalProgress.addChild(creationProgress, withPendingUnitCount: MediaExportProgressUnits.exportDone)
        coordinator.track(progress: totalProgress, of: media, withIdentifier: media.uploadID)

        return media
    }

    /// Create a `Media` instance and upload the asset to the Meida Library.
    ///
    /// - SeeAlso: `MediaImportService.createMedia(with:blog:post:receiveUpdate:thumbnailCallback:completion:)`
    private func addMedia(from asset: ExportableAsset, blog: Blog, post: AbstractPost?, coordinator: MediaProgressCoordinator, analyticsInfo: MediaAnalyticsInfo? = nil) {
        coordinator.track(numberOfItems: 1)
        let service = MediaImportService(coreDataStack: coreDataStack)
        let totalProgress = Progress.discreteProgress(totalUnitCount: MediaExportProgressUnits.done)
        let creationProgress = service.createMedia(
            with: asset,
            blog: blog,
            post: post,
            receiveUpdate: { [weak self] media in
                self?.processing(media)
                coordinator.track(progress: totalProgress, of: media, withIdentifier: media.uploadID)
            },
            thumbnailCallback: { [weak self] media, url in
                self?.thumbnailReady(url: url, for: media)
            },
            completion: { [weak self] media, error in
                self?.handleMediaImportResult(coordinator: coordinator, totalProgress: totalProgress, analyticsInfo: analyticsInfo, media: media, error: error)
            }
        )

        totalProgress.addChild(creationProgress, withPendingUnitCount: MediaExportProgressUnits.exportDone)
    }

    private func handleMediaImportResult(coordinator: MediaProgressCoordinator, totalProgress: Progress, analyticsInfo: MediaAnalyticsInfo?, media: Media?, error: Error?) -> Void {
        if let error = error as NSError? {
            if let media = media {
                coordinator.attach(error: error as NSError, toMediaID: media.uploadID)
                fail(error as NSError, media: media)
            } else {
                // If there was an error and we don't have a media object we just say to the coordinator that one item was finished
                coordinator.finishOneItem()
            }
            return
        }
        guard let media = media, !media.isDeleted else {
            return
        }

        trackUploadOf(media, analyticsInfo: analyticsInfo)

        let uploadProgress = uploadMedia(media)
        totalProgress.addChild(uploadProgress, withPendingUnitCount: MediaExportProgressUnits.uploadDone)
    }

    /// Retry the upload of a media object that previously has failed.
    ///
    /// - Parameters:
    ///     - media: the media object to retry the upload
    ///     - automatedRetry: whether the retry was automatically or manually initiated.
    ///
    func retryMedia(_ media: Media, automatedRetry: Bool = false, analyticsInfo: MediaAnalyticsInfo? = nil) {
        guard media.remoteStatus == .failed else {
            DDLogError("Can't retry Media upload that hasn't failed. \(String(describing: media))")
            return
        }

        trackRetryUploadOf(media, analyticsInfo: analyticsInfo)

        let coordinator = self.coordinator(for: media)

        coordinator.track(numberOfItems: 1)
        let uploadProgress = uploadMedia(media, automatedRetry: automatedRetry)
        coordinator.track(progress: uploadProgress, of: media, withIdentifier: media.uploadID)
    }

    /// Starts the upload of an already existing local media object
    ///
    /// - Parameter media: the media to upload
    /// - Parameter post: the post where media is being inserted
    /// - parameter origin: The location in the app where the upload was initiated (optional).
    ///
    func addMedia(_ media: Media, to post: AbstractPost, analyticsInfo: MediaAnalyticsInfo? = nil) {
        guard media.remoteStatus == .local else {
            DDLogError("Can't try to upload Media that isn't local only. \(String(describing: media))")
            return
        }
        media.addPostsObject(post)
        let coordinator = self.coordinator(for: post)
        coordinator.track(numberOfItems: 1)
        trackUploadOf(media, analyticsInfo: analyticsInfo)
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
    /// the upload will be canceled.
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
    /// the uploads will be canceled.
    ///
    /// - Parameter media: The media objects to delete
    /// - Parameter onProgress: Optional progress block, called after each media item is deleted
    /// - Parameter success: Optional block called after all media items are deleted successfully
    /// - Parameter failure: Optional block called if deletion failed for any media items,
    ///                      after attempted deletion of all media items
    ///
    func delete(media: [Media], onProgress: ((Progress?) -> Void)? = nil, success: (() -> Void)? = nil, failure: (() -> Void)? = nil) {
        media.forEach({ self.cancelUpload(of: $0) })

        coreDataStack.performAndSave { context in
            let service = self.mediaServiceFactory.create(context)
            service.deleteMedia(media,
                                progress: { onProgress?($0) },
                                success: success,
                                failure: failure)
        }
    }

    @discardableResult
    private func uploadMedia(_ media: Media, automatedRetry: Bool = false) -> Progress {
        let resultProgress = Progress.discreteProgress(totalUnitCount: 100)

        let success: () -> Void = {
            self.end(media)
        }
        let failure: (Error?) -> Void = { error in
            // Ideally the upload service should always return an error.  This may be easier to enforce
            // if we update the service to Swift, but in the meanwhile I'm instantiating an unknown upload
            // error whenever the service doesn't provide one.
            //
            let nserror = error as NSError?
                ?? NSError(
                    domain: MediaServiceErrorDomain,
                    code: MediaServiceError.unknownUploadError.rawValue,
                    userInfo: [
                        "filename": media.filename ?? "",
                        "filesize": media.filesize ?? "",
                        "height": media.height ?? "",
                        "width": media.width ?? "",
                        "localURL": media.localURL ?? "",
                        "remoteURL": media.remoteURL ?? "",
                ])

            self.coordinator(for: media).attach(error: nserror, toMediaID: media.uploadID)
            self.fail(nserror, media: media)
        }

        // For some reason, this `MediaService` instance has to be created with the main context, otherwise
        // the successfully uploaded media is shown as a "local" assets incorrectly (see the issue comment linked below).
        // https://github.com/wordpress-mobile/WordPress-iOS/issues/20298#issuecomment-1465319707
        let service = self.mediaServiceFactory.create(coreDataStack.mainContext)
        var progress: Progress? = nil
        service.uploadMedia(media, automatedRetry: automatedRetry, progress: &progress, success: success, failure: failure)
        if let progress {
            resultProgress.addChild(progress, withPendingUnitCount: resultProgress.totalUnitCount)
        }

        uploading(media, progress: resultProgress)

        return resultProgress
    }

    private func trackUploadOf(_ media: Media, analyticsInfo: MediaAnalyticsInfo?) {
        guard let info = analyticsInfo else {
            return
        }

        guard let event = info.eventForMediaType(media.mediaType) else {
            // Fall back to the WPShared event tracking
            trackUploadViaWPSharedOf(media, analyticsInfo: analyticsInfo)
            return
        }

        let properties = info.properties(for: media)
        WPAnalytics.track(event, properties: properties, blog: media.blog)
    }

    private func trackUploadViaWPSharedOf(_ media: Media, analyticsInfo: MediaAnalyticsInfo?) {
        guard let info = analyticsInfo,
            let event = info.wpsharedEventForMediaType(media.mediaType) else {
            return
        }

        let properties = info.properties(for: media)
        WPAppAnalytics.track(event,
                             withProperties: properties,
                             with: media.blog)
    }

    private func trackRetryUploadOf(_ media: Media, analyticsInfo: MediaAnalyticsInfo?) {
        guard let info = analyticsInfo,
            let event = info.retryEvent else {
                return
        }

        let properties = info.properties(for: media)
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
        return cachedCoordinator(for: post)?.totalProgress ?? 0
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
            let managedObjectID = storeCoordinator.safeManagedObjectID(forURIRepresentation: url),
            let media = try? mainContext.existingObject(with: managedObjectID) as? Media else {
            return nil
        }
        return media
    }

    /// Returns true if any media is being processed or uploading
    ///
    func isUploadingMedia(for post: AbstractPost) -> Bool {
        return cachedCoordinator(for: post)?.isRunning ?? false
    }

    /// Returns true if there is any media with a fail state
    ///
    @objc
    func hasFailedMedia(for post: AbstractPost) -> Bool {
        return cachedCoordinator(for: post)?.hasFailedMedia ?? false
    }

    /// Return an array with all failed media IDs
    ///
    func failedMediaIDs(for post: AbstractPost) -> [String] {
        return cachedCoordinator(for: post)?.failedMediaIDs ?? []
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
    @discardableResult
    func addObserver(_ onUpdate: @escaping ObserverBlock, for media: Media? = nil) -> UUID {
        let uuid = UUID()

        let observer = MediaObserver(
            subject: media.flatMap({ .media(id: $0.objectID) }) ?? .all,
            onUpdate: onUpdate
        )

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
    @discardableResult
    func addObserver(_ onUpdate: @escaping ObserverBlock, forMediaFor post: AbstractPost) -> UUID {
        let uuid = UUID()

        let original = post.original ?? post
        let observer = MediaObserver(subject: .post(id: original.objectID), onUpdate: onUpdate)

        queue.async {
            self.mediaObservers[uuid] = observer
        }

        return uuid
    }

    /// Removes the observer block for the specified UUID.
    ///
    /// - parameter uuid: The UUID that matches the observer to be removed.
    ///
    @objc
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
        case uploading(progress: Progress)
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
    private struct MediaObserver {
        enum Subject: Equatable {
            case media(id: NSManagedObjectID)
            case post(id: NSManagedObjectID)
            case all
        }

        let subject: Subject
        let onUpdate: ObserverBlock
    }

    /// Utility method to return all observers for a `Media` item with the given `NSManagedObjectID`
    /// and part of the posts with given `NSManagedObjectID`s, including any 'wildcard' observers
    /// that are observing _all_ media items.
    ///
    private func observersForMedia(withObjectID mediaObjectID: NSManagedObjectID, originalPostIDs: [NSManagedObjectID]) -> [MediaObserver] {
        let mediaObservers = self.mediaObservers.values.filter({ $0.subject == .media(id: mediaObjectID) })

        let postObservers = self.mediaObservers.values.filter({
            guard case let .post(postObjectID) = $0.subject else { return false }

            return originalPostIDs.contains(postObjectID)
        })

        return mediaObservers + postObservers + wildcardObservers
    }

    /// Utility method to return all 'wildcard' observers that are
    /// observing _all_ media items.
    ///
    private var wildcardObservers: [MediaObserver] {
        return mediaObservers.values.filter({ $0.subject == .all })
    }

    // MARK: - Notifying observers

    /// Notifies observers that a media item is processing/importing.
    ///
    func processing(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .processing)
    }
    /// Notifies observers that a media item has begun uploading.
    ///
    func uploading(_ media: Media, progress: Progress) {
        notifyObserversForMedia(media, ofStateChange: .uploading(progress: progress))
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
        let originalPostIDs: [NSManagedObjectID] = coreDataStack.performQuery { context in
            guard let mediaInContext = try? context.existingObject(with: media.objectID) as? Media else {
                return []
            }

            return mediaInContext.posts?.compactMap { (object: AnyHashable) in
                guard let post = object as? AbstractPost else {
                    return nil
                }
                return (post.original ?? post).objectID
            } ?? []
        }

        queue.async {
            self.observersForMedia(withObjectID: media.objectID, originalPostIDs: originalPostIDs).forEach({ observer in
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
        syncOperationQueue.addOperation(AsyncBlockOperation { done in
            self.coreDataStack.performAndSave { context in
                let service = self.mediaServiceFactory.create(context)
                service.syncMediaLibrary(
                    for: blog,
                    success: {
                        done()
                        success?()
                    },
                    failure: { error in
                        done()
                        failure?(error)
                    }
                )
            }
        })

    }

    /// This method checks the status of all media objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of media are happening.
    ///
    @objc func refreshMediaStatus() {
        Media.refreshMediaStatus(using: coreDataStack)
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
        // We only want to show an upload notice for uploads initiated within
        // the media library.
        // If the errors are causes by a missing file, we want to ignore that too.

        let allFailedMediaErrorsAreMissingFilesErrors = mediaProgressCoordinator.failedMedia.allSatisfy { $0.hasMissingFileError }

        let allFailedMediaHaveAssociatedPost = mediaProgressCoordinator.failedMedia.allSatisfy { $0.hasAssociatedPost() }

        if mediaProgressCoordinator.failedMedia.isEmpty || (!allFailedMediaErrorsAreMissingFilesErrors && !allFailedMediaHaveAssociatedPost),
           mediaProgressCoordinator == mediaLibraryProgressCoordinator || mediaProgressCoordinator.hasFailedMedia {

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

extension MediaCoordinator {
    // Based on user logs we've collected for users, we've noticed the app sometimes
    // trying to upload a Media object and failing because the underlying file has disappeared from
    // `Documents` folder.
    // We want to collect more data about that, so we're going to log that info to Sentry,
    // and also delete the `Media` object, since there isn't really a reasonable way to recover from that failure.
    func addObserverForDeletedFiles() {
        addObserver({ (media, _) in
            guard let mediaError = media.error,
                media.hasMissingFileError else {
                return
            }

            self.cancelUploadAndDeleteMedia(media)
            WordPressAppDelegate.crashLogging?.logMessage("Deleting a media object that's failed to upload because of a missing local file. \(mediaError)")

        }, for: nil)
    }
}

extension Media {
    var uploadID: String {
        return objectID.uriRepresentation().absoluteString
    }

    fileprivate var hasMissingFileError: Bool {
        // So this is weirdly complicated for a weird reason.
        // Turns out, Core Data and Swift-y `Error`s do not play super well together, but there's some magic here involved.
        // If you assing an `Error` property to a Core Data's object field, it will retain all it's Swifty-ish magic properties,
        // it'll have all the enum values you expect, etc.
        // However.
        // Persisting the data to disk and/or reading it from a different MOC using methods like `existingObjectWithID(:_)`
        // or similar, loses all that data, and the resulting error is "simplified" down to a "dumb"
        // `NSError` with just a `domain` and `code` set.
        // This was _not_ a fun one to track down.

        // I don't want to hand-encode the Alamofire.AFError domain and/or code — they're both subject to change
        // in the future, so I'm hand-creating an error here to get the domain/code out of.
        let multipartEncodingFailedSampleError = AFError.multipartEncodingFailed(reason: .bodyPartFileNotReachable(at: URL(string: "https://wordpress.com")!)) as NSError
        // (yes, yes, I know, unwrapped optional. but if creating a URL from this string fails, then something is probably REALLY wrong and we should bail anyway.)

        // If we still have enough data to know this is a Swift Error, let's do the actual right thing here:
        if let afError = error as? AFError {
            guard
                case .multipartEncodingFailed = afError,
                case .multipartEncodingFailed(let encodingFailure) = afError else {
                    return false
            }

            switch encodingFailure {
            case .bodyPartFileNotReachableWithError,
                 .bodyPartFileNotReachable:
                return true
            default:
                return false
            }
        } else if let nsError = error as NSError?,
            nsError.domain == multipartEncodingFailedSampleError.domain,
            nsError.code == multipartEncodingFailedSampleError.code {
            // and if we only have the NSError-level of data, let's just fall back on best-effort guess.
            return true
        } else if let nsError = error as NSError?,
            nsError.domain == MediaServiceErrorDomain,
            nsError.code == MediaServiceError.fileDoesNotExist.rawValue {
            // if for some reason, the app crashed when trying to create a media object (like, for example, in this crash):
            // https://github.com/wordpress-mobile/gutenberg-mobile/issues/1190
            // the Media objects ends up in a malformed state, and we acutally handle that on the
            // MediaService level. We need to also handle it here!

            return true
        }

        return false
    }
}
