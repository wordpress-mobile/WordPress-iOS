import UIKit

protocol ExternalMediaPickerViewDelegate: AnyObject {
    /// If the user cancels the flow, the selection is empty.
    func externalMediaPickerViewController(_ viewController: ExternalMediaPickerViewController, didFinishWithSelection selection: [TenorMedia])
}

final class ExternalMediaPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating {
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private lazy var flowLayout = UICollectionViewFlowLayout()
    private var collectionViewDataSource: UICollectionViewDiffableDataSource<Int, String>!
    private let searchController = UISearchController()
    private let activityIndicator = UIActivityIndicatorView()
    private let toolbarItemTitle = ExternalMediaSelectionTitleView()
    private lazy var buttonDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(buttonDoneTapped))

    private let dataSource: TenorDataSource
    private var allowsMultipleSelection: Bool
    private var selection = NSMutableOrderedSet()
    private var observerKey: NSObjectProtocol?

    /// A view to show when the screen is first open and the search query
    /// wasn't added.
    var welcomeView: UIView?

    weak var delegate: ExternalMediaPickerViewDelegate?

    init(dataSource: TenorDataSource,
         allowsMultipleSelection: Bool = false) {
        self.dataSource = dataSource
        self.allowsMultipleSelection = allowsMultipleSelection
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
        configureActivityIndicator()
        configureNavigationItems()
        configureToolbarItems()

        if let welcomeView {
            view.addSubview(welcomeView)
            welcomeView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(welcomeView)
        }

        observerKey = dataSource.registerChangeObserverBlock { [weak self] _, _, _, _, _ in
            self?.reloadData()
        }

        dataSource.onStartLoading = { [weak self] in self?.didChangeLoading(true) }
        dataSource.onStopLoading = { [weak self] in self?.didChangeLoading(false) }

        searchController.searchBar.becomeFirstResponder()

        // TODO: add fullscreen preview for selection using QuickLookViewController and selection toolbar
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
    }

    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(dataSource.tenorMedia.map(\.id), toSection: 0)
        collectionViewDataSource.apply(snapshot, animatingDifferences: false)

        let remaning = NSOrderedSet(array: dataSource.tenorMedia)
        selection.intersect(remaning)
        didUpdateSelection()
    }

    private func didChangeLoading(_ isLoading: Bool) {
        if isLoading && dataSource.numberOfAssets() == 0 {
            activityIndicator.startAnimating()
            welcomeView?.isHidden = true
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func item(at index: Int) -> TenorMedia {
        dataSource.media(at: index) as! TenorMedia
    }

    // MARK: - Selection

    private func setSelected(_ isSelected: Bool, for media: TenorMedia) {
        if isSelected {
            selection.add(media)
        } else {
            selection.remove(media)
        }
        didUpdateSelection()
    }

    private func didUpdateSelection() {
        toolbarItemTitle.setSelectionCount(selection.count)
        navigationController?.setToolbarHidden(dataSource.numberOfAssets() == 0, animated: true)

        // Update badges for visible items (might need to update count)
        for indexPath in collectionView.indexPathsForVisibleItems {
            let item = item(at: indexPath.item)
            let index = selection.index(of: item)
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
        let selection = (collectionView.indexPathsForSelectedItems ?? [])
            .map { item(at: $0.item) }
        delegate?.externalMediaPickerViewController(self, didFinishWithSelection: selection)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.numberOfAssets()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(cell: ExternalMediaPickerCollectionCell.self, for: indexPath)!
        let item = item(at: indexPath.row)
        cell.configure(imageURL: item.previewURL, size: flowLayout.itemSize.scaled(by: UIScreen.main.scale))
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setSelected(true, for: item(at: indexPath.row))
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        setSelected(false, for: item(at: indexPath.row))
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""
        if searchTerm.count < 2 {
            dataSource.searchCancelled()
        } else {
            dataSource.search(for: searchTerm)
        }
    }
}
