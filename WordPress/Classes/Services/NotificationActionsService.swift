import Foundation


/// This service encapsulates all of the Actions that can be performed with a NotificationBlock
///
public class NotificationActionsService: LocalCoreDataService
{
    /// Follows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func followSiteWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            completion?(false)
            return
        }

        siteService.followSiteWithID(siteID, success: {
            DDLogSwift.logInfo("Successfully followed site \(siteID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to follow site: \(error)")
            block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Follow)
    }


    /// Unfollows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Site Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unfollowSiteWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            completion?(false)
            return
        }

        siteService.unfollowSiteWithID(siteID, success: {
            DDLogSwift.logInfo("Successfully unfollowed site \(siteID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to unfollow site: \(error)")
            block.removeOverrideValueForAction(.Follow)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Follow)
    }


    /// Replies a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Reply's Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func replyCommentWithBlock(block: NotificationBlock, content: String, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.replyToCommentWithID(commentID, siteID: siteID, content: content, success: {
            DDLogSwift.logInfo("Successfully replied to comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to reply comment: \(error)")
            completion?(false)
        })
    }


    /// Updates a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter content: The Comment's New Content
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func updateCommentWithBlock(block: NotificationBlock, content: String, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // Local Override: Temporary hack until Simperium reflects the REST op
        block.textOverride = content

        // Hit the backend
        commentService.updateCommentWithID(commentID, siteID: siteID, content: content, success: {
            DDLogSwift.logInfo("Successfully updated to comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to update comment: \(error)")
            completion?(false)
        })
    }


    /// Likes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func likeCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved == false {
            approveCommentWithBlock(block)
        }

        // Proceed toggling the Like field
        commentService.likeCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully liked comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to like comment: \(error)")
            block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Like)
    }


    /// Unlikes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unlikeCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unlikeCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unliked comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to unlike comment: \(error)")
            block.removeOverrideValueForAction(.Like)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Like)
    }


    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func approveCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.approveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully approved comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        block.setOverrideValue(true, forAction: .Approve)
    }


    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func unapproveCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.unapproveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unapproved comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeOverrideValueForAction(.Approve)
            completion?(false)
        })

        block.setOverrideValue(false, forAction: .Approve)
    }


    /// Spams a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func spamCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.spamCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully spammed comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to mark comment as spam: \(error)")
            completion?(false)
        })
    }


    /// Deletes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameter block: The Notification's Comment Block
    /// - Parameter completion: Closure block to be executed on completion, indicating if we've succeeded or not.
    ///
    func deleteCommentWithBlock(block: NotificationBlock, completion: (Bool -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            completion?(false)
            return
        }

        commentService.deleteCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully deleted comment \(siteID).\(commentID)")
            completion?(true)
        }, failure: { error in
            DDLogSwift.logError("Error while trying to delete comment: \(error)")
            completion?(false)
        })
    }



    // MARK: - Private Helpers

    private var commentService: CommentService {
        return CommentService(managedObjectContext: managedObjectContext)
    }

    private var siteService: ReaderSiteService {
        return ReaderSiteService(managedObjectContext: managedObjectContext)
    }
}
