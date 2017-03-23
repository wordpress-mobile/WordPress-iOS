import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared
import WPMediaPicker

/// Displays the user's media library in a grid
///
class MediaLibraryViewController: UIViewController {
    let blog: Blog

    fileprivate let pickerViewController: WPMediaPickerViewController
    fileprivate let pickerDataSource: MediaLibraryPickerDataSource

    fileprivate var noResultsView: WPNoResultsView? = nil

    fileprivate var selectedAsset: Media? = nil

    private let defaultSearchBarHeight: CGFloat = 44.0
    lazy fileprivate var searchBarContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy fileprivate var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.hidesNavigationBarDuringPresentation = true
        controller.dimsBackgroundDuringPresentation = false

        WPStyleGuide.configureSearchBar(controller.searchBar)
        controller.searchBar.delegate = self
        controller.searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return controller
    }()

    fileprivate let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()

    var searchQuery: String? = nil

    // MARK: - Initializers

    init(blog: Blog) {
        self.blog = blog
        self.pickerViewController = WPMediaPickerViewController()
        self.pickerDataSource = MediaLibraryPickerDataSource(blog: blog)

        super.init(nibName: nil, bundle: nil)

        configurePickerViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterChangeObserver()
    }

    private func configurePickerViewController() {
        pickerViewController.mediaPickerDelegate = self
        pickerViewController.allowCaptureOfMedia = false
        pickerViewController.filter = .videoOrImage
        pickerViewController.allowMultipleSelection = false
        pickerViewController.showMostRecentFirst = true
        pickerViewController.dataSource = pickerDataSource
    }

    // MARK: - View Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Media", comment: "Title for Media Library section of the app.")

        definesPresentationContext = true
        automaticallyAdjustsScrollViewInsets = false

        addStackView()
        addMediaPickerAsChildViewController()
        addSearchBarContainer()
        addNoResultsView()

        registerChangeObserver()

        updateViewState(for: pickerDataSource.totalAssetCount)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let searchQuery = searchQuery,
            !searchQuery.isEmpty {

            // If we deleted the last asset, then clear the search
            if pickerDataSource.numberOfAssets() == 0 {
                clearSearch()
            } else {
                searchController.searchBar.text = searchQuery
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        selectedAsset = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if searchController.isActive {
            searchQuery = searchController.searchBar.text
            searchController.isActive = false
        }
    }

    private func addStackView() {
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            topLayoutGuide.bottomAnchor.constraint(equalTo: stackView.topAnchor),
            bottomLayoutGuide.topAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    private func addMediaPickerAsChildViewController() {
        pickerViewController.willMove(toParentViewController: self)
        stackView.addArrangedSubview(pickerViewController.view)
        pickerViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pickerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        addChildViewController(pickerViewController)
        pickerViewController.didMove(toParentViewController: self)
    }

    private func addSearchBarContainer() {
        stackView.insertArrangedSubview(searchBarContainer, at: 0)

        NSLayoutConstraint.activate([
            searchBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let heightConstraint = searchBarContainer.heightAnchor.constraint(equalToConstant: defaultSearchBarHeight)
        heightConstraint.priority = UILayoutPriorityDefaultLow
        heightConstraint.isActive = true

        let expandedHeightConstraint = searchBarContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: defaultSearchBarHeight)
        expandedHeightConstraint.priority = UILayoutPriorityRequired
        expandedHeightConstraint.isActive = true

        searchBarContainer.layoutIfNeeded()
        searchBarContainer.addSubview(searchController.searchBar)
        searchController.searchBar.sizeToFit()
    }

    private func addNoResultsView() {
        guard let noResultsView = WPNoResultsView(title: nil,
                                               message: nil,
                                               accessoryView: UIImageView(image: UIImage(named: "media-no-results")),
                                               buttonTitle: nil) else { return }

        noResultsView.translatesAutoresizingMaskIntoConstraints = false

        pickerViewController.collectionView?.addSubview(noResultsView)
        pickerViewController.collectionView?.pinSubviewAtCenter(noResultsView)
        noResultsView.layoutIfNeeded()

        noResultsView.delegate = self

        self.noResultsView = noResultsView
    }

    // MARK: - Update view state

    private func updateViewState(for assetCount: Int) {
        updateNavigationItemButtons(for: assetCount)
        updateNoResultsView(for: assetCount)
        updateSearchBar(for: assetCount)
    }

    private func updateNavigationItemButtons(for assetCount: Int) {
        if isEditing {
            navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editTapped)), animated: true)
            navigationItem.setRightBarButton(UIBarButtonItem(image: Gridicon.iconOfType(.trash), style: .plain, target: self, action: #selector(trashTapped)), animated: true)
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.setLeftBarButton(nil, animated: true)
            if blog.supports(.mediaDeletion) && assetCount > 0 {
                navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped)), animated: true)
            } else {
                navigationItem.setRightBarButton(nil, animated: true)
            }
        }
    }

    fileprivate func updateNoResultsView(for assetCount: Int) {
        let shouldShowNoResults = (assetCount == 0)

        noResultsView?.isHidden = !shouldShowNoResults

        guard shouldShowNoResults else { return }

        if let searchQuery = pickerDataSource.searchQuery,
            searchQuery.characters.count > 0,
            searchController.isActive {
            let text = NSLocalizedString("No media files match your search for %@", comment: "Message displayed when no results are returned from a media library search. Should match Calypso.")
            noResultsView?.titleText = String.localizedStringWithFormat(text, searchQuery)
            noResultsView?.messageText = nil
            noResultsView?.buttonTitle = nil
        } else {
            noResultsView?.titleText = NSLocalizedString("You don't have any media.", comment: "Title displayed when the user doesn't have any media in their media library. Should match Calypso.")
            noResultsView?.messageText = NSLocalizedString("Would you like to upload something?", comment: "Prompt displayed when the user has an empty media library. Should match Calypso.")
            noResultsView?.buttonTitle = NSLocalizedString("Upload Media", comment: "Title for button displayed when the user has an empty media library")
        }
    }

    private func updateSearchBar(for assetCount: Int) {
        guard !searchController.isActive else { return }

        let shouldShowBar = assetCount > 0

        if shouldShowBar {
            if searchBarContainer.superview != stackView {
                stackView.insertArrangedSubview(searchBarContainer, at: 0)
            }
        } else {
            if searchBarContainer.superview == stackView {
                searchBarContainer.removeFromSuperview()
            }
        }
    }

    // MARK: - Actions

    @objc private func editTapped() {
        isEditing = !isEditing

        pickerViewController.allowMultipleSelection = isEditing

        pickerViewController.clearSelectedAssets(true)
    }

    @objc private func trashTapped() {
        let message: String
        if pickerViewController.selectedAssets.count == 1 {
            message = NSLocalizedString("Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso.")
        } else {
            message = NSLocalizedString("Are you sure you want to permanently delete these items?", comment: "Message prompting the user to confirm that they want to permanently delete a group of media items.")
        }

        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Delete", comment: "Title for button that permanently deletes one or more media items (photos / videos)"), handler: { action in
            self.deleteSelectedItems()
        })

        present(alertController, animated: true, completion: nil)
    }

    private func deleteSelectedItems() {
        guard pickerViewController.selectedAssets.count > 0 else { return }
        guard let assets = pickerViewController.selectedAssets.copy() as? [Media] else { return }

        let updateProgress = { (progress: Progress?) in
            let fractionCompleted = progress?.fractionCompleted ?? 0
            SVProgressHUD.showProgress(Float(fractionCompleted), status: NSLocalizedString("Deleting...", comment: "Text displayed in HUD while a media item is being deleted."))
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)

        // Initialize the progress HUD before we start
        updateProgress(nil)

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteMultipleMedia(assets,
                                    progress: updateProgress,
                                    success: { [weak self] in
                                        SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Deleted!", comment: "Text displayed in HUD after successfully deleting a media item"))
                                        self?.isEditing = false
        }, failure: { error in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete all media items.", comment: "Text displayed in HUD if there was an error attempting to delete a group of media items."))
        })
    }

    override var isEditing: Bool {
        didSet {
            updateNavigationItemButtons(for: pickerDataSource.totalAssetCount)
        }
    }

    // MARK: - Media Library Change Observer

    private var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil

    private func registerChangeObserver() {
        assert(mediaLibraryChangeObserverKey == nil)
        mediaLibraryChangeObserverKey = pickerDataSource.registerChangeObserverBlock({ [weak self] _, _, _, _, _ in
            guard let strongSelf = self else { return }

            strongSelf.updateViewState(for: strongSelf.pickerDataSource.totalAssetCount)

            if strongSelf.pickerDataSource.totalAssetCount > 0 {
                strongSelf.updateNavigationItemButtonsForCurrentAssetSelection()
            } else {
                strongSelf.isEditing = false
            }

            // If we're presenting an item and it's been deleted, pop the
            // detail view off the stack
            if let navigationController = strongSelf.navigationController,
                navigationController.topViewController != strongSelf,
                let asset = strongSelf.selectedAsset,
                asset.isDeleted {
                _ = strongSelf.navigationController?.popToViewController(strongSelf, animated: true)
            }
        })
    }

    private func unregisterChangeObserver() {
        if let mediaLibraryChangeObserverKey = mediaLibraryChangeObserverKey {
            pickerDataSource.unregisterChangeObserver(mediaLibraryChangeObserverKey)
        }
    }
}

