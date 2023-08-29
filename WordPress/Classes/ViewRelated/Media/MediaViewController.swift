import UIKit
import PhotosUI

final class MediaViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private lazy var dataSource = makeDataSource()
    private lazy var fetchController = makeFetchController()

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, Media> {
        UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, media in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! WPMediaCollectionViewCell
            cell.asset = media
            cell.backgroundColor = .red
            return cell
        })
    }

    private func makeFetchController() -> NSFetchedResultsController<Media> {
        let request = NSFetchRequest<Media>(entityName: Media.self.entityName())
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Media.creationDate, ascending: true),
            // Disambiguate in case media are uploaded at the same time, which
            // is highlely likely given it has onle second precision.
            NSSortDescriptor(keyPath: \Media.mediaID, ascending: true)
        ]
        #warning("TODO: add predicates and stuff")

        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: ContextManager.shared.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(WPMediaCollectionViewCell.self, forCellWithReuseIdentifier: "cellID")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinSubviewToAllEdges(view)

        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = self

        fetchController.delegate = self
        do {
            try fetchController.performFetch()
        } catch {
            // This should never happen
            WordPressAppDelegate.crashLogging?.logError(error)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let spacing: CGFloat = 2

        let availableWidth = collectionView.bounds.width
        let maxNumColumns = Int(availableWidth / Constants.minColumnWidth)
        let cellWidth = ((availableWidth - spacing * CGFloat(maxNumColumns - 1)) / CGFloat(maxNumColumns)).rounded(.down)

        let flowLayout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Media>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchController.fetchedObjects ?? [])
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("start prefetch: \(indexPaths)")
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("cancel prefetch: \(indexPaths)")
    }
}

private enum Constants {
    static let minColumnWidth: CGFloat = 96
}

final class MediaCellViewModel: Hashable {
    private let media: Media

    init(media: Media) {
        self.media = media
    }

    static func == (lhs: MediaCellViewModel, rhs: MediaCellViewModel) -> Bool {
        lhs.media.objectID == rhs.media.objectID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(media.objectID)
    }
}
