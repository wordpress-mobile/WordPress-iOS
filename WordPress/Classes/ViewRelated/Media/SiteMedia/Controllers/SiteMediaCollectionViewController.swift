import UIKit
import PhotosUI

protocol SiteMediaCollectionViewControllerDelegate: AnyObject {
    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, didUpdateSelection selection: [Media])
    /// Return a non-nil value to allow adding media using the empty state.
    func makeAddMediaMenu(for viewController: SiteMediaCollectionViewController) -> UIMenu?
    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, contextMenuFor media: Media) -> UIMenu?
}

extension SiteMediaCollectionViewControllerDelegate {
    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, didUpdateSelection: [Media]) {}
    func makeAddMediaMenu(for viewController: SiteMediaCollectionViewController) -> UIMenu? { nil }
    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, contextMenuFor media: Media) -> UIMenu? { nil }
}

/// The internal view controller for managing the media collection view.
final class SiteMediaCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching, UISearchResultsUpdating, UIGestureRecognizerDelegate, SiteMediaPageViewControllerDelegate {
    weak var delegate: SiteMediaCollectionViewControllerDelegate?

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private lazy var refreshControl = UIRefreshControl()
    private lazy var fetchController = makeFetchController()

    private let searchController = UISearchController()

    private var isSyncing = false
    private var syncError: Error?
    private var pendingChanges: [(UICollectionView) -> Void] = []
    private var viewModels: [NSManagedObjectID: SiteMediaCollectionCellViewModel] = [:]
    private let blog: Blog
    private let filter: Set<MediaType>?
    private let isShowingPendingUploads: Bool
    private let coordinator = MediaCoordinator.shared

