import WordPressShared

/*
Until https://github.com/wordpress-mobile/WordPress-iOS/pull/4591 is fixed, we
need to use the custom WPTableViewSectionHeaderFooterView.

This lives as an extension on a separate file because it's specific to our UI
implementation and shouldn't be in a generic ImmuTable that we might eventually
release as a standalone library.
*/
extension ImmuTableViewHandler {
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let title = self.tableView(tableView, titleForHeaderInSection: section) {
            return WPTableViewSectionHeaderFooterView.heightForHeader(title, width: tableView.frame.width)
        } else {
            return UITableViewAutomaticDimension
        }
    }

    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }

        let view = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Header)
        view.title = title
        return view
    }

    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let title = self.tableView(tableView, titleForFooterInSection: section) {
            return WPTableViewSectionHeaderFooterView.heightForFooter(title, width: tableView.frame.width)
        } else {
            return UITableViewAutomaticDimension
        }
    }

    public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForFooterInSection: section) else {
            return nil
        }

        let view = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        view.title = title
        return view
    }
}
