import Foundation


extension UITableView
{
    public func reloadSelectedRow() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadRowsAtIndexPaths([selectedRowIndexPath], withRowAnimation: .None)
            selectRowAtIndexPath(selectedRowIndexPath, animated: false, scrollPosition: .None)
        }
    }

    public func reloadDataPreservingSelection() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadData()
            selectRowAtIndexPath(selectedRowIndexPath, animated: false, scrollPosition: .None)
        }
    }

    public func deselectSelectedRowWithAnimation(animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            deselectRowAtIndexPath(selectedRowIndexPath, animated: animated)
        }
    }

    public func deselectSelectedRowWithAnimationAfterDelay(animated: Bool) {
        // Note: due to a weird UITableView interaction between reloadData and deselectSelectedRow,
        // we'll introduce a slight delay before deselecting, to avoid getting the highlighted row flickering.
        //
        dispatch_async(dispatch_get_main_queue()) {
            self.deselectSelectedRowWithAnimation(animated)
        }
    }
}