    // Selection management
    private var selection = NSMutableOrderedSet() // `Media`
    private var allowsMultipleSelection = false
    private var isSelectionOrdered = false
    private var isBatchSelectionUpdate = false
    private var panGestureInitialIndexPath: IndexPath?
    private var panGesturePeviousSelection: NSOrderedSet?
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didRecognizePanGesture))

    private var emptyViewState: EmptyViewState = .hidden {
        didSet {
            guard oldValue != emptyViewState else { return }
            displayEmptyViewState(emptyViewState)
        }
    }

    static let spacing: CGFloat = 2
    static let spacingAspectRatio: CGFloat = 8

    var selectedMedia: [Media] {
        guard let selection = selection.array as? [Media] else {
            assertionFailure("Invalid selection")
            return []
        }
        return selection
    }

    init(blog: Blog, filter: Set<MediaType>? = nil, isShowingPendingUploads: Bool = true) {
        self.blog = blog
        self.filter = filter
        self.isShowingPendingUploads = isShowingPendingUploads
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func embed(in parentViewController: UIViewController) {
        parentViewController.addChild(self)
        parentViewController.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.view.pinSubviewToAllEdges(view)
        didMove(toParent: parentViewController)

        parentViewController.navigationItem.searchController = searchController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureSearchController()

        fetchController.delegate = self
        do {
            try fetchController.performFetch()
        } catch {
            WordPressAppDelegate.crashLogging?.logError(error) // Should never happen
        }

        syncMedia()
        updateEmptyViewState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateFlowLayoutItemSize()
    }

    private func configureCollectionView() {
        collectionView.register(cell: SiteMediaCollectionCell.self)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinSubviewToAllEdges(view)
        collectionView.accessibilityIdentifier = "MediaCollection"

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.refreshControl = refreshControl

        refreshControl.addTarget(self, action: #selector(syncMedia), for: .valueChanged)

        collectionView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
    }

    private func updateFlowLayoutItemSize() {
        let spacing = UserDefaults.standard.isMediaAspectRatioModeEnabled ? SiteMediaCollectionViewController.spacingAspectRatio : SiteMediaCollectionViewController.spacing
        let availableWidth = collectionView.bounds.width
        let itemsPerRow = availableWidth < 450 ? 4 : 5
        let cellWidth = ((availableWidth - spacing * CGFloat(itemsPerRow - 1)) / CGFloat(itemsPerRow)).rounded(.down)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }

    func makeMoreMenu() -> UIMenu? {
        guard !makeMoreMenuActions().isEmpty else {
            return nil
        }
        return UIMenu(children: [UIDeferredMenuElement.uncached { [weak self] in
            $0(self?.makeMoreMenuActions() ?? [])
        }])
    }

    private func makeMoreMenuActions() -> [UIAction] {
        var actions: [UIAction] = []
        if UIDevice.current.userInterfaceIdiom == .pad {
            let isAspect = UserDefaults.standard.isMediaAspectRatioModeEnabled
            actions.append(UIAction(
                title: isAspect ? Strings.squareGrid : Strings.aspectRatioGrid,
                image: UIImage(systemName: isAspect ? "rectangle.arrowtriangle.2.outward" : "rectangle.arrowtriangle.2.inward")) { [weak self] _ in
                    self?.toggleAspectRatioMode()
                })
        }
        return actions
    }

    private func toggleAspectRatioMode() {
        UserDefaults.standard.isMediaAspectRatioModeEnabled.toggle()
        UIView.animate(withDuration: 0.33) {
            self.updateFlowLayoutItemSize()
            for cell in self.collectionView.visibleCells {
                guard let cell = cell as? SiteMediaCollectionCell else { continue }
                cell.configure(isAspectRatioModeEnabled: UserDefaults.standard.isMediaAspectRatioModeEnabled)
            }
        }
    }

    // MARK: - Editing (Selection)

    func setEditing(
        _ isEditing: Bool,
        allowsMultipleSelection: Bool = true,
        isSelectionOrdered: Bool = false
    ) {
        guard self.isEditing != isEditing else { return }
        self.isEditing = isEditing
        self.allowsMultipleSelection = allowsMultipleSelection
        self.isSelectionOrdered = isSelectionOrdered

        deselectAll()
    }

    private func updateSelection(_ perform: () -> Void) {
        guard !isBatchSelectionUpdate else {
            return perform()
        }

        let previousSelection = selectedMedia

        isBatchSelectionUpdate = true
        perform()
        isBatchSelectionUpdate = false

        for media in previousSelection where !selection.contains(media) {
            getViewModel(for: media).badge = nil
        }
        if allowsMultipleSelection {
            for (index, media) in selection.enumerated() {
                if let media = media as? Media {
                    getViewModel(for: media).badge = isSelectionOrdered ? .ordered(index: index) : .unordered
                } else {
                    assertionFailure("Invalid selection")
                }
            }
        }
        delegate?.siteMediaViewController(self, didUpdateSelection: selectedMedia)
        if !allowsMultipleSelection {
            selection = []
        }
    }

    private func toggleSelection(for media: Media) {
        setSelected(!selection.contains(media), for: media)
    }

    private func setSelected(_ isSelected: Bool, for media: Media) {
        updateSelection {
            if isSelected {
                selection.add(media)
            } else {
                selection.remove(media)
            }
        }
    }

    private func deselectAll() {
        updateSelection {
            selection.removeAllObjects()
        }
    }

    @objc private func didRecognizePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isEditing, allowsMultipleSelection else { return }

        switch gesture.state {
        case .began:
            panGestureInitialIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView))
            panGesturePeviousSelection = selection.copy() as? NSOrderedSet
        case .changed:
            guard let currentIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)),
                  let panGestureInitialIndexPath,
                  let panGesturePeviousSelection else { return }

            let isDeselecting = panGesturePeviousSelection.contains(fetchController.object(at: panGestureInitialIndexPath))

            updateSelection {
                selection = NSMutableOrderedSet(orderedSet: panGesturePeviousSelection)
                for index in stride(from: panGestureInitialIndexPath.item, through: currentIndexPath.item, by: currentIndexPath.item > panGestureInitialIndexPath.item ? 1 : -1) {
                    let media = fetchController.object(at: IndexPath(item: index, section: 0))
                    isDeselecting ? selection.remove(media) : selection.add(media)
                }
            }
        case .ended:
            break
        default:
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate (Selection)

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            return otherGestureRecognizer === collectionView.panGestureRecognizer
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            return isEditing
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            return abs(translation.x) > abs(translation.y)
        }
        return true
    }

    // MARK: - Refresh

    private var pendingRefreshWorkItem: DispatchWorkItem?

    @objc private func syncMedia() {
        guard !isSyncing else { return }
        isSyncing = true

        coordinator.syncMedia(for: blog, success: { [weak self] in
            // The success callback is called before the changes get merged
            // in the main context, so the app needs to wait until the
            // fetch controller updates. Fixes https://github.com/wordpress-mobile/WordPress-iOS/issues/9922
            let work = DispatchWorkItem {
                self?.didFinishRefreshing(error: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: work)
            self?.pendingRefreshWorkItem = work
        }, failure: { [weak self] error in
            DispatchQueue.main.async {
                self?.didFinishRefreshing(error: error)
            }
        })
    }

    private func didFinishRefreshing(error: Error?) {
        isSyncing = false
        syncError = error
        refreshControl.endRefreshing()
        pendingRefreshWorkItem = nil

        let isEmpty = collectionView.numberOfItems(inSection: 0) == 0
        if let error, !isEmpty {
            WPError.showNetworkingNotice(title: Strings.syncFailed, error: error as NSError)
        }
        updateEmptyViewState()
    }

    // MARK: - NSFetchedResultsController

    private func makeFetchController() -> NSFetchedResultsController<Media> {
        let request = NSFetchRequest<Media>(entityName: Media.self.entityName())
        request.predicate = makePredicate(searchTerm: "")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Media.creationDate, ascending: false),
            // Disambiguate in case media are uploaded at the same time, which
            // is highly likely, given it has no sub-second precision.
            NSSortDescriptor(keyPath: \Media.mediaID, ascending: false)
        ]
        request.fetchBatchSize = 200
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: ContextManager.shared.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func makePredicate(searchTerm: String) -> NSPredicate {
        var predicates = [NSPredicate(format: "blog == %@", blog)]
        if let filter {
            let mediaTypes = filter.map(Media.string(from:))
            predicates.append(NSPredicate(format: "mediaTypeString IN %@", mediaTypes))
        }
        if !isShowingPendingUploads {
            predicates.append(NSPredicate(format: "remoteStatusNumber == %i", MediaRemoteStatus.sync.rawValue))
        }
        if !searchTerm.isEmpty {
            predicates.append(NSPredicate(format: "(title CONTAINS[cd] %@) OR (caption CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchTerm, searchTerm, searchTerm))
        }
        return predicates.count == 1 ? predicates[0] : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        pendingChanges = []
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath else { return }
            pendingChanges.append({ $0.insertItems(at: [newIndexPath]) })
        case .delete:
            guard let indexPath else { return }
            pendingChanges.append({ $0.deleteItems(at: [indexPath]) })
            if let media = anObject as? Media {
                setSelected(false, for: media)
                didDeleteMedia(media, at: indexPath)
            } else {
                assertionFailure("Invalid object: \(anObject)")
            }
        case .update:
            // No interested in these. The screen observe these changes separately
            // to minimize the number of reloads: `.update` is emitted too often.
            break
        case .move:
            guard let indexPath, let newIndexPath else { return }
            pendingChanges.append({ $0.moveItem(at: indexPath, to: newIndexPath) })
        @unknown default:
            break
        }
    }

    private func didDeleteMedia(_ media: Media, at indexPath: IndexPath) {
        if let viewController = navigationController?.topViewController,
           let detailsViewController = viewController as? SiteMediaPageViewController {
            let before = indexPath.item > 0 ? fetchController.object(at: IndexPath(item: indexPath.item - 1, section: 0)) : nil
            let after = indexPath.item < (fetchController.fetchedObjects?.count ?? 0) ? fetchController.object(at: IndexPath(item: indexPath.item, section: 0)) : nil

            detailsViewController.didDeleteItem(media, before: before, after: after)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard !pendingChanges.isEmpty else {
            return
        }
        let updates = pendingChanges
        collectionView.performBatchUpdates {
            for update in updates {
                update(collectionView)
            }
        }
        pendingChanges = []

        if let workItem = pendingRefreshWorkItem {
            workItem.cancel()
            didFinishRefreshing(error: nil)
            pendingRefreshWorkItem = nil
        }

        updateEmptyViewState()
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchController.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(cell: SiteMediaCollectionCell.self, for: indexPath)!
        let media = fetchController.object(at: indexPath)
        let viewModel = getViewModel(for: media)
        cell.configure(viewModel: viewModel)
        cell.configure(isAspectRatioModeEnabled: UserDefaults.standard.isMediaAspectRatioModeEnabled)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let media = fetchController.object(at: indexPath)
        if isEditing {
            toggleSelection(for: media)
        } else {
            switch media.remoteStatus {
            case .failed, .pushing, .processing:
                showRetryOptions(for: media)
            case .sync:
                WPAppAnalytics.track(.mediaLibraryPreviewedItem, with: blog)

                let viewController = SiteMediaPageViewController(media: media, delegate: self)
                self.navigationController?.pushViewController(viewController, animated: true)
            default: break
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else {
            return nil
        }
        let media = fetchController.object(at: indexPath)
        return UIContextMenuConfiguration(previewProvider: { [weak self] in
            guard let self else { return nil }
            return self.makePreviewViewController(for: media)
        }, actionProvider: { [weak self] _ in
            guard let self else { return nil }
            return self.delegate?.siteMediaViewController(self, contextMenuFor: media)
        })
    }

    private func makePreviewViewController(for media: Media) -> UIViewController? {
        let viewModel = getViewModel(for: media)
        guard let image = viewModel.getCachedThubmnail() else {
            return nil
        }
        let imageView = UIImageView(image: image)
        imageView.accessibilityIgnoresInvertColors = true

        let viewController = UIViewController()
        viewController.view.addSubview(imageView)
        viewController.view.pinSubviewToAllEdges(imageView)
        viewController.preferredContentSize = image.size
        return viewController
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let media = fetchController.object(at: indexPath)
            getViewModel(for: media).startPrefetching()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let media = fetchController.object(at: indexPath)
            getViewModel(for: media).cancelPrefetching()
        }
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""
        fetchController.fetchRequest.predicate = makePredicate(searchTerm: searchTerm)
        do {
            try fetchController.performFetch()
            collectionView.reloadData()
            updateEmptyViewState()
        } catch {
            WordPressAppDelegate.crashLogging?.logError(error) // Should never happen
        }
    }


    // MARK: - SiteMediaPageViewControllerDelegate

    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaBeforeMedia media: Media) -> Media? {
        guard let fetchedObjects = fetchController.fetchedObjects,
              let index = fetchedObjects.firstIndex(of: media),
              index > 0 else {
            return nil
        }
        return fetchedObjects[index - 1]
    }

    func siteMediaPageViewController(_ viewController: SiteMediaPageViewController, getMediaAfterMedia media: Media) -> Media? {
        guard let fetchedObjects = fetchController.fetchedObjects,
              let index = fetchedObjects.firstIndex(of: media),
              index < (fetchedObjects.count - 1) else {
            return nil
        }
        return fetchedObjects[index + 1]
    }

    // MARK: - Menus

    private func showRetryOptions(for media: Media) {
        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: style)
        alertController.addDestructiveActionWithTitle(Strings.retryMenuDelete) { _ in
            self.coordinator.delete(media: [media])
        }
        if media.remoteStatus == .failed {
            if let error = media.error {
                alertController.message = error.localizedDescription
            }
            if media.canRetry {
                alertController.addDefaultActionWithTitle(Strings.retryMenuRetry) { _ in
                    let info = MediaAnalyticsInfo(origin: .mediaLibrary(.wpMediaLibrary))
                    self.coordinator.retryMedia(media, analyticsInfo: info)
                }
            }
        }
        alertController.addCancelActionWithTitle(Strings.retryMenuDismiss)
        present(alertController, animated: true)
    }

    // MARK: - Helpers

    // Create ViewModel lazily to avoid fetching more managed objects than needed.
    private func getViewModel(for media: Media) -> SiteMediaCollectionCellViewModel {
        if let viewModel = viewModels[media.objectID] {
            return viewModel
        }
        let viewModel = SiteMediaCollectionCellViewModel(media: media)
        viewModels[media.objectID] = viewModel
        return viewModel
    }
}

