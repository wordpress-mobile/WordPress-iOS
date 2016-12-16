import Foundation


extension UITableView
{
    /// Reloads the currently selected row, if any.
    ///
    public func reloadSelectedRow() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadRows(at: [selectedRowIndexPath], with: .none)
            selectRow(at: selectedRowIndexPath, animated: false, scrollPosition: .none)
        }
    }

    /// Reloads the tableView's data, while preserving the currently selected row.
    ///
    public func reloadDataPreservingSelection() {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            reloadData()
            selectRow(at: selectedRowIndexPath, animated: false, scrollPosition: .none)
        }
    }

    /// Deselects the currently selected row. If any
    ///
    public func deselectSelectedRowWithAnimation(_ animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            deselectRow(at: selectedRowIndexPath, animated: animated)
        }
    }

    /// Deselects the currently selected row, asynchronously
    ///
    public func deselectSelectedRowWithAnimationAfterDelay(_ animated: Bool) {
        // Note: due to a weird UITableView interaction between reloadData and deselectSelectedRow,
        // we'll introduce a slight delay before deselecting, to avoid getting the highlighted row flickering.
        //
        DispatchQueue.main.async {
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
    public func flashRowAtIndexPath(_ indexPath: IndexPath, scrollPosition: UITableViewScrollPosition = .middle, completion: (() -> Void)?) {
        flashRowAtIndexPath(indexPath, scrollPosition: scrollPosition, flashLength: type(of: self).defaultFlashLength, completion: completion)
    }

    /// Flashes the specified row (selecting and then deselecting), and optionally scrolls to the specified position.
    ///
    // - Parameters:
    ///     - indexPath:        The indexPath of the row to flash.
    ///     - scrollPosition:   The position in the table view to scroll the specified row. Use `.None` for no scrolling.
    ///     - flashLength:      The length of time (in seconds) to wait between selecting and deselecting the row.
    ///     - completion:       A block to call after the row has been deselected.
    ///
    func flashRowAtIndexPath(_ indexPath: IndexPath, scrollPosition: UITableViewScrollPosition = .middle, flashLength: TimeInterval, completion: (() -> Void)?) {
        selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)

        let time = DispatchTime.now() + Double(Int64(flashLength * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            self?.deselectSelectedRowWithAnimation(true)
            completion?()
        }
    }

    fileprivate static let defaultFlashLength: TimeInterval = 0.7

    /// Disables Editing after a specified delay.
    ///
    /// -   Parameter delay: milliseconds to elapse before edition will be disabled.
    ///
    public func disableEditionAfterDelay(_ delay: TimeInterval = defaultDelay) {
        let delay = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
            if self?.isEditing == true {
                self?.setEditing(false, animated: true)
            }
        }
    }

    /// Default Disable Edition Action Delay
    ///
    fileprivate static let defaultDelay = TimeInterval(0.2)
}
