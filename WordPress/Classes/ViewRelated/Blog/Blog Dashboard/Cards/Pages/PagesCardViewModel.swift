import Foundation
import CoreData
import UIKit

protocol PagesCardView: AnyObject {
    var tableView: UITableView { get }
}

fileprivate enum PagesState: CaseIterable {
    case loading
    case loaded
}

enum PagesListSection: CaseIterable {
    case pages
    case loading
    case create
}

enum PagesListItem: Hashable {
    case page(NSManagedObjectID)
    case ghost(Int)
    case createPage(expanded: Bool, hasPages: Bool)
}

/// Responsible for populating a table view with pages
/// And syncing them if needed.
///
class PagesCardViewModel: NSObject {
    var blog: Blog

    private let managedObjectContext: NSManagedObjectContext

    private var filter: PostListFilter = PostListFilter.allNonTrashedFilter()

    private var fetchedResultsController: NSFetchedResultsController<Page>?

    private var isSyncing = false

    private var currentState: PagesState = .loading {
        didSet {
            if oldValue != currentState {
                forceReloadSnapshot()
                trackCardDisplayedIfNeeded()
            }
        }
    }

    private var lastPagesSnapshot: PagesSnapshot?

    private weak var view: PagesCardView?

    typealias DataSource = UITableViewDiffableDataSource<PagesListSection, PagesListItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<PagesListSection, PagesListItem>
    typealias PagesSnapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    lazy var diffableDataSource = DataSource(tableView: view!.tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
        guard let self = self else {
            return nil
        }
        switch item {
        case .page(let objectID):
            return self.configurePageCell(objectID: objectID, tableView: tableView, indexPath: indexPath)
        case .ghost:
            return self.configureGhostCell(tableView: tableView, indexPath: indexPath)
        case .createPage(let expanded, let hasPages):
            return UITableViewCell()
        }

    }

    init(blog: Blog, view: PagesCardView, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.blog = blog
        self.view = view
        self.managedObjectContext = managedObjectContext

        super.init()
    }

    /// Refresh the results and reload the data on the table view
    func refresh() {
        do {
            try fetchedResultsController?.performFetch()
            view?.tableView.reloadData()
            showLoadingIfNeeded()
        } catch {
            DDLogError("Pages Dashboard Card: Failed to fetch pages from core data")
        }
    }

    func retry() {
        showLoadingIfNeeded()
        sync()
    }

    /// Set up the view model to be ready for use
    func viewDidLoad() {
        performInitialLoading()
        refresh()
    }

    /// Return the page at the given IndexPath
    func pageAt(_ indexPath: IndexPath) -> Page? {
        fetchedResultsController?.object(at: indexPath)
    }

    func tearDown() {
        DashboardPostsSyncManager.shared.removeListener(self)
        fetchedResultsController?.delegate = nil
    }
}

// MARK: Cells Configuration

private extension PagesCardViewModel {
    private func configurePageCell(objectID: NSManagedObjectID, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let page = try? self.managedObjectContext.existingObject(with: objectID) as? Page else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: DashboardPageCell.defaultReuseID, for: indexPath) as? DashboardPageCell

        cell?.accessoryType = .none
        cell?.configure(using: page, rowIndex: indexPath.row)

        return cell ?? UITableViewCell()
    }

    private func configureGhostCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlogDashboardPostCardGhostCell.defaultReuseID, for: indexPath) as? BlogDashboardPostCardGhostCell
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .placeholderElementFaded)
        cell?.contentView.stopGhostAnimation()
        cell?.contentView.startGhostAnimation(style: style)
        return cell ?? UITableViewCell()
    }
}

// MARK: - Private methods

