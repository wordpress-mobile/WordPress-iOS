import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func removeIfNeeded()
}

enum PostsListSection {
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

    private let postService: PostService

    private var postListFilter: PostListFilter = PostListFilter.draftFilter()

    private var fetchedResultsController: NSFetchedResultsController<Post>!

    private var status: BasePost.Status = .draft

    private var syncing: (NSNumber?, BasePost.Status)?

    private var currentState: PostsListSection = .posts {
        didSet {
            if oldValue != currentState {
                forceReloadSnapshot()
                trackCardDisaplyedIfNeeded()
            }
        }
    }

    private var lastPostsSnapshot: PostsSnapshot?

    private weak var viewController: PostsCardView?

    typealias DataSource = UITableViewDiffableDataSource<PostsListSection, PostsListItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<PostsListSection, PostsListItem>
    typealias PostsSnapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    lazy var diffableDataSource = DataSource(tableView: viewController!.tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
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

    init(blog: Blog, status: BasePost.Status, viewController: PostsCardView, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.blog = blog
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.postService = PostService(managedObjectContext: managedObjectContext)
        self.status = status

        super.init()
    }

    /// Refresh the results and reload the data on the table view
    func refresh() {
        do {
            try fetchedResultsController.performFetch()
            viewController?.tableView.reloadData()
            updatePostsInfoIfNeeded()
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
        let filter = postListFilter

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.authorID = blog.userID
        options.number = Constants.numberOfPostsToSync
        options.order = .descending
        options.orderBy = .byModified
        options.purgesLocalSync = true

        guard syncing?.0 != blog.dotComID && syncing?.1 != status else {
            return
        }

        syncing = (blog.dotComID, status)

        // If the userID is nil we need to sync authors
        // But only if the user is an admin
        if blog.userID == nil && blog.isAdmin {
            syncAuthors()
            return
        }

        postService.syncPosts(
            ofType: .post,
            with: options,
            for: blog,
            success: { [weak self] posts in
                self?.updateDashboardStateWithSuccessfulSync()
                if posts?.count == 0 {
                    self?.updatePostsInfoIfNeeded()
                }

                self?.hideLoading()
                self?.syncing = nil
            }, failure: { [weak self] _ in
                self?.syncing = nil
                if self?.numberOfPosts == 0 {
                    self?.showLoadingFailureError()
                }
                else {
                    self?.hideLoading()
                }
        })
    }

    func syncAuthors() {
        let blogService = BlogService(managedObjectContext: managedObjectContext)
        blogService.syncAuthors(for: blog, success: { [weak self] in
            self?.syncing = nil
            self?.performInitialLoading()
            self?.refresh()
        }, failure: { [weak self] _ in
            self?.syncing = nil
            self?.showLoadingFailureError()
        })
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

    func showLoadingFailureError() {
        currentState = .error
    }

    func hideLoading() {
        currentState = .posts
    }

    func showLoadingIfNeeded() {
        // Only show loading state if there are no posts at all
        if numberOfPosts == 0 && isSyncing() {
            currentState = .loading
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
    func updatePostsInfoIfNeeded() -> Bool {
        if let postsCount = fetchedResultsController?.fetchedObjects?.count, postsCount == 0, !isSyncing() {
            viewController?.removeIfNeeded()
            return true
        }
        return false
    }

    func trackCardDisaplyedIfNeeded() {
        switch currentState {
        case .posts:
            WPAnalytics.track(.dashboardCardShown, properties: ["type": "post", "sub_type": status.rawValue])
        case .error:
            WPAnalytics.track(.dashboardCardShown, properties: ["type": "post", "sub_type": "error"])
        case .loading:
            return
        }
    }

    func isSyncing() -> Bool {
        syncing != nil
    }

    enum Constants {
        static let numberOfPosts = 3
        static let numberOfPostsToSync: NSNumber = 3
    }

    enum Strings {
        static let loadingFailure = NSLocalizedString("Unable to load posts right now.", comment: "Message for when posts fail to load on the dashboard")
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PostsCardViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = viewController?.tableView.dataSource as? DataSource else {
            return
        }

        let postsSnapshot = snapshot as PostsSnapshot
        self.lastPostsSnapshot = postsSnapshot

        guard updatePostsInfoIfNeeded() == false else {
            return // Don't update datasource if the view will be updated
        }

        let currentSnapshot = dataSource.snapshot() as Snapshot
        let finalSnapshot = createSnapshot(currentSnapshot: currentSnapshot, postsSnapshot: postsSnapshot)
        applySnapshot(finalSnapshot, to: dataSource)
    }

    private func forceReloadSnapshot() {
        guard let dataSource = viewController?.tableView.dataSource as? DataSource else {
            return
        }
        let currentSnapshot = dataSource.snapshot() as Snapshot
        let postsSnapshot = self.lastPostsSnapshot ?? NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
        let snapshot = createSnapshot(currentSnapshot: currentSnapshot, postsSnapshot: postsSnapshot)
        applySnapshot(snapshot, to: dataSource)
    }

    private func createSnapshot(currentSnapshot: Snapshot, postsSnapshot: PostsSnapshot) -> Snapshot {
        var snapshot = Snapshot()
        switch currentState {
        case .posts:
            var adjustedPostsSnapshot = postsSnapshot
            adjustedPostsSnapshot.deleteItems(adjustedPostsSnapshot.itemIdentifiers.enumerated().filter { $0.offset > fetchedResultsController.fetchRequest.fetchLimit - 1 }.map { $0.element })
            let postItems: [PostsListItem] = adjustedPostsSnapshot.itemIdentifiers.map { .post($0) }
            snapshot.appendSections([.posts])
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
            snapshot.appendSections([.error])
            snapshot.appendItems([.error], toSection: .error)

        case .loading:
            let items: [PostsListItem] = (0..<Constants.numberOfPosts).map { .ghost($0) }
            snapshot.appendSections([.loading])
            snapshot.appendItems(items, toSection: .loading)
        }
        return snapshot
    }

    private func applySnapshot(_ snapshot: Snapshot, to dataSource: DataSource) {
        let shouldAnimate = viewController?.tableView.numberOfSections != 0 && viewController?.tableView.numberOfRows(inSection: 0) != 0
        dataSource.defaultRowAnimation = .fade
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate, completion: nil)
        viewController?.tableView.allowsSelection = currentState == .posts
    }
}
