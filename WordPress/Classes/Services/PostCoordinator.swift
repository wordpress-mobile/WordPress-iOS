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

    /// Saves the post to both the local database and the server if available.
    /// If media is still uploading it keeps track of the ongoing media operations and updates the post content when they finish
    ///
    /// - Parameter post: the post to save
    func save(post: AbstractPost) {
        let mediaCoordinator = MediaCoordinator.shared

        if mediaCoordinator.isUploadingMedia(for: post) {
            mediaCoordinator.addObserver({ (media, state) in
                switch state {
                case .ended:
                    self.updateReferences(to: media, in: post)
                    // Let's check if media uploading is still going, if all finished with success then we can upload the post
                    if !mediaCoordinator.isUploadingMedia(for: post) {
                        self.upload(post: post)
                    }
                default:
                    print("Post Coordinator -> Media state: \(state)")
                }
            }, forMediaFor: post)
            return
        }

        upload(post: post)
    }

    private func upload(post: AbstractPost) {
        let postService = PostService(managedObjectContext: mainContext)
        postService.uploadPost(post, success: { uploadedPost in
            print("Post Coordinator -> upload succesfull: \(String(describing: uploadedPost.content))")
            let model = PostNoticeViewModel(post: post)
            ActionDispatcher.dispatch(NoticeAction.post(model.notice))
        }, failure: { error in
            print("Post Coordinator -> upload error: \(String(describing: error))")
        })
    }

    private func updateReferences(to media: Media, in post: AbstractPost) {
        guard var postContent = post.content,
            let remoteURLStr = media.remoteURL else {
            return
        }

        let mediaUploadID = media.uploadID

        if media.mediaType == .image {
            let imgPostUploadProcessor = ImgUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, width: media.width?.intValue, height: media.height?.intValue)
            postContent = imgPostUploadProcessor.process(postContent)
        } else if media.mediaType == .video {
            let videoPostUploadProcessor = VideoUploadProcessor(mediaUploadID: mediaUploadID, remoteURLString: remoteURLStr, videoPressID: media.videopressGUID)
            postContent = videoPostUploadProcessor.process(postContent)
        }

        post.content = postContent
    }
}
