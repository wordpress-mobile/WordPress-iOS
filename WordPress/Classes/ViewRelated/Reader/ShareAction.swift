final class ShareAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, anchor: UIView, vc: UIViewController) {
        let postID = post.objectID
        if let post: ReaderPost = ActionHelpers.existingObject(for: postID, in: context) {
            let sharingController = PostSharingController()

            sharingController.shareReaderPost(post, fromView: anchor, inViewController: vc)
        }
    }
}
