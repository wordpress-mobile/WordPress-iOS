
protocol ReaderTagCardCellViewModelDelegate: NSObjectProtocol {
    func showLoading()
    func hideLoading()
}

class ReaderTagCardCellViewModel: NSObject {

    enum Section: Int {
        case emptyState = 101
        case posts
    }

    enum CardCellItem: Hashable {
        case empty
        case post(id: NSManagedObjectID)
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, CardCellItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CardCellItem>

    let slug: String
    weak var viewDelegate: ReaderTagCardCellViewModelDelegate? = nil

    private let coreDataStack: CoreDataStackSwift
    private weak var parentViewController: UIViewController?
    private weak var collectionView: UICollectionView?
    private let isLoggedIn: Bool
    private let cellSize: () -> CGSize?

    private lazy var readerPostService: ReaderPostService = {
        .init(coreDataStack: coreDataStack)
    }()

    private lazy var dataSource: DataSource? = { [weak self] in
        guard let self,
              let collectionView else {
           return nil
        }

        let dataSource = DataSource(collectionView: collectionView, cellProvider: self.cardCellProvider)
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter,
                  let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: ReaderTagFooterView.classNameWithoutNamespaces(),
                                                                             for: indexPath) as? ReaderTagFooterView else {
                return nil
            }
            view.configure(with: self.slug) { [weak self] in
                self?.onTagButtonTapped()
            }
            return view
        }
        return dataSource
    }()

    private lazy var resultsController: NSFetchedResultsController<ReaderPost> = {
        let fetchRequest = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortRank", ascending: false)]
        fetchRequest.fetchLimit = Constants.displayPostLimit
        fetchRequest.includesSubentities = false
        let resultsController = NSFetchedResultsController<ReaderPost>(fetchRequest: fetchRequest,
                                                           managedObjectContext: ContextManager.shared.mainContext,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
        resultsController.delegate = self
        return resultsController
    }()

    // MARK: Methods

    init(parent: UIViewController?,
         tag: ReaderTagTopic,
         collectionView: UICollectionView?,
         isLoggedIn: Bool,
         viewDelegate: ReaderTagCardCellViewModelDelegate?,
         coreDataStack: CoreDataStackSwift = ContextManager.shared,
         cellSize: @escaping @autoclosure () -> CGSize?) {
        self.parentViewController = parent
        self.slug = tag.slug
        self.collectionView = collectionView
        self.isLoggedIn = isLoggedIn
        self.viewDelegate = viewDelegate
        self.coreDataStack = coreDataStack
        self.cellSize = cellSize

        super.init()

        resultsController.fetchRequest.predicate = NSPredicate(format: "topic = %@ AND isSiteBlocked = NO", tag)
        collectionView?.delegate = self
    }

    func fetchTagPosts(syncRemotely: Bool) {
        guard let topic = try? ReaderTagTopic.lookup(withSlug: slug, in: coreDataStack.mainContext) else {
            return
        }

        viewDelegate?.showLoading()

        let onRemoteFetchComplete = { [weak self] in
            try? self?.resultsController.performFetch()
        }

        guard syncRemotely else {
            onRemoteFetchComplete()
            return
        }

        readerPostService.fetchPosts(for: topic, earlierThan: Date()) { _, _ in
            onRemoteFetchComplete()
        } failure: { _ in
            // try to show local contents even if the request failed.
            onRemoteFetchComplete()
        }
    }

    func onTagButtonTapped() {
        let controller = ReaderStreamViewController.controllerWithTagSlug(slug)
        parentViewController?.navigationController?.pushViewController(controller, animated: true)
    }

    struct Constants {
        static let displayPostLimit = 10
        static let footerWidth: CGFloat = 200
    }

}

// MARK: - Private Methods

private extension ReaderTagCardCellViewModel {
    /// Configures and returns a collection view cell according to the index path and `CardCellItem`.
    /// This method that satisfies the `UICollectionViewDiffableDataSource.CellProvider` closure signature.
    func cardCellProvider(_ collectionView: UICollectionView,
                          _ indexPath: IndexPath,
                          _ item: CardCellItem) -> UICollectionViewCell? {
        switch item {
        case .empty:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReaderTagCardEmptyCell.defaultReuseID,
                                                                for: indexPath) as? ReaderTagCardEmptyCell else {
                return UICollectionViewCell()
            }

            cell.configure(tagTitle: slug) { [weak self] in
                self?.fetchTagPosts(syncRemotely: true)
            }

            return cell

        case .post(let objectID):
            guard let post = try? ContextManager.shared.mainContext.existingObject(with: objectID) as? ReaderPost,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReaderTagCell.classNameWithoutNamespaces(),
                                                                for: indexPath) as? ReaderTagCell else {
                return UICollectionViewCell()
            }

            cell.configure(parent: parentViewController, post: post, isLoggedIn: isLoggedIn)
            return cell
        }
    }

    /// Translates a diffable snapshot from `NSFetchedResultsController` to a snapshot that fits the collection view.
    ///
    /// Snapshots returned from `NSFetchedResultsController` always have the type `<String, NSManagedObjectID>`, so
    /// it needs to be converted to match the correct type required by the collection view.
    ///
    /// - Parameter snapshotRef: The snapshot returned from the `NSFetchedResultsController`
    /// - Returns: `Snapshot`
    private func collectionViewSnapshot(from snapshotRef: NSDiffableDataSourceSnapshotReference) -> Snapshot {
        let coreDataSnapshot = snapshotRef as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        let isEmpty = coreDataSnapshot.numberOfItems == .zero
        var snapshot = Snapshot()

        // there must be at least one section.
        snapshot.appendSections([isEmpty ? .emptyState : .posts])
        snapshot.appendItems(isEmpty ? [.empty] : coreDataSnapshot.itemIdentifiers.map { .post(id: $0) })

        return snapshot
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension ReaderTagCardCellViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource?.apply(collectionViewSnapshot(from: snapshot), animatingDifferences: false) { [weak self] in
            self?.viewDelegate?.hideLoading()
        }
    }

}

// MARK: - UICollectionViewDelegate

extension ReaderTagCardCellViewModel: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = dataSource?.sectionIdentifier(for: indexPath.section),
              section == .posts,
              let sectionInfo = resultsController.sections?[safe: indexPath.section],
              indexPath.row < sectionInfo.numberOfObjects else {
            return
        }
        let post = resultsController.object(at: indexPath)
        let controller = ReaderDetailViewController.controllerWithPost(post)
        parentViewController?.navigationController?.pushViewController(controller, animated: true)
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension ReaderTagCardCellViewModel: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = dataSource?.sectionIdentifier(for: indexPath.section),
              let size = cellSize() else {
            return .zero
        }

        switch section {
        case .emptyState:
            return CGSize(width: collectionView.frame.width, height: size.height)
        case .posts:
            return size
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let sectionIdentifier = dataSource?.sectionIdentifier(for: section),
              sectionIdentifier == .posts else {
            return .zero
        }

        var viewSize = cellSize() ?? .zero
        viewSize.width = Constants.footerWidth
        return viewSize
    }

}
