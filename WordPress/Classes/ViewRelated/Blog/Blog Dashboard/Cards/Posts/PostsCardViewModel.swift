import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func showLoading()
    func hideLoading()
    func showError(message: String, retry: Bool)
    func hideError()
    func updatePostsInfo(hasPosts: Bool)
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

    private weak var viewController: PostsCardView?

    typealias DataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    lazy var diffableDataSource = DataSource(tableView: viewController!.tableView) { [weak self] (tableView, indexPath, objectID) -> UITableViewCell? in
        guard let self = self,
            let post = try? self.managedObjectContext.existingObject(with: objectID) as? Post else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PostCompactCell.defaultReuseID, for: indexPath)

        self.viewController?.hideLoading()

        self.configureCell(cell, at: indexPath, with: post)

        return cell
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

// MARK: - Private methods

private extension PostsCardViewModel {
    var numberOfPosts: Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func performInitialLoading() {
        updateFilter()
        createFetchedResultsController()
        sync()
        showLoadingIfNeeded()
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
                if posts?.count == 0 {
                    self?.updatePostsInfoIfNeeded()
                    self?.viewController?.hideLoading()
                }

                self?.hideLoading()
                self?.syncing = nil
            }, failure: { [weak self] _ in
                self?.syncing = nil

                if self?.numberOfPosts == 0 {
                    self?.updatePostsInfoIfNeeded()
                    self?.showLoadingFailureError()
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
        viewController?.showError(message: Strings.loadingFailure, retry: true)
        viewController?.hideLoading()
    }

    func hideLoading() {
        viewController?.hideLoading()
    }

    func showLoadingIfNeeded() {
        // Only show loading state if there are no posts at all
        if numberOfPosts == 0 {
            viewController?.showLoading()
        }
    }

    func updatePostsInfoIfNeeded() {
        if let postsCount = fetchedResultsController?.fetchedObjects?.count, postsCount == 0, !isSyncing() {
            viewController?.updatePostsInfo(hasPosts: false)
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
        var snapshot = snapshot as Snapshot
        let currentSnapshot = dataSource.snapshot() as Snapshot

        /// Ensure a maximum of `fetchRequest.fetchLimit` items is displayed
        snapshot.deleteItems(snapshot.itemIdentifiers.enumerated().filter { $0.offset > fetchedResultsController.fetchRequest.fetchLimit - 1 }.map { $0.element })

        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)

        let shouldAnimate = viewController?.tableView.numberOfSections != 0 && viewController?.tableView.numberOfRows(inSection: 0) != 0
        dataSource.defaultRowAnimation = .fade
        dataSource.apply(snapshot as Snapshot,
                         animatingDifferences: shouldAnimate,
                         completion: { [weak self] in
            self?.updatePostsInfoIfNeeded() // TODO: Move this outside completion
        })
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath, with post: Post) {
        cell.accessoryType = .none
        guard let configurablePostView = cell as? PostCompactCell else {
                fatalError("Cell is not a PostCompactCell")
        }

        viewController?.hideError()
        configurablePostView.configureForDashboard(with: post)
    }
}
