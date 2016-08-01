import Foundation


/// This service encapsulates all of the Actions that can be performed with a NotificationBlock
///
public class NotificationActionsService: LocalCoreDataService
{
    /// Designated Initializer
    ///
    /// - Parameter managedObjectContext: A Reference to the MOC that should be used to interact with the Core Data Stack.
    ///
    public override init(managedObjectContext context: NSManagedObjectContext) {
        super.init(managedObjectContext: context)
    }


    ///
    ///
    func followSiteWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext)
        service.followSiteWithID(siteID, success: {
            success?()
        }, failure: { error in
            block.removeActionOverrideForKey(NoteActionFollowKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionFollowKey)
    }


    ///
    ///
    func unfollowSiteWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let siteID = block.metaSiteID?.unsignedIntegerValue else {
            return
        }

        let service = ReaderSiteService(managedObjectContext: managedObjectContext)
        service.unfollowSiteWithID(siteID, success: {
            success?()
        }, failure: { error in
            block.removeActionOverrideForKey(NoteActionFollowKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionFollowKey)
    }


    ///
    ///
    func likeCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
        if block.isCommentApproved() == false {
            approveCommentWithBlock(block, success: nil, failure: nil)
        }

        // Proceed toggling the Like field
        let service = CommentService(managedObjectContext: managedObjectContext)
        service.likeCommentWithID(commentID, siteID: siteID, success: {
            success?()
        }, failure: { error in
            block.removeActionOverrideForKey(NoteActionLikeKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionLikeKey)
    }


    ///
    ///
    func unlikeCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.unlikeCommentWithID(commentID, siteID: siteID, success: {
            success?()
        }, failure: { error in
            block.removeActionOverrideForKey(NoteActionLikeKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionLikeKey)
    }


    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    func approveCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.approveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully approved comment \(block.metaSiteID).\(block.metaCommentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            failure?(error)
        })

        block.setActionOverrideValue(true, forKey: NoteActionApproveKey)
    }


    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    func unapproveCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.unapproveCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully unapproved comment \(block.metaSiteID).\(block.metaCommentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            failure?(error)
        })

        block.setActionOverrideValue(false, forKey: NoteActionApproveKey)
    }


    ///
    ///
    func spamCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.spamCommentWithID(commentID, siteID: siteID, success: {
            success?()
        }, failure: { error in
            failure?(error)
        })
    }


    /// Trashes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    func trashCommentWithBlock(block: NotificationBlock, success: (() -> Void)?, failure: (ErrorType -> Void)?) {
        guard let commentID = block.metaCommentID, siteID = block.metaSiteID else {
            return
        }

        let service = CommentService(managedObjectContext: managedObjectContext)
        service.deleteCommentWithID(commentID, siteID: siteID, success: {
            DDLogSwift.logInfo("Successfully deleted comment \(block.metaSiteID).\(block.metaCommentID)")
            success?()
        }, failure: { error in
            DDLogSwift.logInfo("Error while trying to delete comment: \(error)")
            failure?(error)
        })
    }
}
