final class ReaderTableContent {
    private var tableViewHandler: WPTableViewHandler?

    func initializeContent(tableView: UITableView, delegate: WPTableViewHandlerDelegate) {
        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler?.cacheRowHeights = false
        tableViewHandler?.updateRowAnimation = .none
        tableViewHandler?.delegate = delegate
    }
}
