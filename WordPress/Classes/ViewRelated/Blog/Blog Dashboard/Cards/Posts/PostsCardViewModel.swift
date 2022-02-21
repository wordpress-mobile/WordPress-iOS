import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func showLoading()
    func hideLoading()
    func showError(message: String, retry: Bool)
}

/// Responsible for populating a table view with posts
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
        } catch {
            print("Fetch failed")
        }
    }

    func retry() {
        viewController?.showLoading()
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

    /// Update currently displayed posts for the given blog and status
    func update(blog: Blog, status: BasePost.Status) {
        self.blog = blog
        self.status = status
        performInitialLoading()
        refresh()
    }
}

// MARK: - Private methods

private extension PostsCardViewModel {
    var numberOfPosts: Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func performInitialLoading() {
        viewController?.showLoading()
        updateFilter()
        createFetchedResultsController()
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
        var predicates = [NSPredicate]()

        // Show all original posts without a revision & revision posts.
        let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
        predicates.append(basePredicate)

        let filterPredicate = postListFilter.predicateForFetchRequest
        predicates.append(filterPredicate)

       let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       return predicate
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return postListFilter.sortDescriptors
    }

    func sync() {
        let filter = postListFilter

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.number = Constants.numberOfPostsToSync
        options.purgesLocalSync = true

        guard syncing?.0 != blog.dotComID && syncing?.1 != status else {
            return
        }

        syncing = (blog.dotComID, status)

        postService.syncPosts(
            ofType: .post,
            with: options,
            for: blog,
            success: { [weak self] _ in
                if self?.numberOfPosts == 0 {
                    self?.showEmptyPostsError()
                }

                self?.syncing = nil
            }, failure: { [weak self] _ in
                if self?.numberOfPosts == 0 {
                    self?.showLoadingFailureError()
                }

                self?.syncing = nil
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

    func showEmptyPostsError() {
        viewController?.hideLoading()
        viewController?.showError(message: Strings.noPostsMessage, retry: false)
    }

    func showLoadingFailureError() {
        viewController?.hideLoading()
        viewController?.showError(message: Strings.loadingFailure, retry: true)
    }

    enum Constants {
        static let numberOfPosts = 3
        static let numberOfPostsToSync: NSNumber = 4
    }

    enum Strings {
        static let noPostsMessage = NSLocalizedString("You don't have any posts", comment: "Displayed when the user views the dashboard posts card but they have no posts")
        static let loadingFailure = NSLocalizedString("Unable to load posts right now.", comment: "Message for when posts fail to load on the dashboard")
    }
}

// MARK: - UITableViewDataSource

extension PostsCardViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCompactCell.defaultReuseID, for: indexPath)

        viewController?.hideLoading()

        configureCell(cell, at: indexPath)

        return cell
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        cell.accessoryType = .none

        let post: Post = fetchedResultsController.object(at: indexPath)

        guard let configurablePostView = cell as? PostCompactCell else {
                fatalError("Cell is not a PostCompactCell")
        }

        configurablePostView.configureForDashboard(with: post)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PostsCardViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        viewController?.tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        viewController?.tableView.endUpdates()

        // When going to the post list all displayed posts there will be displayed
        // here too. This check ensures that we never display more than what
        // is specified on the `fetchLimit` property
        if fetchedResultsController.fetchRequest.fetchLimit > 0 && fetchedResultsController.fetchRequest.fetchLimit < fetchedResultsController.fetchedObjects?.count ?? 0 {
            try? fetchedResultsController.performFetch()
            viewController?.tableView.reloadData()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                viewController?.tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                viewController?.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .update:
            if let indexPath = indexPath, let cell = viewController?.tableView.cellForRow(at: indexPath) {
                configureCell(cell, at: indexPath)
            }
            break
        case .move:
            if let indexPath = indexPath {
                viewController?.tableView.deleteRows(at: [indexPath], with: .fade)
            }

            if let newIndexPath = newIndexPath {
                viewController?.tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break
        @unknown default:
            break
        }
    }
}