// MARK: - MediaViewController (NoResults)

extension SiteMediaCollectionViewController: NoResultsViewHost {
    private func updateEmptyViewState() {
        let isEmpty = collectionView.numberOfItems(inSection: 0) == 0
        guard isEmpty else {
            emptyViewState = .hidden
            return
        }
        if isSyncing {
            emptyViewState = .synching
        } else if syncError != nil {
            emptyViewState = .failed
        } else if let searchTerm = searchController.searchBar.text, !searchTerm.isEmpty {
            emptyViewState = .emptySearch
        } else {
            emptyViewState = .empty(isAddButtonShown: blog.userCanUploadMedia)
        }
    }

    private func displayEmptyViewState(_ state: EmptyViewState) {
        hideNoResults() // important: it doesn't refresh without it

        switch state {
        case .hidden:
            hideNoResults()
        case .synching:
            noResultsViewController.configureForFetching()
            displayNoResults(on: view)
        case .empty(let isAddButtonShown):
            let menu = delegate?.makeAddMediaMenu(for: self)
            noResultsViewController.configureForNoAssets(userCanUploadMedia: isAddButtonShown && menu != nil)
            noResultsViewController.buttonMenu = menu
            displayNoResults(on: view)
        case .emptySearch:
            configureAndDisplayNoResults(on: view, title: Strings.noSearchResultsTitle)
        case .failed:
            configureAndDisplayNoResults(on: view, title: Strings.syncFailed)
        }
    }

