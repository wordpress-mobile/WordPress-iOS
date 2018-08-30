import Aztec
import Foundation
import WordPressFlux

class PostCoordinator: NSObject {

    @objc static let shared = PostCoordinator()

    private(set) var backgroundContext: NSManagedObjectContext = {
        let context = ContextManager.sharedInstance().newDerivedContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    private let mainContext = ContextManager.sharedInstance().mainContext

    private let queue = DispatchQueue(label: "org.wordpress.postcoordinator")

    private var observerUUIDs: [AbstractPost: UUID] = [:]

    private lazy var mediaCoordinator: MediaCoordinator = {
        return MediaCoordinator.shared
    }()

    /// Saves the post to both the local database and the server if available.
    /// If media is still uploading it keeps track of the ongoing media operations and updates the post content when they finish
    ///
    /// - Parameter post: the post to save
    func save(post postToSave: AbstractPost) {
        var post = postToSave
        if postToSave.isRevision() && !postToSave.hasRemote(), let originalPost = postToSave.original {
            post = originalPost
            post.applyRevision()
            post.deleteRevision()
        }

        change(post: post, status: .pushing)

        if mediaCoordinator.isUploadingMedia(for: post) {
            change(post: post, status: .pushingMedia)
            // Only observe if we're not already
            guard !isObserving(post: post) else {
                return
            }

            let uuid = mediaCoordinator.addObserver({ [weak self](media, state) in
                guard let `self` = self else {
                    return
                }
                switch state {
                case .ended:
                    self.updateReferences(to: media, in: post)

                    // Let's check if media uploading is still going, if all finished with success then we can upload the post
                    if !self.mediaCoordinator.isUploadingMedia(for: post) && !post.hasFailedMedia {
                        self.removeObserver(for: post)
                        self.upload(post: post)
                    }
                case .failed:
                    self.change(post: post, status: .failed)
                default:
                    DDLogInfo("Post Coordinator -> Media state: \(state)")
                }
            }, forMediaFor: post)
            trackObserver(receipt: uuid, for: post)
            return
        }

        upload(post: post)
    }

    func cancelAnyPendingSaveOf(post: AbstractPost) {
        removeObserver(for: post)
    }

    func isUploading(post: AbstractPost) -> Bool {
        return post.remoteStatus == .pushing
    }

    func posts(for blog: Blog, wichTitleContains value: String) -> NSFetchedResultsController<AbstractPost> {
        let context = self.mainContext
        let fetchRequest = NSFetchRequest<AbstractPost>(entityName: "AbstractPost")

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_created_gmt", ascending: false)]

        let blogPredicate = NSPredicate(format: "blog == %@", blog)
        let urlPredicate = NSPredicate(format: "permaLink != NULL")
        let noVersionPredicate = NSPredicate(format: "original == NULL")
        var compoundPredicates = [blogPredicate, urlPredicate, noVersionPredicate]
        if !value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            compoundPredicates.append(NSPredicate(format: "postTitle contains[c] %@", value))
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

    /// Retries the upload and save of the post and any associated media with it.
    ///
    /// - Parameter post: the post to retry the upload
    ///
    @objc func retrySave(of post: AbstractPost) {
        for media in post.media {
            guard media.remoteStatus == .failed else {
                continue
            }
            mediaCoordinator.retryMedia(media)
        }
        save(post: post)
    }

    /// This method checks the status of all post objects and updates them to the correct status if needed.
    /// The main cause of wrong status is the app being killed while uploads of posts are happening.
    ///
    @objc func refreshPostStatus() {
        let service = PostService(managedObjectContext: backgroundContext)
        service.refreshPostStatus()
    }

    private func upload(post: AbstractPost) {
        let postService = PostService(managedObjectContext: mainContext)
        postService.uploadPost(post, success: { uploadedPost in
            print("Post Coordinator -> upload succesfull: \(String(describing: uploadedPost.content))")

            SearchManager.shared.indexItem(uploadedPost)

            let model = PostNoticeViewModel(post: uploadedPost)
            ActionDispatcher.dispatch(NoticeAction.post(model.notice))
        }, failure: { error in
            let model = PostNoticeViewModel(post: post)
            ActionDispatcher.dispatch(NoticeAction.post(model.notice))

            print("Post Coordinator -> upload error: \(String(describing: error))")
        })
    }

    private func updateReferences(to media: Media, in post: AbstractPost) {
        guard var postContent = post.content,
            let remoteURLStr = media.remoteURL else {
            return
        }

        let mediaUploadID = media.uploadID
        if media.remoteStatus == .failed {
            return
        }
        if media.mediaType == .image {
            let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, width: media.width?.intValue, height: media.height?.intValue)
            postContent = imgPostUploadProcessor.process(postContent)
        } else if media.mediaType == .video {
            let videoPostUploadProcessor = VideoUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, videoPressID: media.videopressGUID)
            postContent = videoPostUploadProcessor.process(postContent)
        } else if let remoteURL = URL(string: remoteURLStr) {
            let documentTitle = remoteURL.lastPathComponent
            let documentUploadProcessor = DocumentUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, title: documentTitle)
            postContent = documentUploadProcessor.process(postContent)
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

    private func change(post: AbstractPost, status: AbstractPostRemoteStatus) {
        post.managedObjectContext?.perform {
            post.remoteStatus = status
            try? post.managedObjectContext?.save()
        }
    }
}
