import Foundation
import CocoaLumberjack

/// This service encapsulates all of the Actions that can be performed with a NotificationBlock
///
class NotificationActionsService: LocalCoreDataService {

    /// Follows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func followSiteWithBlock(_ block: FormattableUserContent, completion: ((Bool) -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.uintValue else {
            completion?(false)
            return
        }

        siteService.followSite(withID: siteID, success: {
            DDLogInfo("Successfully followed site \(siteID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to follow site: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        //block.setOverrideValue(true, forAction: .Follow)
    }


    /// Unfollows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unfollowSiteWithBlock(_ block: FormattableUserContent, completion: ((Bool) -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.uintValue else {
            completion?(false)
            return
        }

        siteService.unfollowSite(withID: siteID, success: {
            DDLogInfo("Successfully unfollowed site \(siteID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to unfollow site: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        //block.setOverrideValue(false, forAction: .Follow)
    }


    /// Replies a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Reply's Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func replyCommentWithBlock(_ block: FormattableCommentContent, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.replyToComment(withID: commentID, siteID: siteID, content: content, success: {
            DDLogInfo("Successfully replied to comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to reply comment: \(String(describing: error))")
            completion?(false)
        })
    }


    /// Updates a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Comment's New Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func updateCommentWithBlock(_ block: FormattableCommentContent, content: String, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // Local Override: Temporary hack until the Notification is updated
        block.textOverride = content

        // Hit the backend
        commentService.updateComment(withID: commentID, siteID: siteID, content: content, success: {
            DDLogInfo("Successfully updated to comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to update comment: \(String(describing: error))")
            completion?(false)
        })
    }


    /// Likes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func likeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved == false {
            approveCommentWithBlock(block)
        }

        // Proceed toggling the Like field
        commentService.likeComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully liked comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to like comment: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        //block.setOverrideValue(true, forAction: .Like)
    }


    /// Unlikes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unlikeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unlikeComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully unliked comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to unlike comment: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        //block.setOverrideValue(false, forAction: .Like)
    }


    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func approveCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.approveComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully approved comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to moderate comment: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        //block.setOverrideValue(true, forAction: .Approve)
    }


    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unapproveCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unapproveComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully unapproved comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to moderate comment: \(String(describing: error))")
            //block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        //block.setOverrideValue(false, forAction: .Approve)
    }


    /// Spams a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func spamCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.spamComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully spammed comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to mark comment as spam: \(String(describing: error))")
            completion?(false)
        })
    }


    /// Deletes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func deleteCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)? = nil) {
        guard let commentID = block.metaCommentID, let siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.deleteComment(withID: commentID, siteID: siteID, success: {
            DDLogInfo("Successfully deleted comment \(siteID).\(commentID)")
            self.invalidateCacheAndForceSyncNotification(with: block)
            completion?(true)

        }, failure: { error in
            DDLogError("Error while trying to delete comment: \(String(describing: error))")
            completion?(false)
        })
    }
}



// MARK: - Private Helpers
//
private extension NotificationActionsService {

    /// Invalidates the Local Cache for a given Notification, and re-downloaded from the remote endpoint.
    /// We're doing *both actions* so that in the eventual case of "Broken REST Request", the notification's hash won't match
    /// with the remote value, and the note will be redownloaded upon Sync.
    ///
    /// Required due to a beautiful backend bug. Details here: https://github.com/wordpress-mobile/WordPress-iOS/pull/6871
    ///
    /// - Parameter block: child NotificationBlock object of the Notification-to-be-refreshed.
    ///
    func invalidateCacheAndForceSyncNotification(with block: NotificationTextContent) {
        guard let mediator = NotificationSyncMediator() else {
            return
        }

        let notificationID = block.parent.notificationId
        DDLogInfo("Invalidating Cache and Force Sync'ing Notification with ID: \(notificationID)")
        mediator.invalidateCacheForNotification(with: notificationID)
        mediator.syncNote(with: notificationID)
    }
}



// MARK: - Computed Properties
//
private extension NotificationActionsService {

    var commentService: CommentService {
        return CommentService(managedObjectContext: managedObjectContext)
    }

    var siteService: ReaderSiteService {
        return ReaderSiteService(managedObjectContext: managedObjectContext)
    }
}