    private enum EmptyViewState: Hashable {
        case hidden
        case synching
        case empty(isAddButtonShown: Bool)
        case emptySearch
        case failed
    }
}

private enum Strings {
    static let syncFailed = NSLocalizedString("media.syncFailed", value: "Unable to sync media", comment: "Title of error prompt shown when a sync fails.")
    static let retryMenuRetry = NSLocalizedString("mediaLibrary.retryOptionsAlert.retry", value: "Retry Upload", comment: "User action to retry media upload.")
    static let retryMenuDelete = NSLocalizedString("mediaLibrary.retryOptionsAlert.delete", value: "Delete", comment: "User action to delete un-uploaded media.")
    static let retryMenuDismiss = NSLocalizedString("mediaLibrary.retryOptionsAlert.dismissButton", value: "Dismiss", comment: "Verb. Button title. Tapping dismisses a prompt.")
    static let noSearchResultsTitle = NSLocalizedString("mediaLibrary.searchResultsEmptyTitle", value: "No media matching your search", comment: "Message displayed when no results are returned from a media library search. Should match Calypso.")
    static let aspectRatioGrid = NSLocalizedString("mediaLibrary.aspectRatioGrid", value: "Aspect Ratio Grid", comment: "Button name in the more menu")
    static let squareGrid = NSLocalizedString("mediaLibrary.squareGrid", value: "Square Grid", comment: "Button name in the more menu")
}
