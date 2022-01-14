import Foundation
import CoreData
import UIKit

protocol PostsCardView: AnyObject {
    var tableView: UITableView { get }

    func showLoading()
    func hideLoading()
}

/// Responsible for populating a table view with posts
///
class PostsCardViewModel: NSObject {
    var blog: Blog

    private let managedObjectContext: NSManagedObjectContext

    private let postService: PostService

    lazy var filterSettings: PostListFilterSettings = {
        PostListFilterSettings(blog: blog, postType: .post)
    }()

    private var fetchedResultsController: NSFetchedResultsController<Post>!

    private weak var viewController: PostsCardView?

    init(blog: Blog, viewController: PostsCardView, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.blog = blog
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.postService = PostService(managedObjectContext: managedObjectContext)
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

    /// Set up the view model to be ready for use
    func viewDidLoad() {
        viewController?.showLoading()
        createFetchedResultsController()
        sync()
    }

    /// Return the post at the given IndexPath
    func postAt(_ indexPath: IndexPath) -> Post {
        fetchedResultsController.object(at: indexPath)
    }

    /// The status of post being presented (Draft, Published)
    func currentPostStatus() -> String {
        filterSettings.currentPostListFilter().title
    }
}

// MARK: - Private methods

private extension PostsCardViewModel {
    func createFetchedResultsController() {
        // 0 = published, 1 = draft, 2 = scheduled
        filterSettings.setCurrentFilterIndex(1)

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

        let filterPredicate = filterSettings.currentPostListFilter().predicateForFetchRequest
        predicates.append(filterPredicate)

       let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       return predicate
    }

    func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        return filterSettings.currentPostListFilter().sortDescriptors
    }

    func sync() {
        let filter = filterSettings.currentPostListFilter()

        let options = PostServiceSyncOptions()
        options.statuses = filter.statuses.strings
        options.number = Constants.numberOfPostsToSync
        options.purgesLocalSync = true

        postService.syncPosts(
            ofType: .post,
            with: options,
            for: blog,
            success: { _ in

            }, failure: { (error: Error?) -> () in

        })
    }

    enum Constants {
        static let numberOfPosts = 3
        static let numberOfPostsToSync: NSNumber = 4
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

        guard let configurablePostView = cell as? ConfigurablePostView else {
                fatalError("Cell does not implement the required protocols")
        }

        configurablePostView.configure(with: post)
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
