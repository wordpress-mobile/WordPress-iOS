/// Encapsulates a command to subscribe or unsubscribe to a posts comments.
final class ReaderSubscribeCommentsAction {
    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 followCommentsService: FollowCommentsService,
                 completion: (() -> Void)? = nil,
                 failure: ((Error?) -> Void)? = nil) {

        let subscribing = !post.isSubscribedComments

        followCommentsService.toggleSubscribed(!subscribing, success: { success in
            followCommentsService.toggleNotificationSettings(subscribing, success: {
                ReaderHelpers.dispatchToggleSubscribeCommentMessage(subscribing: subscribing, success: success)
                completion?()
            }, failure: { error in
                DDLogError("Error toggling comment subscription status: \(error.debugDescription)")
                ReaderHelpers.dispatchToggleSubscribeCommentErrorMessage(subscribing: subscribing)
            })
        }, failure: { error in
            DDLogError("Error toggling comment subscription status: \(error.debugDescription)")
            ReaderHelpers.dispatchToggleSubscribeCommentErrorMessage(subscribing: subscribing)
        })
    }
}
