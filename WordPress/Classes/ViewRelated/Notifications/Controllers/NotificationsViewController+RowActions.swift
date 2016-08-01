import Foundation
import WordPressShared


/// In this Extension, we'll enhance NotificationsViewController, so that it supports *Swipeable* rows.
/// On the first iteration, we'll only support Comment Actions (matching the Push Interactive Notifications
/// actionable items).
///
extension NotificationsViewController
{
    // MARK: - UITableViewDelegate Methods

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let note = tableViewHandler?.resultsController.objectOfType(Notification.self, atIndexPath: indexPath),
                    group = note.blockGroupOfType(NoteBlockGroupType.Comment),
                    block = group.blockOfType(.Comment) else
        {
            // HACK: (JLP 02.16.2016)
            //
            // Not every single row will have actions. For this reason, we'll introduce a slight hack
            // so that the UX isn't terrible.
            // We'll (A) return an Empty UITableViewRowAction, and (B) will hide it after a few seconds.
            //
            stopEditingTableViewAfterDelay()

            // Finally: Return a No-OP Row
            let noop = UITableViewRowAction(style: .Normal, title: title, handler: { action, path in })
            noop.backgroundColor = UIColor.clearColor()
            return [noop]
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
                self?.showUndeleteForNoteWithID(note.objectID) { completion in
                    self?.actionsService.trashCommentWithBlock(block, success: {
                        completion(true)
                    }, failure: { error in
                        completion(false)
                    })
                }

                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.errorRed()
            actions.append(trash)
        }

        // Comments: Unapprove
        if isApproveEnabled && isApproveOn {
            let title = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")

            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.actionsService.unapproveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.grey()
            actions.append(trash)
        }

        // Comments: Approve
        if isApproveEnabled && !isApproveOn {
            let title = NSLocalizedString("Approve", comment: "Approves a Comment")

            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.actionsService.approveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })

            trash.backgroundColor = WPStyleGuide.wordPressBlue()
            actions.append(trash)
        }

        return actions
    }



    // MARK: - Private Helpers

    private func stopEditingTableViewAfterDelay() {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue()) { [weak self] in
            if self?.tableView.editing == true {
                self?.tableView.setEditing(false, animated: true)
            }
        }
    }
}