private extension PagesCardViewModel {
    var numberOfPages: Int {
        fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    func performInitialLoading() {
        DashboardPostsSyncManager.shared.addListener(self)
        createFetchedResultsController()
        showLoadingIfNeeded()
        sync()
    }

    func createFetchedResultsController() {
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest(), managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        fetchedResultsController?.delegate = self
    }

    func fetchRequest() -> NSFetchRequest<Page> {
        let fetchRequest = NSFetchRequest<Page>(entityName: String(describing: Page.self))
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        fetchRequest.fetchBatchSize = Constants.numberOfPages
        fetchRequest.fetchLimit = Constants.numberOfPages
        return fetchRequest
    }

    func predicateForFetchRequest() -> NSPredicate {
        filter.predicate(for: blog)
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return filter.sortDescriptors
    }

    func sync() {
        isSyncing = true
        let filter = filter
        DashboardPostsSyncManager.shared.syncPosts(blog: blog, postType: .page, statuses: filter.statuses.strings)
    }

    func hideLoading() {
        currentState = .loaded
    }

    func showLoadingIfNeeded() {
        // Only show loading state if there are no pages at all
        if numberOfPages == 0 && isSyncing {
            currentState = .loading
        }
        else {
            currentState = .loaded
        }
    }

    func updateDashboardStateWithSuccessfulSync() {
        // TODO: Do something like this:
        // blog.dashboardState.pagesSynced = true
        // This will be needed if we need to determine if there are pages
        // or not while parsing the cards endpoint response
    }

    func trackCardDisplayedIfNeeded() {
        // TODO: Implement tracking
    }

    enum Constants {
        static let numberOfPages = 3
    }
}

// MARK: DashboardPostsSyncManagerListener

extension PagesCardViewModel: DashboardPostsSyncManagerListener {
    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     posts: [AbstractPost]?,
                     for statuses: [String]) {
        guard postType == .page,
              self.blog == blog else {
            return
        }

        isSyncing = false
        if success {
            updateDashboardStateWithSuccessfulSync()

            hideLoading()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PagesCardViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = view?.tableView.dataSource as? DataSource else {
            return
        }

        let pagesSnapshot = snapshot as PagesSnapshot
        self.lastPagesSnapshot = pagesSnapshot

        let currentSnapshot = dataSource.snapshot() as Snapshot
        let finalSnapshot = createSnapshot(currentSnapshot: currentSnapshot, pagesSnapshot: pagesSnapshot)
        applySnapshot(finalSnapshot, to: dataSource)
    }

    private func forceReloadSnapshot() {
        guard let dataSource = view?.tableView.dataSource as? DataSource else {
            return
        }
        let currentSnapshot = dataSource.snapshot() as Snapshot
        let pagesSnapshot = self.lastPagesSnapshot ?? NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
        let snapshot = createSnapshot(currentSnapshot: currentSnapshot, pagesSnapshot: pagesSnapshot)
        applySnapshot(snapshot, to: dataSource)
    }

    private func createSnapshot(currentSnapshot: Snapshot, pagesSnapshot: PagesSnapshot) -> Snapshot {
        var snapshot = Snapshot()
        switch currentState {
        case .loaded:
            snapshot.appendSections([.pages, .create])
            var adjustedPagesSnapshot = pagesSnapshot

            // Delete extra pages
            let sequenceToDelete = adjustedPagesSnapshot.itemIdentifiers.enumerated().filter { $0.offset > Constants.numberOfPages - 1 }
            let managedObjectIDsToDelete = sequenceToDelete.map { $0.element }
            adjustedPagesSnapshot.deleteItems(managedObjectIDsToDelete)

            // Add pages to new snapshot
            let pageItems: [PagesListItem] = adjustedPagesSnapshot.itemIdentifiers.map { .page($0) }
            snapshot.appendItems(pageItems, toSection: .pages)

            // Reload items if needed
            let reloadIdentifiers = identifiersToBeReloaded(newSnapshot: snapshot,
                                                            currentSnapshot: currentSnapshot,
                                                            pagesSnapshot: pagesSnapshot)
            snapshot.reloadItems(reloadIdentifiers)

            snapshot.appendItems([.createPage(expanded: true, hasPages: true)], toSection: .create)

        case .loading:
            snapshot.appendSections([.loading])
            let items: [PagesListItem] = (0..<Constants.numberOfPages).map { .ghost($0) }
            snapshot.appendItems(items, toSection: .loading)
        }
        return snapshot
    }


    /// Returns items that need to be reloaded. These are items that haven't changed position, but their date was updated.
    /// - Parameters:
    ///   - newSnapshot: The snapshot that should be reloaded
    ///   - currentSnapshot: The old snapshot. Used to check if the item changed position
    ///   - pagesSnapshot: Snapshot retrieved from CoreDate
    /// - Returns: Array of items that should be reloaded
    private func identifiersToBeReloaded(newSnapshot: Snapshot, currentSnapshot: Snapshot, pagesSnapshot: PagesSnapshot) -> [PagesListItem] {
        return newSnapshot.itemIdentifiers.compactMap { item in
            guard case PagesListItem.page(let objectID) = item,
                  let currentIndex = currentSnapshot.indexOfItem(item),
                  let index = pagesSnapshot.indexOfItem(objectID),
                  index == currentIndex else {
                return nil // No need to reload if the index changed
            }
            guard let existingObject = try? fetchedResultsController?.managedObjectContext.existingObject(with: objectID),
                  existingObject.isUpdated else {
                return nil // No need to reload if the object wasn't updated
            }
            return item
        }
    }

    private func applySnapshot(_ snapshot: Snapshot, to dataSource: DataSource) {
        dataSource.defaultRowAnimation = .fade
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        view?.tableView.allowsSelection = currentState == .loaded
    }
}
