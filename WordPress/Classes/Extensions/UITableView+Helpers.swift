import Foundation


extension UITableView
{
    public func reloadSelectedRow() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadRowsAtIndexPaths([selectedRowIndexPath], withRowAnimation: .None)
            selectRowAtIndexPath(selectedRowIndexPath, animated: false, scrollPosition: .None)
        }
    }

    public func deselectSelectedRowWithAnimation(animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            deselectRowAtIndexPath(selectedRowIndexPath, animated: animated)
        }
    }
}
