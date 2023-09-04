import UIKit
import PhotosUI

final class MediaViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private lazy var fetchController = makeFetchController()

    private var pendingChanges: [(UICollectionView) -> Void] = []
    private var viewModels: [NSManagedObjectID: MediaCollectionCellViewModel] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title

        collectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: Constants.cellID)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinSubviewToAllEdges(view)

        collectionView.dataSource = self
        collectionView.prefetchDataSource = self

        fetchController.delegate = self
        do {
            try fetchController.performFetch()
        } catch {
            WordPressAppDelegate.crashLogging?.logError(error) // Should never happen
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateFlowLayoutItemSize()
    }

    private func updateFlowLayoutItemSize() {
        let spacing = Constants.minCellSpacing
        let availableWidth = collectionView.bounds.width
        let maxNumColumns = Int(availableWidth / Constants.minColumnWidth)
        let cellWidth = ((availableWidth - spacing * CGFloat(maxNumColumns - 1)) / CGFloat(maxNumColumns)).rounded(.down)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }

    // MARK: - NSFetchedResultsController

    private func makeFetchController() -> NSFetchedResultsController<Media> {
        let request = NSFetchRequest<Media>(entityName: Media.self.entityName())
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
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchController.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as! MediaCollectionCell
        let media = fetchController.object(at: indexPath)
        let viewModel = makeViewModel(for: media)
        cell.configure(viewModel: viewModel, targetSize: getImageTargetSize())
        return cell
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let targetSize = getImageTargetSize()
        for indexPath in indexPaths {
            makeViewModel(for: fetchController.object(at: indexPath))
                .loadThumbnail(targetSize: targetSize)
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

    private func getImageTargetSize() -> CGSize {
        let scale = UIScreen.main.scale
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return CGSizeApplyAffineTransform(flowLayout.itemSize, transform)
    }
}

private enum Constants {
    static let minColumnWidth: CGFloat = 96
    static let minCellSpacing: CGFloat = 2
    static let cellID = "cellID"
}

private enum Strings {
    static let title = NSLocalizedString("media.title", value: "Media", comment: "Media screen navigation title")
}
