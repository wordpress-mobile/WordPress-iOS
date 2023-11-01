import Foundation

final class PageListTableViewHandler: WPTableViewHandler {
    var status: PostListFilter.Status = .published

    var showEditorHomepage: Bool {
        guard RemoteFeatureFlag.siteEditorMVP.enabled() else {
            return false
        }

        let isFSETheme = blog.blockEditorSettings?.isFSETheme ?? false
        return isFSETheme && status == .published
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

    private lazy var _resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        resultsController(with: fetchRequest(), context: managedObjectContext())
    }()

    init(tableView: UITableView, blog: Blog) {
        self.blog = blog
        super.init(tableView: tableView)
    }

    override var resultsController: NSFetchedResultsController<NSFetchRequestResult> {
        _resultsController
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
        pages[indexPath.row]
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
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pages.count + (showEditorHomepage ? 1 : 0)
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

    private func setupPages() -> [Page] {
        guard let pages = _resultsController.fetchedObjects as? [Page] else {
            return []
        }
        return status == .published ? pages.setHomePageFirst().hierarchySort() : pages
    }
}
