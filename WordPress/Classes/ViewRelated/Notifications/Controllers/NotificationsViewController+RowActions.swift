import Foundation
import WordPressShared


extension NotificationsViewController
{
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    public override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let note = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Notification,
                    group = note.blockGroupOfType(NoteBlockGroupType.Comment),
                    block = group.blockOfType(.Comment) else {
            return []
        }

        var actions = [UITableViewRowAction]()
        
        if block.isActionEnabled(NoteActionTrashKey) {
            let title = NSLocalizedString("Trash", comment: "Trashes a comment")
            let handler = { (action: UITableViewRowAction, path: NSIndexPath) -> Void in
// TODO: Implement Me
            }
            
            let trash = UITableViewRowAction(style: .Destructive, title: title, handler: handler)
            trash.backgroundColor = WPStyleGuide.errorRed()
            actions.append(trash)
        }
        
        if block.isActionEnabled(NoteActionApproveKey) {
            let isApproveOn         = block.isActionOn(NoteActionApproveKey)
            let handler             = isApproveOn ? approveComment : unapproveComment
            let title               = isApproveOn ? NSLocalizedString("Unapprove", comment: "Unapproves a Comment") :
                                                    NSLocalizedString("Approve",   comment: "Approves a Comment")
            
            let trash               = UITableViewRowAction(style: .Normal, title: title, handler: handler)
            trash.backgroundColor   = isApproveOn ? WPStyleGuide.grey() : WPStyleGuide.wordPressBlue()
            actions.append(trash)
        }
        
        return actions
    }
    
    
    private func approveComment(action: UITableViewRowAction, path: NSIndexPath) {
// TODO: Implement Me
    }
    
    private func unapproveComment(action: UITableViewRowAction, path: NSIndexPath) {
// TODO: Implement Me
    }
}
