import Foundation


extension UITableView
{
    /// Reloads the currently selected row, if any.
    ///
    public func reloadSelectedRow() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadRowsAtIndexPaths([selectedRowIndexPath], withRowAnimation: .None)
            selectRowAtIndexPath(selectedRowIndexPath, animated: false, scrollPosition: .None)
        }
    }

    /// Reloads the tableView's data, while preserving the currently selected row.
    ///
    public func reloadDataPreservingSelection() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadData()
            selectRowAtIndexPath(selectedRowIndexPath, animated: false, scrollPosition: .None)
        }
    }

    /// Deselects the currently selected row. If any
    ///
    public func deselectSelectedRowWithAnimation(animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            deselectRowAtIndexPath(selectedRowIndexPath, animated: animated)
        }
    }

    /// Deselects the currently selected row, asynchronously
    ///
    public func deselectSelectedRowWithAnimationAfterDelay(animated: Bool) {
        // Note: due to a weird UITableView interaction between reloadData and deselectSelectedRow,
        // we'll introduce a slight delay before deselecting, to avoid getting the highlighted row flickering.
        //
        dispatch_async(dispatch_get_main_queue()) {
            self.deselectSelectedRowWithAnimation(animated)
        }
    }

    /// Disables Editing after a specified delay.
    ///
    /// -   Parameter delay: milliseconds to elapse before edition will be disabled.
    ///
    public func disableEditionAfterDelay(delay: NSTimeInterval = defaultDelay) {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue()) { [weak self] in
            if self?.editing == true {
                self?.setEditing(false, animated: true)
            }
        }
    }

    /// Default Disable Edition Action Delay
    ///
    private static let defaultDelay = NSTimeInterval(0.2)
}
