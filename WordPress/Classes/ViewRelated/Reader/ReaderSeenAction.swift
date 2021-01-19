/// Encapsulates a command to toggle a post's seen status
final class ReaderSeenAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil, failure: ((Error?) -> Void)? = nil) {

        let event: WPAnalyticsEvent = post.isSeen ? .readerPostMarkUnseen : .readerPostMarkSeen
        WPAnalytics.track(event, properties: ["source": "post_card"])

        let postService = ReaderPostService(managedObjectContext: context)
        postService.toggleSeen(for: post, success: completion, failure: failure)
    }
}
