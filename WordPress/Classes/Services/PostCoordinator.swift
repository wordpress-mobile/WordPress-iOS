import Aztec
import Foundation
import WordPressKit
import WordPressFlux
import CocoaLumberjack
import Combine
import AutomatticTracks

protocol PostCoordinatorDelegate: AnyObject {
    func postCoordinator(_ postCoordinator: PostCoordinator, promptForPasswordForBlog blog: Blog)
}

class PostCoordinator: NSObject {

    enum SavingError: Error, LocalizedError, CustomNSError {
        case mediaFailure(AbstractPost, Error)
        case unknown

        var errorDescription: String? {
            Strings.genericErrorTitle
        }

        var errorUserInfo: [String: Any] {
            switch self {
            case .mediaFailure(_, let error):
                return [NSUnderlyingErrorKey: error]
            case .unknown:
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
    private var pendingDeletionPostIDs: Set<NSManagedObjectID> = []
    private var observerUUIDs: [AbstractPost: UUID] = [:]

    private let mediaCoordinator: MediaCoordinator

    private let mainService: PostService
    private let failedPostsFetcher: FailedPostsFetcher

    private let actionDispatcherFacade: ActionDispatcherFacade
    private let isSyncPublishingEnabled: Bool

    /// The initial sync retry delay. By default, 8 seconds.
    var syncRetryDelay: TimeInterval = 8

    // MARK: - Initializers

    init(mainService: PostService? = nil,
         mediaCoordinator: MediaCoordinator? = nil,
         failedPostsFetcher: FailedPostsFetcher? = nil,
         actionDispatcherFacade: ActionDispatcherFacade = ActionDispatcherFacade(),
         coreDataStack: CoreDataStackSwift = ContextManager.sharedInstance(),
         isSyncPublishingEnabled: Bool = RemoteFeatureFlag.syncPublishing.enabled()) {
        self.coreDataStack = coreDataStack

        let mainContext = self.coreDataStack.mainContext

        self.mainService = mainService ?? PostService(managedObjectContext: mainContext)
        self.mediaCoordinator = mediaCoordinator ?? MediaCoordinator.shared
        self.failedPostsFetcher = failedPostsFetcher ?? FailedPostsFetcher(mainContext)

        self.actionDispatcherFacade = actionDispatcherFacade
        self.isSyncPublishingEnabled = isSyncPublishingEnabled

        super.init()

        if isSyncPublishingEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(didUpdateReachability), name: .reachabilityChanged, object: nil)
        }
    }

    /// Upload or update a post in the server.
    ///
    /// - Parameter forceDraftIfCreating Please see `PostService.uploadPost:forceDraftIfCreating`.
    ///
    /// - note: deprecated (kahu-offline-mode)
    func save(_ postToSave: AbstractPost,
              automatedRetry: Bool = false,
              forceDraftIfCreating: Bool = false,
              defaultFailureNotice: Notice? = nil,
              completion: ((Result<AbstractPost, Error>) -> ())? = nil) {

        notifyNewPostCreated()

        prepareToSave(postToSave, automatedRetry: automatedRetry) { result in
            switch result {
            case .success(let post):
                self.upload(post: post, forceDraftIfCreating: forceDraftIfCreating, completion: completion)
            case .failure(let error):
                switch error {
                case SavingError.mediaFailure(let savedPost, _):
                    self.dispatchNotice(savedPost)
                default:
                    if let notice = defaultFailureNotice {
                        self.actionDispatcherFacade.dispatch(NoticeAction.post(notice))
                    }
                }

                completion?(.failure(error))
            }
        }
    }

    func autoSave(_ postToSave: AbstractPost, automatedRetry: Bool = false) {
        prepareToSave(postToSave, automatedRetry: automatedRetry) { result in
            switch result {
            case .success(let post):
                self.mainService.autoSave(post, success: { uploadedPost, _ in }, failure: { _ in })
            case .failure:
                break
            }
        }
    }

    /// - note: Deprecated (kahu-offline-mode) (See PostCoordinator.publish)
    func publish(_ post: AbstractPost) {
        if post.status == .draft {
            post.status = .publish
            post.isFirstTimePublish = true
        }

        if post.status != .scheduled {
            post.date_created_gmt = Date()
        }

        post.shouldAttemptAutoUpload = true

        save(post)
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
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
    @MainActor
    func _publish(_ post: AbstractPost, options: PublishingOptions) async throws {
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
            try await repository._save(post, changes: parameters)
            didPublish(post)
            show(PostCoordinator.makeUploadSuccessNotice(for: post))
        } catch {
            trackError(error, operation: "post-publish")
            handleError(error, for: post)
            throw error
        }
    }

