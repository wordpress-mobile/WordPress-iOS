import Aztec
import Foundation
import WordPressFlux

class PostCoordinator: NSObject {

    enum SavingError: Error {
        case mediaFailure(AbstractPost)
        case unknown
    }

    @objc static let shared = PostCoordinator()

    private let backgroundContext: NSManagedObjectContext

    private let mainContext: NSManagedObjectContext

    private let queue = DispatchQueue(label: "org.wordpress.postcoordinator")

    private var observerUUIDs: [AbstractPost: UUID] = [:]

    private let mediaCoordinator: MediaCoordinator

    private let backgroundService: PostService
    private let mainService: PostService
    private let failedPostsFetcher: FailedPostsFetcher

    private let actionDispatcherFacade: ActionDispatcherFacade

    // MARK: - Initializers

    init(mainService: PostService? = nil,
         backgroundService: PostService? = nil,
         mediaCoordinator: MediaCoordinator? = nil,
         failedPostsFetcher: FailedPostsFetcher? = nil,
         actionDispatcherFacade: ActionDispatcherFacade = ActionDispatcherFacade()) {
        let contextManager = ContextManager.sharedInstance()

        let mainContext = contextManager.mainContext
        let backgroundContext = contextManager.newDerivedContext()
        backgroundContext.automaticallyMergesChangesFromParent = true

        self.mainContext = mainContext
        self.backgroundContext = backgroundContext

        self.mainService = mainService ?? PostService(managedObjectContext: mainContext)
        self.backgroundService = backgroundService ?? PostService(managedObjectContext: backgroundContext)
        self.mediaCoordinator = mediaCoordinator ?? MediaCoordinator.shared
        self.failedPostsFetcher = failedPostsFetcher ?? FailedPostsFetcher(mainContext)

        self.actionDispatcherFacade = actionDispatcherFacade
    }

