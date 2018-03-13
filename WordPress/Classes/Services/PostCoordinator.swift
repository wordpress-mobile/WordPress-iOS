import Foundation

class PostCoordinator: NSObject {

    @objc static let shared = PostCoordinator()

    private(set) var backgroundContext: NSManagedObjectContext = {
        let context = ContextManager.sharedInstance().newDerivedContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    private let mainContext = ContextManager.sharedInstance().mainContext

    private let queue = DispatchQueue(label: "org.wordpress.postcoordinator")

    /// Saves the post to both the local database and server. If media is still uploading it keeps track of the ongoing media operations and updates the post content.
    ///
    /// - Parameter post: the post to save
    func save(post: AbstractPost) {
        let mediaCoordinator = MediaCoordinator.shared

        if mediaCoordinator.isUploadingMedia(for: post) {
            mediaCoordinator.addObserver({ (media, state) in

            }, forMediaFor: post)
        }

        let postService = PostService(managedObjectContext: mainContext)
        postService.uploadPost(post, success: { uploadedPost in

        }) { error in
        }
    }
}