// MARK: - WPNoResultsViewDelegate

extension MediaLibraryViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        // TODO: Present upload UI
    }
}

// MARK: - UISearchResultsUpdating

extension MediaLibraryViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            pickerDataSource.searchQuery = searchController.searchBar.text
            pickerViewController.collectionView?.reloadData()

            updateNoResultsView(for: pickerDataSource.numberOfAssets())
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        clearSearch()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearSearch()
    }

    func clearSearch() {
        searchQuery = nil
        searchController.searchBar.text = nil
        pickerDataSource.searchQuery = nil
        pickerViewController.collectionView?.reloadData()
    }
}

// MARK: - WPMediaPickerViewControllerDelegate

extension MediaLibraryViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPickingAssets assets: [Any]) {

    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor asset: WPMediaAsset) -> UIViewController? {
        return mediaItemViewController(for: asset)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldSelect asset: WPMediaAsset) -> Bool {
        if isEditing { return true }

        if let viewController = mediaItemViewController(for: asset) {
            navigationController?.pushViewController(viewController, animated: true)
        }

        return false
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didSelect asset: WPMediaAsset) {
        updateNavigationItemButtonsForCurrentAssetSelection()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didDeselect asset: WPMediaAsset) {
        updateNavigationItemButtonsForCurrentAssetSelection()
    }

    func updateNavigationItemButtonsForCurrentAssetSelection() {
        if isEditing {
            // Check that our selected items haven't been deleted – we're notified
            // of changes to the data source before the collection view has
            // updated its selected assets.
            guard let assets = (pickerViewController.selectedAssets.copy() as? [Media]) else { return }
            let existingAssets = assets.filter({ !$0.isDeleted })

            navigationItem.rightBarButtonItem?.isEnabled = (existingAssets.count > 0)
        }
    }

    private func mediaItemViewController(for asset: WPMediaAsset) -> UIViewController? {
        if isEditing { return nil }

        guard let asset = asset as? Media else {
            return nil
        }

        selectedAsset = asset

        return MediaItemViewController(media: asset, dataSource: pickerDataSource)
    }
}
