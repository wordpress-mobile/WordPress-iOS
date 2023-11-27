import UIKit

protocol ExternalMediaPickerViewDelegate: AnyObject {
    /// If the user cancels the flow, the selection is empty.
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection selection: [ExternalMediaAsset])
}

final class ExternalMediaPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating, MediaPreviewControllerDataSource {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private var collectionViewDataSource: UICollectionViewDiffableDataSource<Int, String>!
    private let searchController = UISearchController()
    private let activityIndicator = UIActivityIndicatorView()
    private let toolbarItemTitle = ExternalMediaSelectionTitleView()
    private lazy var buttonDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(buttonDoneTapped))

    private let dataSource: ExternalMediaDataSource
    private var assets: [String: ExternalMediaAsset] = [:]
    private var allowsMultipleSelection: Bool
    private var selection = NSMutableOrderedSet() // of String
    private var isFirstAppearance = true

    /// A view to show when the screen is first open and the search query
    /// wasn't added.
    var welcomeView: UIView?

    weak var delegate: ExternalMediaPickerViewDelegate?

    init(dataSource: ExternalMediaDataSource,
         allowsMultipleSelection: Bool = false) {
        self.dataSource = dataSource
        self.allowsMultipleSelection = allowsMultipleSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureSearchController()
        configureActivityIndicator()
        configureNavigationItems()
        configureToolbarItems()

        if let welcomeView {
            view.addSubview(welcomeView)
            welcomeView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(welcomeView)
        }

        dataSource.onUpdatedAssets = { [weak self] in self?.didUpdateAssets() }
        dataSource.onStartLoading = { [weak self] in self?.didChangeLoading(true) }
        dataSource.onStopLoading = { [weak self] in self?.didChangeLoading(false) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstAppearance {
            isFirstAppearance = false
            searchController.searchBar.becomeFirstResponder()
        }
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
        collectionView.allowsMultipleSelection = allowsMultipleSelection

        collectionViewDataSource = .init(collectionView: collectionView) { [weak self] collectionView, indexPath, _ in
            self?.collectionView(collectionView, cellForItemAt: indexPath)
        }
        collectionView.delegate = self
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

    private func configureActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewAtCenter(activityIndicator)
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false

        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }

    private func configureNavigationItems() {
        let buttonCancel = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.buttonCancelTapped()
        })
        navigationItem.leftBarButtonItem = buttonCancel
        if allowsMultipleSelection {
            navigationItem.rightBarButtonItems = [buttonDone]
        }
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureToolbarItems() {
        guard allowsMultipleSelection, toolbarItems == nil else { return }

        var toolbarItems: [UIBarButtonItem] = []
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        toolbarItems.append(UIBarButtonItem(customView: toolbarItemTitle))
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        self.toolbarItems = toolbarItems

        toolbarItemTitle.buttonViewSelected.addTarget(self, action: #selector(buttonPreviewSelectionTapped), for: .touchUpInside)
    }

    private func didUpdateAssets() {
        self.assets = [:]
        for asset in dataSource.assets {
            self.assets[asset.id] = asset
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        let assetIDs = dataSource.assets.map(\.id)
        snapshot.appendItems(assetIDs, toSection: 0)
        collectionViewDataSource.apply(snapshot, animatingDifferences: false)

        let remaning = NSOrderedSet(array: assetIDs)
        selection.intersect(remaning)
        didUpdateSelection()
    }

    private func didChangeLoading(_ isLoading: Bool) {
        if isLoading && dataSource.assets.isEmpty {
            activityIndicator.startAnimating()
            welcomeView?.isHidden = true
        } else {
            activityIndicator.stopAnimating()
        }
    }

    // MARK: - Selection

    private func setSelected(_ isSelected: Bool, for asset: ExternalMediaAsset) {
        if isSelected {
            selection.add(asset.id)
        } else {
            selection.remove(asset.id)
        }
        didUpdateSelection()
    }

    private func didUpdateSelection() {
        if allowsMultipleSelection {
            toolbarItemTitle.setSelectionCount(selection.count)
            navigationController?.setToolbarHidden(dataSource.assets.isEmpty, animated: true)
        }

        // Update badges for visible items (might need to update count)
        for indexPath in collectionView.indexPathsForVisibleItems {
            let item = dataSource.assets[indexPath.item]
            let index = selection.index(of: item.id)
            if let cell = collectionView.cellForItem(at: indexPath) as? ExternalMediaPickerCollectionCell {
                cell.setBadge(index == NSNotFound ? nil : .ordered(index: index))
            }
        }
    }

    // MARK: - Actions

    private func buttonCancelTapped() {
        delegate?.externalMediaPickerViewController(self, didFinishWithSelection: [])
    }

    @objc private func buttonDoneTapped() {


        let selection = (selection.array as! [String]).compactMap { assets[$0] }
        delegate?.externalMediaPickerViewController(self, didFinishWithSelection: selection)
    }

    @objc private func buttonPreviewSelectionTapped() {
        let viewController = MediaPreviewController()
        viewController.dataSource = self
        let navigation = UINavigationController(rootViewController: viewController)
        present(navigation, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(cell: ExternalMediaPickerCollectionCell.self, for: indexPath)!
        let item = dataSource.assets[indexPath.item]
        cell.configure(imageURL: item.thumbnailURL, size: flowLayout.itemSize.scaled(by: UIScreen.main.scale))
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource.assets[indexPath.item]
        if allowsMultipleSelection {
            setSelected(true, for: item)
        } else {
            delegate?.externalMediaPickerViewController(self, didFinishWithSelection: [item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        setSelected(false, for: dataSource.assets[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height - 500 {
            dataSource.loadMore()
        }
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""
        dataSource.search(for: searchTerm)
    }

    // MARK: - MediaPreviewControllerDataSource

    func numberOfPreviewItems(in controller: MediaPreviewController) -> Int {
        selection.count
    }

    func previewController(_ controller: MediaPreviewController, previewItemAt index: Int) -> MediaPreviewItem? {
        guard let id = selection.object(at: index) as? String,
              let asset = assets[id] else {
            return nil
        }
        return MediaPreviewItem(url: asset.largeURL)
    }
}
