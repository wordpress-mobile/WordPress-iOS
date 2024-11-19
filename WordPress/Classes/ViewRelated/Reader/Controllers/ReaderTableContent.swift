import UIKit
import WordPressShared

/// Wraps WPTableViewHandler so that we can start abstracting coredata out of some view controllers
final class ReaderTableContent {
    private var tableViewHandler: WPTableViewHandler?

    func initializeContent(tableView: UITableView, delegate: WPTableViewHandlerDelegate) {
        let tableViewHandler = WPTableViewHandler(tableView: tableView)
        tableViewHandler.cacheRowHeights = false
        tableViewHandler.updateRowAnimation = .none
        tableViewHandler.moveRowAnimation = .none
        tableViewHandler.insertRowAnimation = .none
        tableViewHandler.disableAnimations = true
        tableViewHandler.delegate = delegate
        self.tableViewHandler = tableViewHandler
    }

    func resetResultsController() {
        tableViewHandler?.resetResultsController()
        tableViewHandler?.tableView.reloadData()
        tableViewHandler?.tableView.layoutIfNeeded()

        if !isEmpty {
            tableViewHandler?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    /// The fetch request can need a different predicate depending on how the content
    /// being displayed has changed (blocking sites for instance).  Call this method to
    /// update the fetch request predicate and then perform a new fetch.
    ///
    func updateAndPerformFetchRequest(predicate: NSPredicate) {
        assert(Thread.isMainThread, "Reader Error: updating fetch request on a background thread.")

        tableViewHandler?.resetResultsController()
        tableViewHandler?.resultsController?.fetchRequest.predicate = predicate
        do {
            try tableViewHandler?.resultsController?.performFetch()
        } catch let error as NSError {
            DDLogError("Error fetching posts after updating the fetch reqeust predicate: \(error.localizedDescription)")
        }
    }

    var isNull: Bool {
        return content == nil
    }

    var content: [NSFetchRequestResult]? {
        return tableViewHandler?.resultsController?.fetchedObjects
    }

    var contentCount: Int {
        return content?.count ?? 0
    }

    var isEmpty: Bool {
        return contentCount == 0
    }

    var isScrolling: Bool {
        return tableViewHandler?.isScrolling ?? false
    }

    func refresh() {
        tableViewHandler?.refreshTableView()
    }

    func refreshPreservingOffset() {
        tableViewHandler?.refreshTableViewPreservingOffset()
    }

    func indexPath<T: NSFetchRequestResult>(forObject object: T) -> IndexPath? {
        return tableViewHandler?.resultsController?.indexPath(forObject: object)
    }

    func object<T: NSFetchRequestResult>(at indexPath: IndexPath) -> T? {
        return tableViewHandler?.resultsController?.object(at: indexPath) as? T
    }
}
