import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func showLoading()
    func hideLoading()
    func showError(message: String, retry: Bool)
    func showNextPostPrompt()
    func hideNextPrompt()
    func firstPostPublished()
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

    private var shouldSync: Bool

    private var syncing: (NSNumber?, BasePost.Status)?

    private weak var viewController: PostsCardView?

    init(blog: Blog, status: BasePost.Status, viewController: PostsCardView, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, shouldSync: Bool = true) {
        self.blog = blog
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.postService = PostService(managedObjectContext: managedObjectContext)
        self.status = status
        self.shouldSync = shouldSync

        super.init()
    }

    /// Refresh the results and reload the data on the table view
    func refresh() {
        do {
            try fetchedResultsController.performFetch()
            viewController?.tableView.reloadData()
            showNextPostPromptIfNeeded()
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

    /// Update currently displayed posts for the given blog and status
    func update(blog: Blog, status: BasePost.Status, shouldSync: Bool) {
        if self.blog != blog || self.status != status {
            // If blog and/or status is different, reset the VC
            self.blog = blog
            self.status = status
            self.shouldSync = shouldSync
            performInitialLoading()
            refresh()
        } else {
            // If they're the same, just sync if needed
            self.blog = blog
            self.status = status
            self.shouldSync = shouldSync
            syncIfNeeded()
        }

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
        syncIfNeeded()
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
        var predicates = [NSPredicate]()

        // Show all original posts without a revision & revision posts.
        let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
        predicates.append(basePredicate)

        let filterPredicate = postListFilter.predicateForFetchRequest
        predicates.append(filterPredicate)

        let myAuthorID = blog.userID ?? 0

        // Brand new local drafts have an authorID of 0.
        let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
        predicates.append(authorPredicate)

       let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       return predicate
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return postListFilter.sortDescriptors
    }

    func syncIfNeeded() {
        if shouldSync {
            sync()
        }
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
        if blog.userID == nil {
            syncAuthors()
            return
        }

        postService.syncPosts(
            ofType: .post,
            with: options,
            for: blog,
            success: { [weak self] posts in
                if posts?.count == 0 {
                    self?.showNextPostPrompt()
                }

                self?.hideLoading()
                self?.syncing = nil
            }, failure: { [weak self] _ in
                self?.syncing = nil

                if self?.numberOfPosts == 0 {
                    self?.showNextPostPromptIfNeeded()
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

    func showNextPostPrompt() {
        viewController?.showNextPostPrompt()
        viewController?.hideLoading()
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
        if numberOfPosts == 0 && shouldSync {
            viewController?.showLoading()
        }
    }

    func showNextPostPromptIfNeeded() {
        if let postsCount = fetchedResultsController?.fetchedObjects?.count,
           postsCount == 0, !isSyncing() {
            viewController?.showNextPostPrompt()
        } else {
            viewController?.hideNextPrompt()
        }
    }

    /// If a post is published we want to let the viewController know
    /// So the prompt can be updated
    func checkIfPostIsPublished() {
        if let post = fetchedResultsController.fetchedObjects?.first,
           post.status == .publish || post.status == .publishPrivate {
            viewController?.firstPostPublished()
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

        showNextPostPromptIfNeeded()
        checkIfPostIsPublished()

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
            if let indexPath = indexPath {
                viewController?.tableView.reloadRows(at: [indexPath], with: .fade)
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
