import Foundation
import WordPressShared


extension NotificationsViewController
{
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let note = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Notification else {
            return false
        }
        
        return note.isComment
    }
    
    public override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let note = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Notification,
                    group = note.blockGroupOfType(NoteBlockGroupType.Comment),
                    block = group.blockOfType(.Comment) else {
            return nil
        }
        
        // Helpers
        let isTrashEnabled      = block.isActionEnabled(NoteActionTrashKey)
        let isApproveEnabled    = block.isActionEnabled(NoteActionApproveKey)
        let isApproveOn         = block.isActionOn(NoteActionApproveKey)
        var actions             = [UITableViewRowAction]()
        
        // Comments: Trash
        if isTrashEnabled {
            let title = NSLocalizedString("Trash", comment: "Trashes a comment")
            
            let trash = UITableViewRowAction(style: .Destructive, title: title, handler: { [weak self] action, path in
                self?.trashCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.errorRed()
            actions.append(trash)
        }
        
        // Comments: Unapprove
        if isApproveEnabled && isApproveOn {
            let title = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")
            
            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.unapproveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.grey()
            actions.append(trash)
        }

        // Comments: Approve
        if isApproveEnabled && !isApproveOn {
            let title = NSLocalizedString("Approve", comment: "Approves a Comment")
            
            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.approveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.wordPressBlue()
            actions.append(trash)
        }
        
        return actions
    }
    
    
    private func trashCommentWithBlock(block: NotificationBlock) {
// TODO: Implement Me
    }
    
    private func approveCommentWithBlock(block: NotificationBlock) {
        let context = ContextManager.sharedInstance().mainContext
        let service = CommentService(managedObjectContext: context)
        
        service.approveCommentWithID(block.metaCommentID, siteID: block.metaSiteID, success: {
                DDLogSwift.logInfo("Successfully approved comment \(block.metaSiteID).\(block.metaCommentID)")
            },
            failure: { error in
                DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
                block.removeActionOverrideForKey(NoteActionApproveKey)
            })
        
        block.setActionOverrideValue(true, forKey: NoteActionApproveKey)
    }
    
    private func unapproveCommentWithBlock(block: NotificationBlock) {
        let context = ContextManager.sharedInstance().mainContext
        let service = CommentService(managedObjectContext: context)
        
        service.unapproveCommentWithID(block.metaCommentID, siteID: block.metaSiteID, success: {
                DDLogSwift.logInfo("Successfully unapproved comment \(block.metaSiteID).\(block.metaCommentID)")
            },
            failure: { error in
                DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
                block.removeActionOverrideForKey(NoteActionApproveKey)
            })
        
        block.setActionOverrideValue(false, forKey: NoteActionApproveKey)
    }
}
