final class ReaderTableContent {
    private var tableViewHandler: WPTableViewHandler?

    func initializeContent(tableView: UITableView, delegate: WPTableViewHandlerDelegate) {
        tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler?.cacheRowHeights = false
        tableViewHandler?.updateRowAnimation = .none
        tableViewHandler?.delegate = delegate
    }

    /// The fetch request can need a different predicate depending on how the content
    /// being displayed has changed (blocking sites for instance).  Call this method to
    /// update the fetch request predicate and then perform a new fetch.
    ///
    func updateAndPerformFetchRequest(predicate: NSPredicate) {
        assert(Thread.isMainThread, "Reader Error: updating fetch request on a background thread.")

        tableViewHandler?.resultsController.fetchRequest.predicate = predicate
        do {
            try tableViewHandler?.resultsController.performFetch()
        } catch let error as NSError {
            DDLogError("Error fetching posts after updating the fetch reqeust predicate: \(error.localizedDescription)")
        }
    }

    func isEmpty() -> Bool {
        return content() == nil
    }

    func content() -> [NSFetchRequestResult]? {
        return tableViewHandler?.resultsController.fetchedObjects
    }

    func noContent() -> Bool {
        return content()?.count == 0
    }
}
