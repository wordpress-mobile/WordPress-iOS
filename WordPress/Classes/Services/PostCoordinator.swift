import AutomatticTracks
import Aztec
import AztecExtensions
import Combine
import Foundation
import WordPressData
import WordPressKit
import WordPressFlux

protocol PostCoordinatorDelegate: AnyObject {
    func postCoordinator(_ postCoordinator: PostCoordinator, promptForPasswordForBlog blog: Blog)
}

class PostCoordinator: NSObject {

    enum SavingError: Error, LocalizedError, CustomNSError {
        /// One of the media uploads failed.
        case mediaFailure(AbstractPost, Error)
        /// The upload has been failing for too long.
        case maximumRetryTimeIntervalReached

        var errorDescription: String? {
            SharedStrings.Error.generic
        }

        var errorUserInfo: [String: Any] {
            switch self {
            case .mediaFailure(_, let error):
                return [NSUnderlyingErrorKey: error]
            case .maximumRetryTimeIntervalReached:
                return [:]
            }
        }
    }

    @objc static let shared = PostCoordinator()

    /// Events about the sync status changes.
    let syncEvents = PassthroughSubject<SyncEvent, Never>()

    private let coreDataStack: CoreDataStackSwift

    private var mainContext: NSManagedObjectContext {
        coreDataStack.mainContext
    }

    weak var delegate: PostCoordinatorDelegate?

    private let queue = DispatchQueue(label: "org.wordpress.postcoordinator")

    private var workers: [NSManagedObjectID: SyncWorker] = [:]
    private var pendingPostIDs: Set<NSManagedObjectID> = []
    private var observerUUIDs: [AbstractPost: UUID] = [:]

    private let mediaCoordinator: MediaCoordinator
    private let actionDispatcherFacade: ActionDispatcherFacade

    /// The initial sync retry delay. By default, 15 seconds.
    var syncRetryDelay: TimeInterval = 15

    // MARK: - Initializers

