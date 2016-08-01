import Foundation


/// This service encapsulates all of the Actions that can be performed with a NotificationBlock
///
public class NotificationActionsService: LocalCoreDataService
{
    /// Error Types
    ///
    public enum Error: ErrorType {
        case MissingParameter
    }


    /// Follows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func followSiteWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            failure?(Error.MissingParameter)
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext)
        service.followSiteWithID(siteID, success: {
            DDLogSwift.logInfo("Successfully followed site \(siteID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to follow site: \(error)")
            block.removeActionOverrideForKey(NoteActionFollowKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionFollowKey)
    }


    /// Unfollows a Site referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func unfollowSiteWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            failure?(Error.MissingParameter)
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext)
        service.unfollowSiteWithID(siteID, success: {
            DDLogSwift.logInfo("Successfully unfollowed site \(siteID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to unfollow site: \(error)")
            block.removeActionOverrideForKey(NoteActionFollowKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionFollowKey)
    }


    /// Likes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func likeCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved() == false {
            approveCommentWithBlock(block, success: nil, failure: nil)
        }

        // Proceed toggling the Like field
        let service = CommentService(managedObjectContext: managedObjectContext)
        service.likeCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully liked comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to like comment: \(error)")
            block.removeActionOverrideForKey(NoteActionLikeKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionLikeKey)
    }


    /// Unlikes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func unlikeCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.unlikeCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unliked comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to unlike comment: \(error)")
            block.removeActionOverrideForKey(NoteActionLikeKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionLikeKey)
    }


    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func approveCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.approveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully approved comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionApproveKey)
    }


    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func unapproveCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.unapproveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unapproved comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionApproveKey)
    }


    /// Spams a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func spamCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.spamCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully spammed comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to mark comment as spam: \(error)")
            failure?(error)
        })
    }


    /// Trashes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block: The Notification's Comment Block
    ///     - success: Closure block to be executed on completion
    ///     - failure: Closure block to be executed on failure
    ///
    func trashCommentWithBlock(block: NotificationBlock, success: (() -> Void)? = nil, failure: (ErrorType -> Void)? = nil) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            failure?(Error.MissingParameter)
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.deleteCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully deleted comment \(siteID).\(commentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logError("Error while trying to delete comment: \(error)")
            failure?(error)
        })
    }
}
