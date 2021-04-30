import Foundation


final class PageListTableViewHandler: WPTableViewHandler {
    var isSearching: Bool = false
    var status: PostListFilter.Status = .published
    var groupResults: Bool {
        if isSearching {
            return true
        }

        return status == .scheduled
    }

    private var pages: [Page] = []
    private let blog: Blog
    private lazy var publishedResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let publishedFilter = PostListFilter.publishedFilter()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Page.entityName())
        let predicate = NSPredicate(format: "\(#keyPath(Page.blog)) = %@ && \(#keyPath(Page.revision)) = nil", blog)
        let predicates = [predicate, publishedFilter.predicateForFetchRequest]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = publishedFilter.sortDescriptors
        return resultsController(with: fetchRequest, context: managedObjectContext(), performFetch: false)
    }()

    private lazy var searchResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        return resultsController(with: fetchRequest(), context: managedObjectContext(), keyPath: BasePost.statusKeyPath, performFetch: false)
    }()

    private lazy var groupedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        return resultsController(with: fetchRequest(), context: managedObjectContext(), keyPath: sectionNameKeyPath())
    }()

    private lazy var flatResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        return resultsController(with: fetchRequest(), context: managedObjectContext())
    }()


    init(tableView: UITableView, blog: Blog) {
        self.blog = blog
        super.init(tableView: tableView)
    }

    override var resultsController: NSFetchedResultsController<NSFetchRequestResult> {
        if isSearching {
            return searchResultsController
        }

        return groupResults ? groupedResultsController : flatResultsController
    }

    override func refreshTableView() {
        refreshTableView(at: nil)
    }

    func refreshTableView(at indexPath: IndexPath?) {
        super.clearCachedRowHeights()

        do {
            try resultsController.performFetch()
            pages = setupPages()
        } catch {
            DDLogError("Error fetching pages after refreshing the table: \(error)")
        }

        if let indexPath = indexPath {
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
        } else {
            tableView.reloadData()
        }
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
        return pages.firstIndex(of: page)
    }

    func removePage(from index: Int?) -> [Page] {
        guard let index = index, status == .published else {
            do {
                try publishedResultController.performFetch()
                if let pages = publishedResultController.fetchedObjects as? [Page] {
                    return pages.setHomePageFirst().hierarchySort()
                }
            } catch {
                DDLogError("Error fetching pages after refreshing the table: \(error)")
            }

            return []
        }

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
        return delegate?.sectionNameKeyPath!()
    }

    private func setupPages() -> [Page] {
        guard !groupResults, let pages = resultsController.fetchedObjects as? [Page] else {
            return []
        }

        return status == .published ? pages.setHomePageFirst().hierarchySort() : pages
    }
}
