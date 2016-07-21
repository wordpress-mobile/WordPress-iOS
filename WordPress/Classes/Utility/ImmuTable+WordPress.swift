import WordPressShared

/// This lives as an extension on a separate file because it's specific to our UI
/// implementation and shouldn't be in a generic ImmuTable that we might eventually
/// release as a standalone library.
///
extension ImmuTableViewHandler {

    public func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionHeader(view)
    }

    public func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
    }
}