    init(mediaCoordinator: MediaCoordinator? = nil,
         actionDispatcherFacade: ActionDispatcherFacade = ActionDispatcherFacade(),
         coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
        self.mediaCoordinator = mediaCoordinator ?? MediaCoordinator.shared
        self.actionDispatcherFacade = actionDispatcherFacade

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateReachability), name: .reachabilityChanged, object: nil)
    }

    struct PublishingOptions {
        var visibility: PostVisibility
        var password: String?
        var publishDate: Date?

        init(visibility: PostVisibility, password: String?, publishDate: Date?) {
            self.visibility = visibility
            self.password = password
            self.publishDate = publishDate
        }
    }

    /// Publishes the post according to the current settings and user capabilities.
    ///
    /// - warning: Before publishing, ensure that the media for the post got
    /// uploaded. Managing media is not the responsibility of `PostRepository.`
    @MainActor
    func publish(_ post: AbstractPost, options: PublishingOptions) async throws {
        wpAssert(post.isOriginal())
        wpAssert(post.isStatus(in: [.draft, .pending]))

        await pauseSyncing(for: post)
        defer { resumeSyncing(for: post) }

        var parameters = RemotePostUpdateParameters()
        switch options.visibility {
        case .public, .protected:
            parameters.status = Post.Status.publish.rawValue
        case .private:
            parameters.status = Post.Status.publishPrivate.rawValue
        }
        let latest = post.latest()
        if (latest.password ?? "") != (options.password ?? "") {
            parameters.password = options.password
        }
        if let publishDate = options.publishDate {
            parameters.date = publishDate
        } else {
            // If the post was previously scheduled for a different date,
            // the app has to send a new value to override it.
            parameters.date = post.shouldPublishImmediately() ? nil : Date()
        }

        do {
            let repository = PostRepository(coreDataStack: coreDataStack)
            try await repository.save(post, changes: parameters)
            didPublish(post)
            show(PostCoordinator.makeUploadSuccessNotice(for: post))
        } catch {
            trackError(error, operation: "post-publish", post: post)
            handleError(error, for: post)
            throw error
        }
    }

    @MainActor
    private func didPublish(_ post: AbstractPost) {
        if post.status == .scheduled {
            notifyNewPostScheduled()
        } else if post.status == .publish {
            notifyNewPostPublished()
        }
        SearchManager.shared.indexItem(post)
        AppRatingUtility.shared.incrementSignificantEvent()
    }

    /// Uploads the changes made to the post to the server.
    @discardableResult @MainActor
    func save(_ post: AbstractPost, changes: RemotePostUpdateParameters? = nil) async throws -> AbstractPost {
        let post = post.original()

        await pauseSyncing(for: post)
        defer { resumeSyncing(for: post) }

        do {
            let previousStatus = post.status
            try await PostRepository().save(post, changes: changes)
            show(PostCoordinator.makeUploadSuccessNotice(for: post, previousStatus: previousStatus))
            return post
        } catch {
            trackError(error, operation: "post-save", post: post)
            handleError(error, for: post)
            throw error
        }
    }

    /// Patches the post.
    ///
    @MainActor
    private func update(_ post: AbstractPost, changes: RemotePostUpdateParameters) async throws {
        wpAssert(post.isOriginal())

        let post = post.original()
        do {
            try await PostRepository(coreDataStack: coreDataStack).update(post, changes: changes)
        } catch {
            trackError(error, operation: "post-patch", post: post)
            handleError(error, for: post)
            throw error
        }
    }

    func handleError(_ error: Error, for post: AbstractPost) {
        guard let topViewController = UIApplication.shared.mainWindow?.topmostPresentedViewController else {
            wpAssertionFailure("Failed to show an error alert")
            return
        }
        let alert = UIAlertController(title: SharedStrings.Error.generic, message: error.localizedDescription, preferredStyle: .alert)
        if let error = error as? PostRepository.PostSaveError {
            switch error {
            case .conflict(let latest):
                alert.addDefaultActionWithTitle(SharedStrings.Button.ok) { [weak self] _ in
                    self?.showResolveConflictView(post: post, remoteRevision: latest, source: .editor)
                }
            case .deleted:
                alert.addDefaultActionWithTitle(SharedStrings.Button.ok) { [weak self] _ in
                    self?.handlePermanentlyDeleted(post)
                }
            }
        } else {
            alert.addDefaultActionWithTitle(SharedStrings.Button.ok, handler: nil)
        }
        topViewController.present(alert, animated: true)
    }

    private func trackError(_ error: Error, operation: String, post: AbstractPost) {
        DDLogError("post-coordinator-\(operation)-failed: \(error)")

        if let error = error as? TrackableErrorProtocol, var userInfo = error.getTrackingUserInfo() {
            userInfo["operation"] = operation
            for (key, value) in post.analyticsUserInfo {
                userInfo[key] = String(describing: value)
            }
            if let postID = post.postID {
                userInfo["post_id"] = postID.description
            }
            WPAnalytics.track(.postCoordinatorErrorEncountered, properties: userInfo, blog: post.blog)
        }
    }

    func showResolveConflictView(post: AbstractPost, remoteRevision: RemotePost, source: ResolveConflictView.Source) {
        wpAssert(post.isOriginal())
        guard let topViewController = UIApplication.shared.mainWindow?.topmostPresentedViewController else {
            wpAssertionFailure("Failed to show conflict resolution view")
            return
        }
        let repository = PostRepository(coreDataStack: coreDataStack)
        let controller = ResolveConflictViewController(post: post, remoteRevision: remoteRevision, repository: repository, source: source)
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }

    func didResolveConflict(for post: AbstractPost) {
        postConflictResolvedNotification(for: post)
        startSync(for: post) // Clears the error associated with the post
    }

    private func handlePermanentlyDeleted(_ post: AbstractPost) {
        let context = coreDataStack.mainContext
        context.deleteObject(post)
        ContextManager.shared.saveContextAndWait(context)
    }

    private func show(_ notice: Notice) {
        actionDispatcherFacade.dispatch(NoticeAction.post(notice))
    }

    func moveToDraft(_ post: AbstractPost) {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.draft.rawValue
        performChanges(changes, for: post)
    }

    /// Restores a trashed post by moving it to draft.
    @MainActor
    func restore(_ post: AbstractPost) async throws {
        wpAssert(post.isOriginal())

        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.draft.rawValue
        try await update(post, changes: changes)
    }

    /// Sets the post state to "updating" and performs the given changes.
    private func performChanges(_ changes: RemotePostUpdateParameters, for post: AbstractPost) {
        Task { @MainActor in
            let post = post.original()
            setUpdating(true, for: post)
            defer { setUpdating(false, for: post) }

            try await self.update(post, changes: changes)
        }
    }

    // MARK: - Sync

    /// Returns `true` if the post is eligible for syncing.
    func isSyncAllowed(for post: AbstractPost) -> Bool {
        post.status == .draft || post.status == .pending
    }

    /// Returns `true` if post has any revisions that need to be synced.
    func isSyncNeeded(for post: AbstractPost) -> Bool {
        post.original().getLatestRevisionNeedingSync() != nil
    }

    /// Sets a flag to sync the given revision and schedules the next sync.
    ///
    /// - warning: Should only be used for draft posts.
    func setNeedsSync(for revision: AbstractPost) {
        wpAssert(revision.isRevision(), "Must be used only on revisions")
        wpAssert(isSyncAllowed(for: revision.original()), "Sync is not supported for this post")

        if !revision.isSyncNeeded {
            revision.remoteStatus = .syncNeeded
            revision.confirmedChangesTimestamp = Date()
            ContextManager.shared.saveContextAndWait(coreDataStack.mainContext)
        }
        startSync(for: revision.original())
    }

    func retrySync(for post: AbstractPost) {
        wpAssert(post.isOriginal())

        guard let revision = post.getLatestRevisionNeedingSync() else {
            return
        }
        revision.confirmedChangesTimestamp = Date()
        ContextManager.shared.saveContextAndWait(coreDataStack.mainContext)

        getWorker(for: post).showNextError = true
        startSync(for: post)
    }

    /// Schedules sync for all the posts with revisions that need syncing.
    ///
    /// - note: It should typically only be called once during the app launch.
    func initializeSync() {
        let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
        request.predicate = NSPredicate(format: "remoteStatusNumber == %i", AbstractPostRemoteStatus.syncNeeded.rawValue)
        do {
            let revisions = try coreDataStack.mainContext.fetch(request)
            let originals = Set(revisions.map { $0.original() })
            for post in originals {
                startSync(for: post)
            }
        } catch {
            DDLogError("failed to scheduled sync: \(error)")
        }
    }

    /// Safely pauses sync for the post. If there are any outstanding operations
    /// that can't be canceled, allowing them to finish. When the method returns,
    /// it's guaranteed that no requests will be sent until resumed.
    @MainActor
    func pauseSyncing(for post: AbstractPost) async {
        wpAssert(post.isOriginal())
        guard isSyncAllowed(for: post) else { return }

        guard let worker = workers[post.objectID] else {
            return
        }
        worker.isPaused = true
        worker.log("paused")
        guard let operation = worker.operation else {
            return
        }
        tryCancelSyncOperation(operation)
        if operation.isCancelled {
            return // Cancelled immediatelly
        }
        _ = await syncEvents.first(where: { [expected = operation] event in
            if case .finished(let operation, _) = event, operation === expected {
                return true
            }
            return false
        }).values.first(where: { _ in true })
    }

    /// Resumes sync for the given post.
    @MainActor
    func resumeSyncing(for post: AbstractPost) {
        wpAssert(post.isOriginal())
        guard isSyncAllowed(for: post) else { return }

        guard let worker = workers[post.objectID] else {
            return
        }
        worker.isPaused = false
        worker.log("resumed")
        startSync(for: post)
    }

    /// A manages sync for the given post. Every post has its own worker.
    private final class SyncWorker {
        /// Defines for how many days (in seconds) the app should continue trying
        /// to upload the post before giving up and requiring manual intervention.
        static let maximumRetryTimeInterval: TimeInterval = 86400 * 3 // 3 days

        let post: AbstractPost
        var isPaused = false
        var operation: SyncOperation? // The sync operation that's currently running
        var error: Error? // The previous sync error

        var nextRetryDelay: TimeInterval {
            retryDelay = min(120, retryDelay * 2)
            return retryDelay
        }

        var retryDelay: TimeInterval
        weak var retryTimer: Timer?
        var showNextError = false

        deinit {
            self.log("deinit")
        }

        init(post: AbstractPost, retryDelay: TimeInterval) {
            self.post = post
            self.retryDelay = retryDelay
            self.log("created for \"\(post.postTitle ?? "–")\"")
        }

        func log(_ string: String) {
            DDLogInfo("sync-worker(\(post.objectID.shortDescription)) \(string)")
        }
    }

    /// An operation for syncing post to the given local revision.
    final class SyncOperation {
        let id: Int
        let post: AbstractPost
        let revision: AbstractPost
        var state: State = .uploadingMedia // The first step is always media
        var isCancelled = false

        enum State {
            case uploadingMedia
            case syncing
            case finished(Result<Void, Error>)
        }

        private static var nextId = 1

        init(post: AbstractPost, revision: AbstractPost) {
            self.post = post
            self.revision = revision
            self.id = SyncOperation.nextId
            SyncOperation.nextId += 1
            self.log("created for \"\(post.postTitle ?? "–")\"")
        }

        func log(_ string: String) {
            DDLogInfo("sync-operation(\(id)) (\(post.objectID.shortDescription)→\(revision.objectID.shortDescription))) \(string)")
        }
    }

    enum SyncEvent {
        /// A sync worker started a sync operation.
        case started(operation: SyncOperation)
        /// A sync worker finished a sync operation.
        ///
        /// - warning: By the time operation completes, the revision will be deleted.
        case finished(operation: SyncOperation, result: Result<Void, Error>)
    }

    private func startSync(for post: AbstractPost) {
        if let worker = workers[post.objectID], worker.error != nil {
            worker.error = nil
            postDidUpdateNotification(for: post)
        }
        guard let revision = post.getLatestRevisionNeedingSync() else {
            return DDLogInfo("sync: \(post.objectID.shortDescription) is already up to date")
        }
        startSync(for: post, revision: revision)
    }

    private func startSync(for post: AbstractPost, revision: AbstractPost) {
        wpAssert(Thread.isMainThread)
        wpAssert(post.isOriginal())
        wpAssert(!post.objectID.isTemporaryID)

        let worker = getWorker(for: post)

        if let date = revision.confirmedChangesTimestamp,
           Date.now.timeIntervalSince(date) > SyncWorker.maximumRetryTimeInterval {
            worker.error = PostCoordinator.SavingError.maximumRetryTimeIntervalReached
            postDidUpdateNotification(for: post)
            return worker.log("stopping – failing to upload changes for too long")
        }

        guard !worker.isPaused else {
            return worker.log("start failed: worker is paused")
        }

        if let operation = worker.operation {
            guard operation.revision != revision else {
                return worker.log("already syncing to the latest revision")
            }
            tryCancelSyncOperation(operation)
            guard operation.isCancelled else {
                return worker.log("waiting until the current operation finishes")
            }
        } else {
            worker.retryTimer?.invalidate()
        }

        let operation = SyncOperation(post: post, revision: revision)
        worker.operation = operation
        startSyncOperation(operation)
        syncEvents.send(.started(operation: operation))
    }

    private func getWorker(for post: AbstractPost) -> SyncWorker {
        let worker = workers[post.objectID] ?? SyncWorker(post: post, retryDelay: syncRetryDelay)
        workers[post.objectID] = worker
        return worker
    }

    /// Try to cancel the current sync operation, which is not always possible.
    private func tryCancelSyncOperation(_ operation: SyncOperation) {
        switch operation.state {
        case .uploadingMedia:
            operation.isCancelled = true
            syncOperation(operation, didFinishWithResult: .failure(CancellationError())) // Finish immediatelly
        case .syncing:
            break // There is no way to safely cancel an in-flight request
        case .finished:
            break // This should never happen
        }
    }

    private func startSyncOperation(_ operation: SyncOperation) {
        Task { @MainActor in
            do {
                operation.log("upload remaining media")
                try await uploadRemainingResources(for: operation.revision)
                guard !operation.isCancelled else { return }
                operation.log("sync post contents and settings")
                operation.state = .syncing
                try await PostRepository(coreDataStack: coreDataStack)
                    .sync(operation.post, revision: operation.revision)
                syncOperation(operation, didFinishWithResult: .success(()))
            } catch {
                trackError(error, operation: "post-sync", post: operation.revision)
                syncOperation(operation, didFinishWithResult: .failure(error))
            }
        }
    }

    private func syncOperation(_ operation: SyncOperation, didFinishWithResult result: Result<Void, Error>) {
        operation.log("finished with result: \(result)")
        operation.state = .finished(result)
        defer { syncEvents.send(.finished(operation: operation, result: result)) }

        guard !operation.isCancelled else { return }

        let worker = getWorker(for: operation.post)
        worker.operation = nil

        switch result {
        case .success:
            worker.retryDelay = syncRetryDelay
            worker.error = nil
            postDidUpdateNotification(for: operation.post) // TODO: Use syncEvents

            if let revision = operation.post.getLatestRevisionNeedingSync() {
                operation.log("more revisions need syncing: \(revision.objectID.shortDescription)")
                startSync(for: operation.post, revision: revision)
            } else {
                workers[operation.post.objectID] = nil
            }
        case .failure(let error):
            worker.error = error
            postDidUpdateNotification(for: operation.post)

            if worker.showNextError {
                worker.showNextError = false
                handleError(error, for: operation.post)
            }

            let delay = worker.nextRetryDelay
            worker.retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self, weak worker] _ in
                guard let self, let worker else { return }
                self.didRetryTimerFire(for: worker)
            }
            worker.log("scheduled retry with delay: \(delay)s.")

            if let error = error as? PostRepository.PostSaveError, case .deleted = error {
                operation.log("post was permanently deleted")
                handlePermanentlyDeleted(operation.post)
                workers[operation.post.objectID] = nil
            }
        }
    }

    private func didRetryTimerFire(for worker: SyncWorker) {
        worker.log("retry timer fired")
        startSync(for: worker.post)
    }

    @objc private func didUpdateReachability(_ notification: Foundation.Notification) {
        guard let reachable = notification.userInfo?[Foundation.Notification.reachabilityKey],
              (reachable as? Bool) == true else {
            return
        }
        for worker in workers.values {
            if let error = worker.error,
               let urlError = (error as NSError).underlyingErrors.first as? URLError,
               urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost || urlError.code == .timedOut {
                worker.log("connection is reachable – retrying now")
                startSync(for: worker.post)
            }
        }
    }

    func syncError(for post: AbstractPost) -> Error? {
        wpAssert(post.isOriginal())
        return workers[post.objectID]?.error
    }

    private func postDidUpdateNotification(for post: AbstractPost) {
        NotificationCenter.default.post(name: .postCoordinatorDidUpdate, object: self, userInfo: [NSUpdatedObjectsKey: Set([post])])
    }

    // MARK: - Upload Resources

    @MainActor
    private func uploadRemainingResources(for post: AbstractPost) async throws {
        _ = try await withUnsafeThrowingContinuation { continuation in
            self.prepareToSave(post, then: { continuation.resume(with: $0) })
        }
    }

    /// If media is still uploading it keeps track of the ongoing media operations and updates the post content when they finish.
    /// Then, it calls the completion block with the post ready to be saved/uploaded.
    ///
    /// - Parameter post: the post to save
    /// - Parameter automatedRetry: if this is an automated retry, without user intervenction
    /// - Parameter then: a block to perform after post is ready to be saved
    ///
    private func prepareToSave(_ post: AbstractPost, automatedRetry: Bool = false,
                               then completion: @escaping (Result<AbstractPost, SavingError>) -> ()) {
        post.autoUploadAttemptsCount = NSNumber(value: automatedRetry ? post.autoUploadAttemptsCount.intValue + 1 : 0)

        guard mediaCoordinator.uploadMedia(for: post, automatedRetry: automatedRetry) else {
            completion(.failure(SavingError.mediaFailure(post, URLError(.unknown))))
            return
        }

        let hasPendingMedia = post.media.contains { $0.remoteStatus != .sync }

        if hasPendingMedia {
            // Only observe if we're not already
            guard !isObserving(post: post) else {
                return
            }

            // Ensure that all synced media references are up to date
            let syncedMedia = post.media.filter { $0.remoteStatus == .sync }
            updateMediaBlocksBeforeSave(in: post, with: syncedMedia)

            let uuid = observeMedia(for: post, completion: completion)
            trackObserver(receipt: uuid, for: post)

            return
        } else {
            // Ensure that all media references are up to date
            updateMediaBlocksBeforeSave(in: post, with: post.media)
        }

        completion(.success(post))
    }

    private func updateMediaBlocksBeforeSave(in post: AbstractPost, with media: Set<Media>) {
        guard let postContent = post.content else {
            return
        }
        let contentParser = GutenbergContentParser(for: postContent)
        media.forEach { self.updateReferences(to: $0, in: contentParser.blocks, post: post) }
        post.content = contentParser.html()
    }

    func isUploading(post: AbstractPost) -> Bool {
        return post.remoteStatus == .pushing
    }

    func posts(for blog: Blog, containsTitle title: String, excludingPostIDs excludedPostIDs: [Int] = [], entityName: String? = nil, publishedOnly: Bool = false) -> NSFetchedResultsController<AbstractPost> {
        let context = self.mainContext
        let fetchRequest = NSFetchRequest<AbstractPost>(entityName: entityName ?? AbstractPost.entityName())

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_created_gmt", ascending: false)]

        let blogPredicate = NSPredicate(format: "blog == %@", blog)
        let urlPredicate = NSPredicate(format: "permaLink != NULL")
        let noVersionPredicate = NSPredicate(format: "original == NULL")
        var compoundPredicates = [blogPredicate, urlPredicate, noVersionPredicate]
        if !title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            compoundPredicates.append(NSPredicate(format: "postTitle contains[c] %@", title))
        }
        if !excludedPostIDs.isEmpty {
            compoundPredicates.append(NSPredicate(format: "NOT (postID IN %@)", excludedPostIDs))
        }
        if publishedOnly {
            compoundPredicates.append(NSPredicate(format: "\(BasePost.statusKeyPath) == '\(PostStatusPublish)'"))
        }
        let resultPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)

        fetchRequest.predicate = resultPredicate

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        return controller
    }

    func titleOfPost(withPermaLink value: String, in blog: Blog) -> String? {
        let context = self.mainContext
        let fetchRequest = NSFetchRequest<AbstractPost>(entityName: "AbstractPost")

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_created_gmt", ascending: false)]

        let blogPredicate = NSPredicate(format: "blog == %@", blog)
        let urlPredicate = NSPredicate(format: "permaLink == %@", value)
        let noVersionPredicate = NSPredicate(format: "original == NULL")
        let compoundPredicates = [blogPredicate, urlPredicate, noVersionPredicate]

        let resultPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)

        fetchRequest.predicate = resultPredicate

        let result = try? context.fetch(fetchRequest)

        guard let post = result?.first else {
            return nil
        }

        return post.titleForDisplay()
    }

    private func observeMedia(for post: AbstractPost, completion: @escaping (Result<AbstractPost, SavingError>) -> ()) -> UUID {
        // Only observe if we're not already
        let handleSingleMediaFailure = { [weak self] (error: Error) -> Void in
            guard let `self` = self,
                self.isObserving(post: post) else {
                return
            }

            // One of the media attached to the post has already failed. We're changing the
            // status of the post to .failed so we don't need to observe for other failed media
            // anymore. If we do, we'll receive more notifications and we'll be calling
            // completion() multiple times.
            self.removeObserver(for: post)

            completion(.failure(SavingError.mediaFailure(post, error)))
        }

        return mediaCoordinator.addObserver({ [weak self](media, state) in
            guard let `self` = self else {
                return
            }
            switch state {
            case .ended:
                let successHandler = {
                    self.updateMediaBlocksBeforeSave(in: post, with: [media])
                    if post.media.allSatisfy({ $0.remoteStatus == .sync }) {
                        self.removeObserver(for: post)
                        completion(.success(post))
                    }
                }
                switch media.mediaType {
                case .video:
                    EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post) { (result) in
                        switch result {
                        case .failure(let error):
                            handleSingleMediaFailure(error)
                        case .success(let videoURL):
                            media.remoteURL = videoURL.absoluteString
                            successHandler()
                        }
                    }
                default:
                    successHandler()
                }
            case .failed(let error):
                handleSingleMediaFailure(error)
            default:
                DDLogInfo("Post Coordinator -> Media state: \(state)")
            }
        }, forMediaFor: post)
    }

    private func updateReferences(to media: Media, in contentBlocks: [GutenbergParsedBlock], post: AbstractPost) {
        guard var postContent = post.content,
            let mediaID = media.mediaID?.intValue,
            let remoteURLStr = media.remoteURL else {
            return
        }
        var imageURL = remoteURLStr

        if let remoteLargeURL = media.remoteLargeURL {
            imageURL = remoteLargeURL
        } else if let remoteMediumURL = media.remoteMediumURL {
            imageURL = remoteMediumURL
        }

        let mediaLink = media.link
        let mediaUploadID = media.uploadID
        let gutenbergMediaUploadID = media.gutenbergUploadID
        if media.remoteStatus == .failed {
            return
        }

        var gutenbergBlockProcessors: [GutenbergProcessor] = []
        var gutenbergProcessors: [Processor] = []
        var aztecProcessors: [Processor] = []

        // File block can upload any kind of media.
        let gutenbergFileProcessor = GutenbergFileUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        gutenbergBlockProcessors.append(gutenbergFileProcessor)

        if media.mediaType == .image {
            let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: imageURL)
            gutenbergBlockProcessors.append(gutenbergImgPostUploadProcessor)

            let gutenbergGalleryPostUploadProcessor = GutenbergGalleryUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: imageURL, mediaLink: mediaLink)
            gutenbergBlockProcessors.append(gutenbergGalleryPostUploadProcessor)

            let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, width: media.width?.intValue, height: media.height?.intValue)
            aztecProcessors.append(imgPostUploadProcessor)

            let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
            gutenbergProcessors.append(gutenbergCoverPostUploadProcessor)

        } else if media.mediaType == .video {
            let gutenbergVideoPostUploadProcessor = GutenbergVideoUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
            gutenbergProcessors.append(gutenbergVideoPostUploadProcessor)

            let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
            gutenbergProcessors.append(gutenbergCoverPostUploadProcessor)

            let videoPostUploadProcessor = VideoUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, videoPressID: media.videopressGUID)
            aztecProcessors.append(videoPostUploadProcessor)

            if let videoPressGUID = media.videopressGUID {
                let gutenbergVideoPressUploadProcessor = GutenbergVideoPressUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, videoPressGUID: videoPressGUID)
                gutenbergProcessors.append(gutenbergVideoPressUploadProcessor)
            }

        } else if media.mediaType == .audio {
            let gutenbergAudioProcessor = GutenbergAudioUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
            gutenbergProcessors.append(gutenbergAudioProcessor)
        } else if let remoteURL = URL(string: remoteURLStr) {
            let documentTitle = remoteURL.lastPathComponent
            let documentUploadProcessor = DocumentUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, title: documentTitle)
            aztecProcessors.append(documentUploadProcessor)
        }

        // Gutenberg processors need to run first because they are more specific/and target only content inside specific blocks
        gutenbergBlockProcessors.forEach { $0.process(contentBlocks) }
        postContent = gutenbergProcessors.reduce(postContent) { (content, processor) -> String in
            return processor.process(content)
        }

        // Aztec processors are next because they are more generic and only worried about HTML tags
        postContent = aztecProcessors.reduce(postContent) { (content, processor) -> String in
            return processor.process(content)
        }

        post.content = postContent
    }

    private func trackObserver(receipt: UUID, for post: AbstractPost) {
        queue.sync {
            observerUUIDs[post] = receipt
        }
    }

    private func removeObserver(for post: AbstractPost) {
        queue.sync {
            let uuid = observerUUIDs[post]

            observerUUIDs.removeValue(forKey: post)

            if let uuid {
                mediaCoordinator.removeObserver(withUUID: uuid)
            }
        }
    }

    private func isObserving(post: AbstractPost) -> Bool {
        var result = false
        queue.sync {
            result = observerUUIDs[post] != nil
        }
        return result
    }

    // MARK: - State

    func isUpdating(_ post: AbstractPost) -> Bool {
        pendingPostIDs.contains(post.original().objectID)
    }

    @MainActor
    private func setUpdating(_ isUpdating: Bool, for post: AbstractPost) {
        let post = post.original()
        if isUpdating {
            pendingPostIDs.insert(post.objectID)
        } else {
            pendingPostIDs.remove(post.objectID)
        }
        postDidUpdateNotification(for: post)
    }

    // MARK: - Trash/Restore/Delete

    /// Moves the given post to trash.
    @MainActor
    func trash(_ post: AbstractPost) async {
        wpAssert(post.isOriginal())

        setUpdating(true, for: post)
        defer { setUpdating(false, for: post) }

        await pauseSyncing(for: post)
        defer { resumeSyncing(for: post) }

        do {
            try await PostRepository(coreDataStack: coreDataStack).trash(post)

            MediaCoordinator.shared.cancelUploadOfAllMedia(for: post)
            SearchManager.shared.deleteSearchableItem(post)
        } catch {
            trackError(error, operation: "post-trash", post: post)
            handleError(error, for: post)
        }
    }

    @MainActor
    func delete(_ post: AbstractPost) async {
        wpAssert(post.isOriginal())

        setUpdating(true, for: post)
        defer { setUpdating(false, for: post) }

        do {
            try await PostRepository(coreDataStack: coreDataStack).delete(post)
        } catch {
            trackError(error, operation: "post-delete", post: post)
            handleError(error, for: post)
        }
    }
}

extension Foundation.Notification.Name {
    /// Contains a set of updated objects under the `NSUpdatedObjectsKey` key.
    static let postCoordinatorDidUpdate = Foundation.Notification.Name("org.automattic.postCoordinatorDidUpdate")
}

enum PostNoticeUserInfoKey {
    static let postID = "post_id"
}

private extension NSManagedObjectID {
    var shortDescription: String {
        let description = "\(self)"
        guard let index = description.lastIndex(of: "/") else { return description }
        return String(description.suffix(from: index))
            .trimmingCharacters(in: CharacterSet(charactersIn: "/>"))
    }
}
