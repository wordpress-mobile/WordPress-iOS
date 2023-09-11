import UIKit
import PhotosUI

final class MediaViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private lazy var refreshControl = UIRefreshControl()
    private lazy var fetchController = makeFetchController()

    private var isSyncing = false
    private var pendingChanges: [(UICollectionView) -> Void] = []
    private var viewModels: [NSManagedObjectID: MediaCollectionCellViewModel] = [:]
    private let blog: Blog
    private let coordinator = MediaCoordinator.shared

    static let spacing: CGFloat = 2

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        QuickStartTourGuide.shared.visited(.mediaScreen)

        title = Strings.title
        extendedLayoutIncludesOpaqueBars = true

        configureCollectionView()

        fetchController.delegate = self
        do {
            try fetchController.performFetch()
        } catch {
            WordPressAppDelegate.crashLogging?.logError(error) // Should never happen
        }

        if collectionView.numberOfItems(inSection: 0) == 0 {
            showLoadingView()
        }

        syncMedia()
    }

    private func configureCollectionView() {
        collectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: Constants.cellID)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinSubviewToAllEdges(view)

        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(syncMedia), for: .valueChanged)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateFlowLayoutItemSize()
    }

    private func updateFlowLayoutItemSize() {
        let spacing = MediaViewController.spacing
        let availableWidth = collectionView.bounds.width
        let itemsPerRow = availableWidth < 450 ? 4 : 5
        let cellWidth = ((availableWidth - spacing * CGFloat(itemsPerRow - 1)) / CGFloat(itemsPerRow)).rounded(.down)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
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
        refreshControl.endRefreshing()
        pendingRefreshWorkItem = nil

        hideNoResults()
        let isEmpty = collectionView.numberOfItems(inSection: 0) == 0
        if let error {
            if isEmpty {
                showErrorView()
            } else {
                WPError.showNetworkingNotice(title: Strings.syncFailed, error: error as NSError)
            }
        } else {
            if isEmpty {
                showEmptyView()
            }
        }
    }

    // MARK: - NSFetchedResultsController

    private func makeFetchController() -> NSFetchedResultsController<Media> {
        let request = NSFetchRequest<Media>(entityName: Media.self.entityName())
        request.predicate = NSPredicate(format: "blog == %@", blog)
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

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
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
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchController.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as! MediaCollectionCell
        let media = fetchController.object(at: indexPath)
        let viewModel = makeViewModel(for: media)
        cell.configure(viewModel: viewModel)
        return cell
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            makeViewModel(for: fetchController.object(at: indexPath))
                .loadThumbnail()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            makeViewModel(for: fetchController.object(at: indexPath))
                .cancelLoading()
        }
    }

    // MARK: - Helpers

    // Create ViewModel lazily to avoid fetching more managed objects than needed.
    private func makeViewModel(for media: Media) -> MediaCollectionCellViewModel {
        if let viewModel = viewModels[media.objectID] {
            return viewModel
        }
        let viewModel = MediaCollectionCellViewModel(media: media)
        viewModels[media.objectID] = viewModel
        return viewModel
    }
}

// MARK: - MediaViewController (NoResults)

extension MediaViewController: NoResultsViewHost, NoResultsViewControllerDelegate {
    private func showLoadingView() {
        noResultsViewController.configureForFetching()
        displayNoResults(on: view)
    }

    private func showEmptyView() {
        noResultsViewController.configureForNoAssets(userCanUploadMedia: blog.userCanUploadMedia)
        displayNoResults(on: view)
    }

    private func showErrorView() {
        configureAndDisplayNoResults(on: view, title: Strings.syncFailed)
    }

    func actionButtonPressed() {
        // TODO: Implement "Add Media" button
    }
}

private enum Constants {
    static let cellID = "cellID"
}

private enum Strings {
    static let title = NSLocalizedString("media.title", value: "Media", comment: "Media screen navigation title")
    static let syncFailed = NSLocalizedString("media.syncFailed", value: "Unable to sync media", comment: "Title of error prompt shown when a sync fails.")
}

extension Blog {
    var userCanUploadMedia: Bool {
        // Self-hosted non-Jetpack blogs have no capabilities, so we'll just assume that users can post media
        capabilities != nil ? isUploadingFilesAllowed() : true
    }
}
