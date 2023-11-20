import UIKit

protocol ExternalMediaPickerViewDelegate: AnyObject {
    // TODO: add delegate
}

final class ExternalMediaPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private let searchController = UISearchController()
    private let dataSource: WPMediaCollectionDataSource
    private var observerKey: NSObject?

    init(dataSource: WPMediaCollectionDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        observerKey.map(dataSource.unregisterChangeObserver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureSearchController()

        dataSource.registerChangeObserverBlock { [weak self] _, _, _, _, _ in
            self?.collectionView.reloadData()
        }

        // TODO: add selection
        // TODO: add pan gesture recognizer
        // TODO: add empty state
        // TODO: add fullscreen preview for selection using QuickLookViewController
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateFlowLayoutItemSize()
    }

    private func configureCollectionView() {
        collectionView.register(cell: ExternalMediaPickerCollectionCell.self)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinSubviewToAllEdges(view)
        collectionView.accessibilityIdentifier = "MediaCollection"

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no

        navigationItem.searchController = searchController
    }

    private func updateFlowLayoutItemSize() {
        let spacing: CGFloat = 2
        let availableWidth = collectionView.bounds.width
        let itemsPerRow = availableWidth < 500 ? 4 : 5
        let cellWidth = ((availableWidth - spacing * CGFloat(itemsPerRow - 1)) / CGFloat(itemsPerRow)).rounded(.down)

        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.numberOfAssets()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(cell: ExternalMediaPickerCollectionCell.self, for: indexPath)!
        let item = dataSource.media(at: indexPath.row)
        if let item = item as? TenorMedia {
            cell.configure(imageURL: item.previewURL, size: flowLayout.itemSize.scaled(by: UIScreen.main.scale))
        } else {
            fatalError("Unsupported item \(item)")
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO:
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""
        if searchTerm.count < 2 {
            dataSource.searchCancelled?()
        } else {
            dataSource.search?(for: searchTerm)
        }
    }
}
