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
    func save(post: AbstractPost) {
        if mediaCoordinator.isUploadingMedia(for: post) {
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
                default:
                    print("Post Coordinator -> Media state: \(state)")
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

    /// Retries the upload and save of the post and any associated media with it.
    ///
    /// - Parameter post: the post to retry the upload
    ///
    func retrySave(of post: AbstractPost) {
        for media in post.media {
            guard media.remoteStatus == .failed else {
                continue
            }
            mediaCoordinator.retryMedia(media)
        }
        save(post: post)
    }

    private func upload(post: AbstractPost) {
        let postService = PostService(managedObjectContext: mainContext)
        postService.uploadPost(post, success: { uploadedPost in
            print("Post Coordinator -> upload succesfull: \(String(describing: uploadedPost.content))")
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
}