    @MainActor
    private func didPublish(_ post: AbstractPost) {
        if post.status == .publish {
            QuickStartTourGuide.shared.complete(tour: QuickStartPublishTour(), silentlyForBlog: post.blog)
        }
        if post.status == .scheduled {
            notifyNewPostScheduled()
        } else if post.status == .publish {
            notifyNewPostPublished()
        }
        SearchManager.shared.indexItem(post)
        AppRatingUtility.shared.incrementSignificantEvent()
    }

    /// Uploads the changes made to the post to the server.
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
    @discardableResult @MainActor
    func _save(_ post: AbstractPost, changes: RemotePostUpdateParameters? = nil) async throws -> AbstractPost {
        let post = post.original()

        await pauseSyncing(for: post)
        defer { resumeSyncing(for: post) }

        do {
            let previousStatus = post.status
            try await PostRepository()._save(post, changes: changes)
            show(PostCoordinator.makeUploadSuccessNotice(for: post, previousStatus: previousStatus))
            return post
        } catch {
            trackError(error, operation: "post-save")
            handleError(error, for: post)
            throw error
        }
    }

    /// Patches the post.
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
    @MainActor
    func _update(_ post: AbstractPost, changes: RemotePostUpdateParameters) async throws {
        wpAssert(post.isOriginal())

        let post = post.original()
        do {
            try await PostRepository(coreDataStack: coreDataStack)._update(post, changes: changes)
        } catch {
            trackError(error, operation: "post-patch")
            handleError(error, for: post)
            throw error
        }
    }

    private func handleError(_ error: Error, for post: AbstractPost) {
        guard let topViewController = UIApplication.shared.mainWindow?.topmostPresentedViewController else {
            wpAssertionFailure("Failed to show an error alert")
            return
        }
        let alert = UIAlertController(title: Strings.genericErrorTitle, message: error.localizedDescription, preferredStyle: .alert)
        if let error = error as? PostRepository.PostSaveError {
            switch error {
            case .conflict(let latest):
                alert.addDefaultActionWithTitle(Strings.buttonOK) { [weak self] _ in
                    self?.showResolveConflictView(post: post, remoteRevision: latest, source: .editor)
                }
            case .deleted:
                alert.addDefaultActionWithTitle(Strings.buttonOK) { [weak self] _ in
                    self?.handlePermanentlyDeleted(post)
                }
            }
        } else {
            alert.addDefaultActionWithTitle(Strings.buttonOK, handler: nil)
        }
        topViewController.present(alert, animated: true)
    }

    private func trackError(_ error: Error, operation: String) {
        DDLogError("post-coordinator-\(operation)-failed: \(error)")

        if let error = error as? TrackableErrorProtocol, var userInfo = error.getTrackingUserInfo() {
            userInfo["operation"] = operation
            WPAnalytics.track(.postCoordinatorErrorEncountered, properties: userInfo)
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
        guard isSyncPublishingEnabled else {
            _moveToDraft(post)
            return
        }

        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.draft.rawValue
        _performChanges(changes, for: post)
    }

    /// - note: Deprecated (kahu-offline-mode) (along with all related types)
    private func _moveToDraft(_ post: AbstractPost) {
        post.status = .draft
        save(post)
    }

    /// Sets the post state to "updating" and performs the given changes.
    private func _performChanges(_ changes: RemotePostUpdateParameters, for post: AbstractPost) {
        Task { @MainActor in
            let post = post.original()
            setUpdating(true, for: post)
            defer { setUpdating(false, for: post) }

            try await self._update(post, changes: changes)
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
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
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
        let post: AbstractPost
        var isPaused = false
        var operation: SyncOperation? // The sync operation that's currently running
        var error: Error? // The previous sync error

        var nextRetryDelay: TimeInterval {
            retryDelay = min(32, retryDelay * 1.5)
            return retryDelay
        }
        var retryDelay: TimeInterval
        weak var retryTimer: Timer?

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
        guard let revision = post.getLatestRevisionNeedingSync() else {
            let worker = getWorker(for: post)
            worker.error = nil
            postDidUpdateNotification(for: post)
            return DDLogInfo("sync: \(post.objectID.shortDescription) is already up to date")
        }
        startSync(for: post, revision: revision)
    }

    private func startSync(for post: AbstractPost, revision: AbstractPost) {
        wpAssert(Thread.isMainThread)
        wpAssert(post.isOriginal())
        wpAssert(!post.objectID.isTemporaryID)

        let worker = getWorker(for: post)

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
                trackError(error, operation: "post-sync")
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

            if shouldScheduleRetry(for: error) {
                let delay = worker.nextRetryDelay
                worker.retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self, weak worker] _ in
                    guard let self, let worker else { return }
                    self.didRetryTimerFire(for: worker)
                }
                worker.log("scheduled retry with delay: \(delay)s.")
            }

            if let error = error as? PostRepository.PostSaveError, case .deleted = error {
                operation.log("post was permanently deleted")
                handlePermanentlyDeleted(operation.post)
                workers[operation.post.objectID] = nil
            }
        }
    }

