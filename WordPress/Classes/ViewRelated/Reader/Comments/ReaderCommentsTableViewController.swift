import UIKit
import CoreData
import WordPressUI

final class ReaderCommentsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    @objc let tableView = UITableView(frame: .zero, style: .plain)
    private let padingFooterView = PagingFooterView(state: .loading)
    private lazy var fetchResultsController = makeFetchResultsController()

    private let post: ReaderPost
    private let commentCellReuseID = "commentCellReuseID"
    private var viewModels: [NSManagedObjectID: CommentCellViewModel] = [:]
    private let moc = ContextManager.shared.mainContext

    /// - note: Temporary code.
    @objc weak var containerViewController: ReaderCommentsViewController?

    @objc var isEmpty: Bool { fetchResultsController.isEmpty() }

    @objc init(post: ReaderPost) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Setup view
        setupTableView()

        // Setup fetch
        do {
            try fetchResultsController.performFetch()
            tableView.reloadData()
            fetchResultsController.delegate = self
        } catch {
            wpAssertionFailure("fetch failed", userInfo: ["error": "\(error)"])
        }
    }

    private func setupTableView() {
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.preservesSuperviewLayoutMargins = true

        // We use this to mask the initial WebKit warmup that takes a bit of time
        // the first time you initialize a web view. It renders asynchronously, and
        // we don't want to show cells with empty messages.
        tableView.alpha = 0.0

        let nib = UINib(nibName: CommentContentTableViewCell.classNameWithoutNamespaces(), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: commentCellReuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200

        tableView.separatorStyle = .none

        // Hide cell separator for the last row
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0))

        setLoadingFooterHidden(true)

        view.addSubview(tableView)
        tableView.pinEdges()

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let previous = previousTraitCollection else {
            return
        }
        let current = traitCollection

        guard previous.horizontalSizeClass != current.horizontalSizeClass ||
                previous.preferredContentSizeCategory != current.preferredContentSizeCategory else {
            return
        }

        containerViewController?.helper.resetCachedContentHeights() // important
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc func comment(at indexPath: IndexPath) -> Comment? {
        fetchResultsController.object(at: indexPath)
    }

    @objc func scrollToComment(withID commentID: NSNumber) {
        let comments = fetchResultsController.fetchedObjects ?? []
        guard let comment = comments.first(where: { $0.commentID == commentID.int32Value }) else {
            return
        }

        // Force the table view to be laid out first before scrolling to indexPath.
        // This avoids a case where a cell instance could be orphaned and displayed randomly on top of the other cells.
        guard let indexPath = fetchResultsController.indexPath(forObject: comment) else {
            return
        }
        tableView.layoutIfNeeded()

        // Ensure that the indexPath exists before scrolling to it.
        if indexPath.section >= 0,
           indexPath.row >= 0,
           indexPath.section < tableView.numberOfSections,
           indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            containerViewController?.highlightComment(at: indexPath)
        }
    }

    @objc func setBottomInset(_ inset: CGFloat) {
        tableView.contentInset.bottom = inset
    }

    @objc func setLoadingFooterHidden(_ isHidden: Bool) {
        if isHidden {
            // Hide cell separator for the last row
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0))
        } else {
            tableView.tableFooterView = PagingFooterView(state: .loading)
            tableView.sizeToFitFooterView()
        }
    }

    // MARK: - NSFetchedResultsController

    private func makeFetchResultsController() -> NSFetchedResultsController<Comment> {
        let request = NSFetchRequest<Comment>(entityName: Comment.entityName())
        request.predicate = NSPredicate(format: "post = %@ AND status = %@ AND visibleOnReader = YES", post, CommentStatusType.approved.description)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Comment.hierarchy, ascending: true)
        ]
        request.fetchBatchSize = 40
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .none)
        case .delete:
            guard let indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .none)
        case .update:
            // The cells are responsible for updating themselves
            break
        case .move:
            guard let indexPath, let newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        UIView.performWithoutAnimation {
            tableView.endUpdates()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchResultsController.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: commentCellReuseID, for: indexPath) as! CommentContentTableViewCell
        cell.selectionStyle = .none
        let comment = fetchResultsController.object(at: indexPath)
        let viewModel = makeCellViewModel(comment: comment)
        containerViewController?.configureCell(cell, viewModel: viewModel, indexPath: indexPath)
        return cell
    }

    private func makeCellViewModel(comment: Comment) -> CommentCellViewModel {
        if let viewModel = viewModels[comment.objectID] {
            return viewModel
        }
        let viewModel = CommentCellViewModel(comment: comment)
        viewModels[comment.objectID] = viewModel
        return viewModel
    }

    // MARK: - UITableViewDataDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        containerViewController?.cachedHeaderView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        containerViewController?.cachedHeaderView() == nil ? 0 : UITableView.automaticDimension
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            containerViewController?.loadMore()
        }
    }
}
