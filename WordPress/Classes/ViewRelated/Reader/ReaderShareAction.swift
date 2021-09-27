/// Encapsulates a command share a post
final class ReaderShareAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, anchor: UIView, vc: UIViewController) {
        let postID = post.objectID
        if let post: ReaderPost = ReaderActionHelpers.existingObject(for: postID, in: context) {
            let sharingController = PostSharingController()

            sharingController.shareReaderPost(post, fromView: anchor, inViewController: vc)

            let siteID = post.siteID ?? 0
            let feedID = post.feedID ?? 0
            let properties: [String: Any] = ["blog_id": siteID,
                                             "feed_id": feedID,
                                             "follow": post.isFollowing]
            WPAnalytics.trackReader(.itemSharedReader, properties: properties)
        }
    }
}
