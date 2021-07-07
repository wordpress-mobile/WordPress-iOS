/// Encapsulates a command to subscribe or unsubscribe to a posts comments.
final class ReaderSubscribeCommentsAction {
    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 completion: (() -> Void)? = nil,
                 failure: ((Error?) -> Void)? = nil) {

        let subscribing = !post.isSubscribedComments
        let service = FollowCommentsService(post: post)
        service?.toggleSubscribed(post.isSubscribedComments, success: { success in
            ReaderHelpers.dispatchToggleSubscribeCommentMessage(subscribing: subscribing, success: success)
        }, failure: { error in
            DDLogError("Error toggling comment subscription status: \(error.debugDescription)")
            ReaderHelpers.dispatchToggleSubscribeCommentErrorMessage(subscribing: subscribing)
        })
    }
}
