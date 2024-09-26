/// Encapsulates a command share a post
final class ReaderShareAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, anchor: UIView, vc: UIViewController) {
        self.execute(with: post, context: context, anchor: .view(anchor), vc: vc)
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, anchor: UIPopoverPresentationController.PopoverAnchor, vc: UIViewController) {
        let postID = post.objectID
        if let post: ReaderPost = ReaderActionHelpers.existingObject(for: postID, in: context) {
            let sharingController = PostSharingController()

            sharingController.shareReaderPost(post, fromAnchor: anchor, inViewController: vc)
            WPAnalytics.trackReader(.itemSharedReader, properties: ["blog_id": post.siteID as Any])
        }
    }
}
