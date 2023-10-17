import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func removeIfNeeded()
}

enum PostsListSection: CaseIterable {
    case posts
    case error
    case loading
}

enum PostsListItem: Hashable {
    case post(NSManagedObjectID)
    case error
    case ghost(Int)
}

/// Responsible for populating a table view with posts
/// And syncing them if needed.
///
class PostsCardViewModel: NSObject {
    var blog: Blog

    private let managedObjectContext: NSManagedObjectContext

    private var postListFilter: PostListFilter = PostListFilter.draftFilter()

    private var fetchedResultsController: NSFetchedResultsController<Post>!

    private var status: BasePost.Status = .draft

    private var isSyncing = false

    private var currentState: PostsListSection = .loading {
        didSet {
            if oldValue != currentState {
                forceReloadSnapshot()
                trackCardDisplayedIfNeeded()
            }
        }
    }

    private var lastPostsSnapshot: PostsSnapshot?

    private weak var view: PostsCardView?

    typealias DataSource = UITableViewDiffableDataSource<PostsListSection, PostsListItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<PostsListSection, PostsListItem>
    typealias PostsSnapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    lazy var diffableDataSource = DataSource(tableView: view!.tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
        guard let self = self else {
            return nil
        }
        switch item {
        case .post(let objectID):
            return self.configurePostCell(objectID: objectID, tableView: tableView, indexPath: indexPath)
        case .error:
            return self.configureErrorCell(tableView: tableView, indexPath: indexPath)
        case .ghost:
            return self.configureGhostCell(tableView: tableView, indexPath: indexPath)
        }

    }

    init(blog: Blog, status: BasePost.Status, view: PostsCardView, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.blog = blog
        self.view = view
        self.managedObjectContext = managedObjectContext
        self.status = status

        super.init()
    }

    /// Refresh the results and reload the data on the table view
    func refresh() {
        do {
            try fetchedResultsController.performFetch()
            view?.tableView.reloadData()
            removeViewIfNeeded()
            showLoadingIfNeeded()
        } catch {
            print("Fetch failed")
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

    /// Return the post at the given IndexPath
    func postAt(_ indexPath: IndexPath) -> Post {
        fetchedResultsController.object(at: indexPath)
    }

    /// The status of post being presented (Draft, Published)
    func currentPostStatus() -> String {
        postListFilter.title
    }

    func stopObserving() {
        DashboardPostsSyncManager.shared.removeListener(self)
        fetchedResultsController.delegate = nil
    }
}

// MARK: Cells Configuration

private extension PostsCardViewModel {
    private func configurePostCell(objectID: NSManagedObjectID, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let post = try? self.managedObjectContext.existingObject(with: objectID) as? Post else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PostCompactCell.defaultReuseID, for: indexPath) as? PostCompactCell

        cell?.accessoryType = .none
        cell?.configureForDashboard(with: post)

        return cell ?? UITableViewCell()
    }

    private func configureErrorCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DashboardPostListErrorCell.defaultReuseID, for: indexPath) as? DashboardPostListErrorCell

        cell?.errorMessage = Strings.loadingFailure
        cell?.onCellTap = { [weak self] in
            self?.retry()
        }

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

private extension PostsCardViewModel {
    var numberOfPosts: Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func performInitialLoading() {
        DashboardPostsSyncManager.shared.addListener(self)
        updateFilter()
        createFetchedResultsController()
        showLoadingIfNeeded()
        sync()
    }

    func createFetchedResultsController() {
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest(), managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        fetchedResultsController.delegate = self
    }

    func fetchRequest() -> NSFetchRequest<Post> {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = predicateForFetchRequest()
        fetchRequest.sortDescriptors = sortDescriptorsForFetchRequest()
        fetchRequest.fetchBatchSize = Constants.numberOfPosts
        fetchRequest.fetchLimit = Constants.numberOfPosts
        return fetchRequest
    }

    func predicateForFetchRequest() -> NSPredicate {
        postListFilter.predicate(for: blog)
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return postListFilter.sortDescriptors
    }

    func sync() {
        isSyncing = true
        let filter = postListFilter
        DashboardPostsSyncManager.shared.syncPosts(blog: blog, postType: .post, statuses: filter.statuses)
    }

    func updateFilter() {
        switch status {
        case .draft:
            self.postListFilter = PostListFilter.draftFilter()
        case .scheduled:
            self.postListFilter = PostListFilter.scheduledFilter()
        default:
            fatalError("Post status not supported")
        }
    }

    func showLoadingFailureErrorIfNeeded() {
        // Only show error state if there are no posts at all
        if numberOfPosts == 0 {
            currentState = .error
        }
        else {
            currentState = .posts
        }
    }

    func hideLoading() {
        currentState = .posts
    }