    /// Upload or update a post in the server.
    ///
    /// - Parameter forceDraftIfCreating Please see `PostService.uploadPost:forceDraftIfCreating`.
    func save(_ postToSave: AbstractPost,
              automatedRetry: Bool = false,
              forceDraftIfCreating: Bool = false,
              defaultFailureNotice: Notice? = nil,
              completion: ((Result<AbstractPost, Error>) -> ())? = nil) {

        prepareToSave(postToSave, automatedRetry: automatedRetry) { result in
            switch result {
            case .success(let post):
                self.upload(post: post, forceDraftIfCreating: forceDraftIfCreating, completion: completion)
            case .failure(let error):
                switch error {
                case SavingError.mediaFailure(let savedPost):
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

    func publish(_ post: AbstractPost) {
        if post.status == .draft {
            post.status = .publish
        }

        if post.status != .scheduled {
            post.date_created_gmt = Date()
        }

        post.shouldAttemptAutoUpload = true

        save(post)
    }

    func moveToDraft(_ post: AbstractPost) {
        post.status = .draft
        save(post)
    }

    /// If media is still uploading it keeps track of the ongoing media operations and updates the post content when they finish.
    /// Then, it calls the completion block with the post ready to be saved/uploaded.
    ///
    /// - Parameter post: the post to save
    /// - Parameter automatedRetry: if this is an automated retry, without user intervenction
    /// - Parameter then: a block to perform after post is ready to be saved
    ///
    private func prepareToSave(_ post: AbstractPost, automatedRetry: Bool = false,
                               then completion: @escaping (Result<AbstractPost, Error>) -> ()) {
        post.autoUploadAttemptsCount = NSNumber(value: automatedRetry ? post.autoUploadAttemptsCount.intValue + 1 : 0)

        guard mediaCoordinator.uploadMedia(for: post, automatedRetry: automatedRetry) else {
            change(post: post, status: .failed) { savedPost in
                completion(.failure(SavingError.mediaFailure(savedPost)))
            }
            return
        }

        change(post: post, status: .pushing)

        if mediaCoordinator.isUploadingMedia(for: post) || post.hasFailedMedia {
            change(post: post, status: .pushingMedia)
            // Only observe if we're not already
            guard !isObserving(post: post) else {
                return
            }

            let handleSingleMediaFailure = { [weak self] in
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
                    completion(.failure(SavingError.mediaFailure(savedPost)))
                }
            }

            let uuid = mediaCoordinator.addObserver({ [weak self](media, state) in
                guard let `self` = self else {
                    return
                }
                switch state {
                case .ended:
                    let successHandler = {
                        self.updateReferences(to: media, in: post)
                        // Let's check if media uploading is still going, if all finished with success then we can upload the post
                        if !self.mediaCoordinator.isUploadingMedia(for: post) && !post.hasFailedMedia {
                            self.removeObserver(for: post)
                            completion(.success(post))
                        }
                    }
                    switch media.mediaType {
                    case .video:
                        EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post) { (result) in
                            switch result {
                            case .failure:
                                handleSingleMediaFailure()
                            case .success(let value):
                                media.remoteURL = value.videoURL.absoluteString
                                successHandler()
                            }
                        }
                    default:
                        successHandler()
                    }
                case .failed:
                    handleSingleMediaFailure()
                default:
                    DDLogInfo("Post Coordinator -> Media state: \(state)")
                }
            }, forMediaFor: post)

            trackObserver(receipt: uuid, for: post)

            return
        }

        completion(.success(post))
    }

    func cancelAnyPendingSaveOf(post: AbstractPost) {
        removeObserver(for: post)
    }

    func isUploading(post: AbstractPost) -> Bool {
        return post.remoteStatus == .pushing
    }

    func posts(for blog: Blog, containsTitle title: String, excludingPostIDs excludedPostIDs: [Int] = [], entityName: String? = nil) -> NSFetchedResultsController<AbstractPost> {
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
    @objc func refreshPostStatus() {
        backgroundService.refreshPostStatus()
    }

    private func upload(post: AbstractPost, forceDraftIfCreating: Bool, completion: ((Result<AbstractPost, Error>) -> ())? = nil) {
        mainService.uploadPost(post, forceDraftIfCreating: forceDraftIfCreating, success: { [weak self] uploadedPost in
            guard let uploadedPost = uploadedPost else {
                completion?(.failure(SavingError.unknown))
                return
            }

            print("Post Coordinator -> upload succesfull: \(String(describing: uploadedPost.content))")

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

    private func updateReferences(to media: Media, in post: AbstractPost) {
        guard var postContent = post.content,
            let mediaID = media.mediaID?.intValue,
            let remoteURLStr = media.remoteURL else {
            return
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
            let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
            gutenbergProcessors.append(gutenbergImgPostUploadProcessor)

            let gutenbergGalleryPostUploadProcessor = GutenbergGalleryUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr, mediaLink: mediaLink)
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
        guard let context = post.managedObjectContext else {
            return
        }

        context.perform {
            if status == .failed {
                self.mainService.markAsFailedAndDraftIfNeeded(post: post)
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
}

// MARK: - Automatic Uploads

extension PostCoordinator: Uploader {
    func resume() {
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
        private let postService: PostService

        init(_ postService: PostService) {
            self.postService = postService
        }

        init(_ managedObjectContext: NSManagedObjectContext) {
            postService = PostService(managedObjectContext: managedObjectContext)
        }

        func postsAndRetryActions(result: @escaping ([AbstractPost: PostAutoUploadInteractor.AutoUploadAction]) -> Void) {
            let interactor = PostAutoUploadInteractor()

            postService.getFailedPosts { posts in
                let postsAndActions = posts.reduce(into: [AbstractPost: PostAutoUploadInteractor.AutoUploadAction]()) { result, post in
                    result[post] = interactor.autoUploadAction(for: post)
                }

                result(postsAndActions)
            }
        }
    }
}
