extension UITableView {
    /// Deselects the currently selected row. If any
    ///
    @objc func deselectSelectedRowWithAnimation(_ animated: Bool) {
        if let selectedRowIndexPath = indexPathForSelectedRow {
            deselectRow(at: selectedRowIndexPath, animated: animated)
        }
    }

    /// Flashes the specified row (selecting and then deselecting), and optionally scrolls to the specified position.
    ///
    // - Parameters:
    ///     - indexPath:        The indexPath of the row to flash.
    ///     - scrollPosition:   The position in the table view to scroll the specified row. Use `.None` for no scrolling.
    ///     - flashLength:      The length of time (in seconds) to wait between selecting and deselecting the row.
    ///     - completion:       A block to call after the row has been deselected.
    ///
    @objc func flashRowAtIndexPath(_ indexPath: IndexPath, scrollPosition: UITableViewScrollPosition = .middle, flashLength: TimeInterval, completion: (() -> Void)?) {
        selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)

        let time = DispatchTime.now() + Double(Int64(flashLength * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

        DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
            self?.deselectSelectedRowWithAnimation(true)
            completion?()
        }
    }
}
