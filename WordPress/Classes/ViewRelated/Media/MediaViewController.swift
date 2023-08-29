import UIKit
import PhotosUI

// TODO: Add title
final class MediaViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private lazy var dataSource = makeDataSource()
    private lazy var fetchController = makeFetchController()

    private var imageLoaders: [NSManagedObjectID: MediaCellImageLoader] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(MediaCollectionCell.self, forCellWithReuseIdentifier: "cellID")

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

        // TODO: refactor and verify on other device sizes
        let spacing: CGFloat = 2

        let availableWidth = collectionView.bounds.width
        let maxNumColumns = Int(availableWidth / Constants.minColumnWidth)
        let cellWidth = ((availableWidth - spacing * CGFloat(maxNumColumns - 1)) / CGFloat(maxNumColumns)).rounded(.down)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
    }

    // MARK: - NSFetchedResultsController

    private func makeFetchController() -> NSFetchedResultsController<Media> {
        let request = NSFetchRequest<Media>(entityName: Media.self.entityName())
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Media.creationDate, ascending: true),
            // Disambiguate in case media are uploaded at the same time, which
            // is highlely likely given it has onle second precision.
            NSSortDescriptor(keyPath: \Media.mediaID, ascending: true)
        ]
        // TODO: Add predicates and stuff
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: ContextManager.shared.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Media>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchController.fetchedObjects ?? [])
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDiffableDataSource

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, Media> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] in
            self?.makeCell(for: $0, indexPath: $1, media: $2)
        }
    }

    // TODO: Add cellID to Constants
    private func makeCell(for collectionView: UICollectionView, indexPath: IndexPath, media: Media) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! MediaCollectionCell
        cell.configure(media: media, loader: getImageLoader(for: media), targetSize: getImageTargetSize())
        return cell
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let targetSize = getImageTargetSize()
        for indexPath in indexPaths {
            getImageLoader(for: fetchController.object(at: indexPath)).startLoading(targetSize: targetSize)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            getImageLoader(for: fetchController.object(at: indexPath)).cancelLoading()
        }
    }

    // MARK: - Helpers

    private func getImageTargetSize() -> CGSize {
        let scale = UIScreen.main.scale
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return CGSizeApplyAffineTransform(flowLayout.itemSize, transform)
    }

    private func getImageLoader(for media: Media) -> MediaCellImageLoader {
        if let imageLoader = imageLoaders[media.objectID] {
            return imageLoader
        }
        let imageLoader = MediaCellImageLoader(media: media)
        imageLoaders[media.objectID] = imageLoader
        return imageLoader
    }
}

private enum Constants {
    static let minColumnWidth: CGFloat = 96
}

final class MediaCollectionCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private var media: Media?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.systemGroupedBackground

        imageView.contentMode = .scaleAspectFill

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.pinSubviewToAllEdges(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // TODO: Add cell reuse
    fileprivate func configure(
        media: Media,
        loader: MediaCellImageLoader,
        targetSize: CGSize
    ) {
        if let image = loader.getCachedImage() {
            // Display with no animations. It should happen often thanks to prefetchig
            imageView.image = image
        } else {
            loader.onLoadingFinished = { [weak self] in
                // TODO: handle errors
                self?.imageView.image = $0
                self?.backgroundColor = $0 == nil ? .systemGroupedBackground : .clear
            }
            loader.startLoading(targetSize: targetSize)
        }
    }
}

// TODO: move to other file
// TODO: should it be ViewModel

/// Adds the following capabilities on top of the underlying `MediaThumbnailCoordinator`:
/// - Memory cache
/// - Prefetching
/// - Background decompression
private final class MediaCellImageLoader {
    var onLoadingFinished: ((UIImage?) -> Void)?

    private let media: Media
    private let coordinator: MediaThumbnailCoordinator
    private let cache: MemoryCache
    private var requestCount = 0

    init(media: Media,
         coordinator: MediaThumbnailCoordinator = .shared,
         cache: MemoryCache = .shared) {
        self.media = media
        self.coordinator = coordinator
        self.cache = cache
    }

    /// Returns the image from the memory cache.
    func getCachedImage() -> UIImage? {
        cache.getImage(forKey: makeCacheKey(for: media))
    }

    // TODO: can size change?
    func startLoading(targetSize: CGSize) {
        assert(targetSize != .zero, "Invalid target size")

        requestCount += 1
        guard requestCount == 1 else {
            return // Already loading
        }
        coordinator.thumbnail(for: media, with: targetSize) { [weak self] in
            self?.didFinishLoading(with: $0, error: $1)
        }
    }

    // TODO: add decompression (operation queues or is one serial queue enough?)
    private func didFinishLoading(with image: UIImage?, error: Error?) {
        if let image {
            cache.setImage(image, forKey: makeCacheKey(for: media))
        }
        onLoadingFinished?(image)
    }

    func cancelLoading() {
        requestCount -= 1
        requestCount = max(0, requestCount) // Just in case
        if requestCount == 0 {
            // TODO: actuall cancel
        }
    }

    private func makeCacheKey(for media: Media) -> String {
        "thumbnail-\(media.objectID)"
    }
}
