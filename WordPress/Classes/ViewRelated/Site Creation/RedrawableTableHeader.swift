protocol RedrawableTableHeader {
    func refreshTableViewHeaderLayout(_ table: UITableView)
}

extension RedrawableTableHeader where Self: UIViewController {
    func refreshTableViewHeaderLayout(_ table: UITableView) {
        guard let headerView = table.tableHeaderView else {
            return
        }

        // The tableView may need to layout, run this layout now, if needed.
        // This ensures the proper margins, such as readable margins, are
        // inherited and calculated by the headerView.
        table.layoutIfNeeded()

        // Start with the provided UILayoutFittingCompressedSize to let iOS handle its own magic
        // number for a "compressed" height, meaning we want our fitting size to be the minimal height.
        var fittingSize = UIView.layoutFittingCompressedSize

        // Set the width to the tableView's width since this is a known width for the headerView.
        // Otherwise, the layout will try and adopt 'any' width and may break based on the how
        // the constraints are set up in the nib.
        fittingSize.width = table.frame.size.width

        // Require horizontal fitting since our width is known.
        // Use the lower fitting size priority as we want to minimize our height consumption
        // according to the layout's contraints and intrinsic size.
        let size = headerView.systemLayoutSizeFitting(fittingSize,
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
        // Update the tableHeaderView itself. Classic.
        var headerFrame = headerView.frame
        headerFrame.size.height = size.height
        headerView.frame = headerFrame
        table.tableHeaderView = headerView
    }
}
