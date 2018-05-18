/// Encapsulates a command share a post
final class ShareAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, anchor: UIView, vc: UIViewController) {
        let postID = post.objectID
        if let post: ReaderPost = ReaderActionHelpers.existingObject(for: postID, in: context) {
            let sharingController = PostSharingController()

            sharingController.shareReaderPost(post, fromView: anchor, inViewController: vc)
        }
    }
}
