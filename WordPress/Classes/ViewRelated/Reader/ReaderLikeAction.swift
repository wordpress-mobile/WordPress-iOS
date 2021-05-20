/// Encapsulates a command to toggle a post's liked status
final class ReaderLikeAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        if !post.isLiked {
            // Consider a like from the list to be enough to push a page view.
            // Solves a long-standing question from folks who ask 'why do I
            // have more likes than page views?'.
            ReaderHelpers.bumpPageViewForPost(post)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        let service = ReaderPostService(managedObjectContext: context)
        service.toggleLiked(for: post, success: {
            completion?()
        }, failure: { (error: Error?) in
            if let anError = error {
                DDLogError("Error (un)liking post: \(anError.localizedDescription)")
            }
            completion?()
        })
    }
}