    private func shouldScheduleRetry(for error: Error) -> Bool {
        if let saveError = error as? PostRepository.PostSaveError {
            switch saveError {
            case .deleted:
                return false
            case .conflict:
                return false
            }
        }
        return true
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
               urlError.code == .notConnectedToInternet {
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
            self.prepareToSave(post, then: continuation.resume(with:))
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
            change(post: post, status: .failed) { savedPost in
                completion(.failure(SavingError.mediaFailure(savedPost, URLError(.unknown))))
            }
            return
        }

        change(post: post, status: .pushing)

        let hasPendingMedia: Bool
        if isSyncPublishingEnabled {
            hasPendingMedia = post.media.contains { $0.remoteStatus != .sync }
        } else {
            hasPendingMedia = mediaCoordinator.isUploadingMedia(for: post) || post.hasFailedMedia
        }

        if hasPendingMedia {
            change(post: post, status: .pushingMedia)
            // Only observe if we're not already
            guard !isObserving(post: post) else {
                return
            }

            // Ensure that all synced media references are up to date
            post.media.forEach { media in
                if media.remoteStatus == .sync {
                    self.updateReferences(to: media, in: post)
                }
            }

            let uuid = observeMedia(for: post, completion: completion)
            trackObserver(receipt: uuid, for: post)

            return
        } else {
            // Ensure that all media references are up to date
            post.media.forEach { media in
                self.updateReferences(to: media, in: post)
            }
        }

        completion(.success(post))
    }

