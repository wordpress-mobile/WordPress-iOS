import Foundation


class PageListTableViewHandler: WPTableViewHandler {
    var isSearching: Bool = false
    var status: PostListFilter.Status = .published

    private var pages: [Page] = []
    private var groupResults: Bool {
        if isSearching {
            return true
        }

        switch status {
        case .scheduled: return true
        default: return false
        }
    }

    private lazy var groupedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let keyPath = self.sectionNameKeyPath()
        guard let fetchRequest = self.fetchRequest(), let moc = self.managedObjectContext() else {
            fatalError("A request and a context must exist")
        }

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: keyPath, cacheName: nil)

        try! controller.performFetch()
        return controller
    }()

    private lazy var flatResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        guard let fetchRequest = self.fetchRequest(), let moc = self.managedObjectContext() else {
            fatalError("A request and a context must exist")
        }

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)

        try! controller.performFetch()
        return controller
    }()

    override var resultsController: NSFetchedResultsController<NSFetchRequestResult> {
        switch status {
        case .scheduled:
            return groupedResultsController

        default:
            return flatResultsController
        }
    }

    override func refreshTableView() {
        super.clearCachedRowHeights()

        do {
            try resultsController.performFetch()
            setupPages()
        } catch {
            DDLogError("Error fetching pages after refreshing the table: \(error)")
        }

        tableView.reloadData()
    }


    // MARK: - Public methods

    func page(at indexPath: IndexPath) -> Page {
        guard groupResults else {
            return pages[indexPath.row]
        }

        guard let page = resultsController.object(at: indexPath) as? Page else {
            // Retrieveing anything other than a post object means we have an app with an invalid
            // state.  Ignoring this error would be counter productive as we have no idea how this
            // can affect the App.  This controlled interruption is intentional.
            //
            // - Diego Rey Mendez, May 18 2016
            //
            fatalError("Expected a Page object.")
        }

        return page
    }

    func index(for page: Page) -> Int? {
        return pages.index(of: page)
    }

    func removePage(from index: Int) -> [Page] {
        return pages.remove(from: index)
    }


    // MARK: - Override TableView Datasource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groupResults ? super.numberOfSections(in: tableView) : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupResults ? super.tableView(tableView, numberOfRowsInSection: section) : pages.count
    }


    // MARK: - Private methods

    private func fetchRequest() -> NSFetchRequest<NSFetchRequestResult>? {
        return delegate?.fetchRequest()
    }

    private func managedObjectContext() -> NSManagedObjectContext? {
        return delegate?.managedObjectContext()
    }

    private func sectionNameKeyPath() -> String? {
        return delegate?.sectionNameKeyPath!()
    }

    private func setupPages() {
        guard !groupResults, let pages = resultsController.fetchedObjects as? [Page] else {
            return
        }

        if status == .published {
            self.pages = pages.map {
                $0.hasVisibleParent = !$1.containsPage(for: $0.parentID?.intValue)
                return $0
                }
                .sort()
                .hierachyIndexes()
        } else {
            self.pages = pages
        }
    }
}