    func showLoadingIfNeeded() {
        // Only show loading state if there are no posts at all
        if numberOfPosts == 0 && isSyncing {
            currentState = .loading
        }
        else {
            currentState = .posts
        }
    }

    func updateDashboardStateWithSuccessfulSync() {
        switch status {
        case .draft:
            blog.dashboardState.draftsSynced = true
        case .scheduled:
            blog.dashboardState.scheduledSynced = true
        default:
            return
        }
    }

    /// Triggers the view to remove itself if the posts count reached zero and if we are not currently syncing.
    /// - Returns: Boolean value indicating whether an update was needed or not.
    /// Returns true if update was needed, false otherwise.
    @discardableResult
    func removeViewIfNeeded() -> Bool {
        if let postsCount = fetchedResultsController?.fetchedObjects?.count, postsCount == 0, !isSyncing {
            view?.removeIfNeeded()
            return true
        }
        return false
    }

    func trackCardDisplayedIfNeeded() {
        switch currentState {
        case .posts:
            BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": status.rawValue])
        case .error:
            BlogDashboardAnalytics.shared.track(.dashboardCardShown, properties: ["type": "post", "sub_type": "error"])
        case .loading:
            return
        }
    }

    enum Constants {
        static let numberOfPosts = 3
        static let numberOfPostsToSync: NSNumber = 3
    }

    enum Strings {
        static let loadingFailure = NSLocalizedString("Unable to load posts right now.", comment: "Message for when posts fail to load on the dashboard")
    }
}

// MARK: DashboardPostsSyncManagerListener

extension PostsCardViewModel: DashboardPostsSyncManagerListener {
    func postsSynced(success: Bool,
                     blog: Blog,
                     postType: DashboardPostsSyncManager.PostType,
                     for statuses: [BasePost.Status]) {
        let currentStatuses = postListFilter.statuses
        guard postType == .post,
              self.blog == blog,
              currentStatuses.allSatisfy(statuses.contains) else {
            return
        }

        isSyncing = false
        if success {
            updateDashboardStateWithSuccessfulSync()
            if numberOfPosts == 0 {
                removeViewIfNeeded()
            }

            hideLoading()
        }
        else {
            showLoadingFailureErrorIfNeeded()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PostsCardViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = view?.tableView.dataSource as? DataSource else {
            return
        }

        let postsSnapshot = snapshot as PostsSnapshot
        self.lastPostsSnapshot = postsSnapshot

        guard removeViewIfNeeded() == false else {
            return // Don't update datasource if the view will be updated
        }

        let currentSnapshot = dataSource.snapshot() as Snapshot
        let finalSnapshot = createSnapshot(currentSnapshot: currentSnapshot, postsSnapshot: postsSnapshot)
        applySnapshot(finalSnapshot, to: dataSource)
    }

    private func forceReloadSnapshot() {
        guard let dataSource = view?.tableView.dataSource as? DataSource else {
            return
        }
        let currentSnapshot = dataSource.snapshot() as Snapshot
        let postsSnapshot = self.lastPostsSnapshot ?? NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
        let snapshot = createSnapshot(currentSnapshot: currentSnapshot, postsSnapshot: postsSnapshot)
        applySnapshot(snapshot, to: dataSource)
    }

    private func createSnapshot(currentSnapshot: Snapshot, postsSnapshot: PostsSnapshot) -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections(PostsListSection.allCases)
        switch currentState {
        case .posts:
            var adjustedPostsSnapshot = postsSnapshot
            adjustedPostsSnapshot.deleteItems(adjustedPostsSnapshot.itemIdentifiers.enumerated().filter { $0.offset > fetchedResultsController.fetchRequest.fetchLimit - 1 }.map { $0.element })
            let postItems: [PostsListItem] = adjustedPostsSnapshot.itemIdentifiers.map { .post($0) }
            snapshot.appendItems(postItems, toSection: .posts)

            let reloadIdentifiers: [PostsListItem] = snapshot.itemIdentifiers.compactMap { item in
                guard case PostsListItem.post(let objectID) = item,
                        let currentIndex = currentSnapshot.indexOfItem(item), let index = postsSnapshot.indexOfItem(objectID), index == currentIndex else {
                    return nil
                }
                guard let existingObject = try? fetchedResultsController.managedObjectContext.existingObject(with: objectID),
                        existingObject.isUpdated else {
                            return nil
                }
                return item
            }
            snapshot.reloadItems(reloadIdentifiers)

        case .error:
            snapshot.appendItems([.error], toSection: .error)

        case .loading:
            let items: [PostsListItem] = (0..<Constants.numberOfPosts).map { .ghost($0) }
            snapshot.appendItems(items, toSection: .loading)
        }
        return snapshot
    }

    private func applySnapshot(_ snapshot: Snapshot, to dataSource: DataSource) {
        dataSource.defaultRowAnimation = .fade
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        view?.tableView.allowsSelection = currentState == .posts
    }
}