    func cancelAnyPendingSaveOf(post: AbstractPost) {
        removeObserver(for: post)
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

    /// This method checks the status of all post objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of posts are happening.
    ///
    /// - note: deprecated (kahu-offline-mode)
    @objc func refreshPostStatus() {
        guard !isSyncPublishingEnabled else { return }
        Post.refreshStatus(with: coreDataStack)
    }

    /// - note: Deprecated (kahu-offline-mode)
    private func upload(post: AbstractPost, forceDraftIfCreating: Bool, completion: ((Result<AbstractPost, Error>) -> ())? = nil) {
        mainService.uploadPost(post, forceDraftIfCreating: forceDraftIfCreating, success: { [weak self] uploadedPost in
            guard let uploadedPost = uploadedPost else {
                completion?(.failure(SavingError.unknown))
                return
            }

            print("Post Coordinator -> upload succesfull: \(String(describing: uploadedPost.content))")

            if uploadedPost.isScheduled() {
                self?.notifyNewPostScheduled()
            } else if uploadedPost.isPublished() {
                self?.notifyNewPostPublished()
            }

            SearchManager.shared.indexItem(uploadedPost)

            let model = PostNoticeViewModel(post: uploadedPost)
            self?.actionDispatcherFacade.dispatch(NoticeAction.post(model.notice))

            completion?(.success(uploadedPost))
        }, failure: { [weak self] error in
            self?.dispatchNotice(post)

            completion?(.failure(error ?? SavingError.unknown))

            print("Post Coordinator -> upload error: \(String(describing: error))")
        })
    }

    func add(assets: [ExportableAsset], to post: AbstractPost) -> [Media?] {
        let media = assets.map { asset in
            return mediaCoordinator.addMedia(from: asset, to: post)
        }
        return media
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

            self.change(post: post, status: .failed) { savedPost in
                completion(.failure(SavingError.mediaFailure(savedPost, error)))
            }
        }

        return mediaCoordinator.addObserver({ [weak self](media, state) in
            guard let `self` = self else {
                return
            }
            switch state {
            case .ended:
                let successHandler = {
                    self.updateReferences(to: media, in: post)
                    if self.isSyncPublishingEnabled {
                        if post.media.allSatisfy({ $0.remoteStatus == .sync }) {
                            self.removeObserver(for: post)
                            completion(.success(post))
                        }
                    } else {
                        // Let's check if media uploading is still going, if all finished with success then we can upload the post
                        if !self.mediaCoordinator.isUploadingMedia(for: post) && !post.hasFailedMedia {
                            self.removeObserver(for: post)
                            completion(.success(post))
                        }
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

    private func updateReferences(to media: Media, in post: AbstractPost) {
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
        var gutenbergProcessors = [Processor]()
        var aztecProcessors = [Processor]()

        // File block can upload any kind of media.
        let gutenbergFileProcessor = GutenbergFileUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        gutenbergProcessors.append(gutenbergFileProcessor)

        if media.mediaType == .image {
            let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: imageURL)
            gutenbergProcessors.append(gutenbergImgPostUploadProcessor)

            let gutenbergGalleryPostUploadProcessor = GutenbergGalleryUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: imageURL, mediaLink: mediaLink)
            gutenbergProcessors.append(gutenbergGalleryPostUploadProcessor)

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

            if let uuid = uuid {
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

    private func change(post: AbstractPost, status: AbstractPostRemoteStatus, then completion: ((AbstractPost) -> ())? = nil) {
        guard !isSyncPublishingEnabled else {
            completion?(post)
            return
        }
        guard let context = post.managedObjectContext else {
            return
        }

        context.perform {
            if status == .failed {
                post.markAsFailedAndDraftIfNeeded()
            } else {
                post.remoteStatus = status
            }

            ContextManager.sharedInstance().saveContextAndWait(context)

            completion?(post)
        }
    }

    /// Cancel active and pending automatic uploads of the post.
    func cancelAutoUploadOf(_ post: AbstractPost) {
        cancelAnyPendingSaveOf(post: post)

        post.shouldAttemptAutoUpload = false

        let moc = post.managedObjectContext

        moc?.perform {
            try? moc?.save()
        }

        let notice = Notice(title: PostAutoUploadMessages(for: post).cancelMessage(), message: "")
        actionDispatcherFacade.dispatch(NoticeAction.post(notice))
    }

    private func dispatchNotice(_ post: AbstractPost) {
        DispatchQueue.main.async {
            let model = PostNoticeViewModel(post: post)
            self.actionDispatcherFacade.dispatch(NoticeAction.post(model.notice))
        }
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
            try await PostRepository(coreDataStack: coreDataStack)._trash(post)

            cancelAnyPendingSaveOf(post: post)
            MediaCoordinator.shared.cancelUploadOfAllMedia(for: post)
            SearchManager.shared.deleteSearchableItem(post)
        } catch {
            trackError(error, operation: "post-trash")
            handleError(error, for: post)
        }
    }

    @MainActor
    func _delete(_ post: AbstractPost) async {
        wpAssert(post.isOriginal())

        setUpdating(true, for: post)
        defer { setUpdating(false, for: post) }

        do {
            try await PostRepository(coreDataStack: coreDataStack)._delete(post)
        } catch {
            trackError(error, operation: "post-delete")
            handleError(error, for: post)
        }
    }

    func isDeleting(_ post: AbstractPost) -> Bool {
        pendingDeletionPostIDs.contains(post.objectID)
    }

    /// Moves the post to trash or delets it permanently in case it's already in trash.
    @MainActor
    func delete(_ post: AbstractPost) async {
        wpAssert(post.managedObjectContext == mainContext)

        WPAnalytics.track(.postListTrashAction, withProperties: propertiesForAnalytics(for: post))

        setPendingDeletion(true, post: post)

        let trashed = (post.status == .trash)

        let repository = PostRepository(coreDataStack: ContextManager.shared)
        do {
            try await repository.trash(TaggedManagedObjectID(post))

            if trashed {
                cancelAnyPendingSaveOf(post: post)
                MediaCoordinator.shared.cancelUploadOfAllMedia(for: post)
            }

            // Remove the trashed post from spotlight
            SearchManager.shared.deleteSearchableItem(post)

            let message: String
            switch post {
            case _ as Post:
                message = trashed ? Strings.deletePost : Strings.movePostToTrash
            case _ as Page:
                message = trashed ? Strings.deletePage : Strings.movePageToTrash
            default:
                fatalError("Unsupported item: \(type(of: post))")
            }

            let notice = Notice(title: message)
            ActionDispatcher.dispatch(NoticeAction.dismiss)
            ActionDispatcher.dispatch(NoticeAction.post(notice))

            // No need to notify as the object gets deleted
            setPendingDeletion(false, post: post, notify: false)
        } catch {
            if let error = error as NSError?, error.code == Constants.httpCodeForbidden {
                delegate?.postCoordinator(self, promptForPasswordForBlog: post.blog)
            } else {
                WPError.showXMLRPCErrorAlert(error)
            }

            setPendingDeletion(false, post: post)
        }
    }

    private func setPendingDeletion(_ isDeleting: Bool, post: AbstractPost, notify: Bool = true) {
        if isDeleting {
            pendingDeletionPostIDs.insert(post.objectID)
        } else {
            pendingDeletionPostIDs.remove(post.objectID)
        }
        if notify {
            postDidUpdateNotification(for: post)
        }
    }

    private func propertiesForAnalytics(for post: AbstractPost) -> [String: AnyObject] {
        var properties = [String: AnyObject]()
        properties["type"] = ((post is Post) ? "post" : "page") as AnyObject
        if let dotComID = post.blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }
        return properties
    }
}

private struct Constants {
    static let httpCodeForbidden = 403
}

extension Foundation.Notification.Name {
    /// Contains a set of updated objects under the `NSUpdatedObjectsKey` key.
    static let postCoordinatorDidUpdate = Foundation.Notification.Name("org.automattic.postCoordinatorDidUpdate")
}

// MARK: - Automatic Uploads

extension PostCoordinator: Uploader {
    func resume() {
        guard !isSyncPublishingEnabled else {
            return
        }
        failedPostsFetcher.postsAndRetryActions { [weak self] postsAndActions in
            guard let self = self else {
                return
            }

            postsAndActions.forEach { post, action in
                self.trackAutoUpload(action: action, status: post.status)

                switch action {
                case .upload:
                    self.save(post, automatedRetry: true)
                case .autoSave:
                    self.autoSave(post, automatedRetry: true)
                case .uploadAsDraft:
                    self.save(post, automatedRetry: true, forceDraftIfCreating: true)
                case .nothing:
                    return
                }
            }
        }
    }

    private func trackAutoUpload(action: PostAutoUploadInteractor.AutoUploadAction, status: BasePost.Status?) {
        guard action != .nothing, let status = status else {
            return
        }
        WPAnalytics.track(.autoUploadPostInvoked, withProperties:
            ["upload_action": action.rawValue,
             "post_status": status.rawValue])
    }
}

extension PostCoordinator {
    /// Fetches failed posts that should be retried when there is an internet connection.
    class FailedPostsFetcher {
        private let managedObjectContext: NSManagedObjectContext

        init(_ managedObjectContext: NSManagedObjectContext) {
            self.managedObjectContext = managedObjectContext
        }

        func postsAndRetryActions(result: @escaping ([AbstractPost: PostAutoUploadInteractor.AutoUploadAction]) -> Void) {
            let interactor = PostAutoUploadInteractor()
            managedObjectContext.perform {
                let request = NSFetchRequest<AbstractPost>(entityName: NSStringFromClass(AbstractPost.self))
                request.predicate = NSPredicate(format: "remoteStatusNumber == %d", AbstractPostRemoteStatus.failed.rawValue)
                let posts = (try? self.managedObjectContext.fetch(request)) ?? []

                let postsAndActions = posts.reduce(into: [AbstractPost: PostAutoUploadInteractor.AutoUploadAction]()) { result, post in
                    result[post] = interactor.autoUploadAction(for: post)
                }
                result(postsAndActions)
            }
        }
    }
}

private extension NSManagedObjectID {
    var shortDescription: String {
        let description = "\(self)"
        guard let index = description.lastIndex(of: "/") else { return description }
        return String(description.suffix(from: index))
            .trimmingCharacters(in: CharacterSet(charactersIn: "/>"))
    }
}

private enum Strings {
    static let movePostToTrash = NSLocalizedString("postsList.movePostToTrash.message", value: "Post moved to trash", comment: "A short message explaining that a post was moved to the trash bin.")
    static let deletePost = NSLocalizedString("postsList.deletePost.message", value: "Post deleted permanently", comment: "A short message explaining that a post was deleted permanently.")
    static let movePageToTrash = NSLocalizedString("postsList.movePageToTrash.message", value: "Page moved to trash", comment: "A short message explaining that a page was moved to the trash bin.")
    static let deletePage = NSLocalizedString("postsList.deletePage.message", value: "Page deleted permanently", comment: "A short message explaining that a page was deleted permanently.")
    static let genericErrorTitle = NSLocalizedString("postNotice.errorTitle", value: "An error occured", comment: "A generic error message title")
    static let buttonOK = NSLocalizedString("postNotice.ok", value: "OK", comment: "Button OK")
    static let errorUnsyncedChangesMessage = NSLocalizedString("postNotice.errorUnsyncedChangesMessage", value: "The app is uploading previously made changes to the server. Please try again later.", comment: "An error message")
}
