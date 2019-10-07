import Foundation

class PublishPostInteractor {
    private let postCoordinator: PostCoordinator

    init(postCoordinator: PostCoordinator = PostCoordinator.shared) {
        self.postCoordinator = postCoordinator
    }

    func upload(_ post: AbstractPost) {
        if post.status == .draft {
            post.status = .publish
        }

        if post.status != .scheduled {
            post.date_created_gmt = Date()
        }

        post.shouldAttemptAutoUpload = true

        postCoordinator.save(post)
    }

    func moveToDraft(_ post: AbstractPost) {
        post.status = .draft
        postCoordinator.save(post)
    }
}
