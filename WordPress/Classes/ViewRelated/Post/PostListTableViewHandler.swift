import Foundation

class PostListTableViewHandler: WPTableViewHandler {
    var isSearching: Bool = false

    private lazy var searchResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        return resultsController(with: fetchRequest(), context: managedObjectContext(), keyPath: BasePost.statusKeyPath, performFetch: false)
    }()

    override var resultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if isSearching {
            return searchResultsController
        }

        return super.resultsController
    }

    private func resultsController(with request: NSFetchRequest<NSFetchRequestResult>?,
                                   context: NSManagedObjectContext?,
                                   keyPath: String? = nil,
                                   performFetch: Bool = true) -> NSFetchedResultsController<NSFetchRequestResult> {
        guard let request = request, let context = context else {
            fatalError("A request and a context must exist")
        }

        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: keyPath, cacheName: nil)
        if performFetch {
            do {
                try controller.performFetch()
            } catch {
                DDLogError("Error fetching pages after refreshing the table: \(error)")
            }
        }

        return controller
    }

    private func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
        return delegate?.fetchRequest()
    }

    private func managedObjectContext() -> NSManagedObjectContext? {
        return delegate?.managedObjectContext()
    }

    private func sectionNameKeyPath() -> String? {
        return delegate?.sectionNameKeyPath?()
    }

    override func refreshTableView() {
        super.refreshTableView()
    }
}
