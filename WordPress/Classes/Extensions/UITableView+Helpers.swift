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

    /// Flashes the specified row (selecting and then deselecting), and optionally scrolls to the specified position.
    /// This method uses a default 'flash length' (time between selection and deselection) of 0.7 seconds.
    /// Use `flashRowAtIndexPath(indexPath: NSIndexPath, scrollPosition: UITableViewScrollPosition = default, flashLength: NSTimeInterval, completion: (() -> Void)?)`
    /// to specify a custom length.
    ///
    // - Parameters:
    ///     - indexPath:        The indexPath of the row to flash.
    ///     - scrollPosition:   The position in the table view to scroll the specified row. Use `.None` for no scrolling. Defaults to `.Middle`.
    ///     - completion:       A block to call after the row has been deselected.
    ///
    public func flashRowAtIndexPath(indexPath: NSIndexPath, scrollPosition: UITableViewScrollPosition = .Middle, completion: (() -> Void)?) {
        flashRowAtIndexPath(indexPath, scrollPosition: scrollPosition, flashLength: self.dynamicType.defaultFlashLength, completion: completion)
    }

    /// Flashes the specified row (selecting and then deselecting), and optionally scrolls to the specified position.
    ///
    // - Parameters:
    ///     - indexPath:        The indexPath of the row to flash.
    ///     - scrollPosition:   The position in the table view to scroll the specified row. Use `.None` for no scrolling.
    ///     - flashLength:      The length of time (in seconds) to wait between selecting and deselecting the row.
    ///     - completion:       A block to call after the row has been deselected.
    ///
    func flashRowAtIndexPath(indexPath: NSIndexPath, scrollPosition: UITableViewScrollPosition = .Middle, flashLength: NSTimeInterval, completion: (() -> Void)?) {
        selectRowAtIndexPath(indexPath, animated: true, scrollPosition: scrollPosition)

        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(flashLength * Double(NSEC_PER_SEC)))

        dispatch_after(time, dispatch_get_main_queue()) { [weak self] in
            self?.deselectSelectedRowWithAnimation(true)
            completion?()
        }
    }

    private static let defaultFlashLength: NSTimeInterval = 0.7

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
