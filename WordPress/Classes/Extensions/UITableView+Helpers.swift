import Foundation


extension UITableView
{
    public func deselectSelectedRowWithAnimation(animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow() {
            self.deselectRowAtIndexPath(selectedRowIndexPath, animated: animated)
        }
    }
}