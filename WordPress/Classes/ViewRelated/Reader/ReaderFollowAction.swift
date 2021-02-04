/// Encapsulates a command to toggle following a post
final class ReaderFollowAction {
    func execute(with post: ReaderPost,
                 context: NSManagedObjectContext,
                 completion: (() -> Void)? = nil,
                 failure: (() -> Void)? = nil) {
        let siteID = post.siteID
        var errorMessage: String
        var errorTitle: String
        if post.isFollowing {
            errorTitle = NSLocalizedString("Problem Unfollowing Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem unfollowing the site. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem unfollowing a site and instructions on how to notify us of the problem.")
        } else {
            errorTitle = NSLocalizedString("Problem Following Site", comment: "Title of a prompt")
            errorMessage = NSLocalizedString("There was a problem following the site.  If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Short notice that there was a problem following a site and instructions on how to notify us of the problem.")
        }

        let postService = ReaderPostService(managedObjectContext: context)
        let toFollow = !post.isFollowing

        if !toFollow {
            ReaderSubscribingNotificationAction().execute(for: siteID, context: context, subscribe: false)

        }

        postService.toggleFollowing(for: post,
                                    success: {
                                        completion?()
            },
                                    failure: { _ in
                                        failure?()
                                        let cancelTitle = NSLocalizedString("OK", comment: "Text of an OK button to dismiss a prompt.")
                                        let alertController = UIAlertController(title: errorTitle,
                                                                                message: errorMessage,
                                                                                preferredStyle: .alert)
                                        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                                        alertController.presentFromRootViewController()
        })
    }
}
