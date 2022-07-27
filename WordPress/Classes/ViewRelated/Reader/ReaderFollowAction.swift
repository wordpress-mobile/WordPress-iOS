/// Encapsulates a command to toggle following a post
final class ReaderFollowAction {
    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 completion: ((Bool) -> Void)? = nil,
                 failure: ((Bool, Error?) -> Void)? = nil) {

        if post.isFollowing {
            ReaderSubscribingNotificationAction().execute(for: post.siteID, context: context, subscribe: false)
            WPAnalytics.track(.readerListNotificationMenuOff)
        }

        let postService = ReaderPostService(managedObjectContext: context)
        postService.toggleFollowing(for: post, success: completion, failure: failure)
    }
}
