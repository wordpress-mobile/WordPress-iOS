/// Encapsulates a command to subscribe or unsubscribe to a posts comments.
final class ReaderSubscribeCommentsAction {
    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 followCommentsService: FollowCommentsService,
                 completion: (() -> Void)? = nil,
                 failure: ((Error?) -> Void)? = nil) {

        let subscribing = !post.isSubscribedComments

        followCommentsService.toggleSubscribed(post.isSubscribedComments, success: { subscribeSuccess in
            followCommentsService.toggleNotificationSettings(subscribing, success: {
                ReaderHelpers.dispatchToggleSubscribeCommentMessage(subscribing: subscribing, success: subscribeSuccess) { actionSuccess in
                    self.disableNotificationSettings(followCommentsService: followCommentsService)
                }
                completion?()
            }, failure: { error in
                DDLogError("Error toggling comment notification status: \(error.debugDescription)")
                ReaderHelpers.dispatchToggleCommentNotificationMessage(subscribing: false, success: false)
                failure?(error)
            })
        }, failure: { error in
            DDLogError("Error toggling comment subscription status: \(error.debugDescription)")
            ReaderHelpers.dispatchToggleSubscribeCommentErrorMessage(subscribing: subscribing)
            failure?(error)
        })
    }

    private func disableNotificationSettings(followCommentsService: FollowCommentsService) {
        followCommentsService.toggleNotificationSettings(false, success: {
            ReaderHelpers.dispatchToggleCommentNotificationMessage(subscribing: false, success: true)
        }, failure: { error in
            DDLogError("Error toggling comment notification status: \(error.debugDescription)")
            ReaderHelpers.dispatchToggleCommentNotificationMessage(subscribing: false, success: false)
        })
    }
}
