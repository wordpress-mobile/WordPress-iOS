import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared
import WPMediaPicker

/// Displays the user's media library in a grid
///
class MediaLibraryViewController: UIViewController {
    fileprivate static let restorationIdentifier = "MediaLibraryViewController"

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

    lazy fileprivate var searchBar: UISearchBar = {
        let bar = UISearchBar()

        WPStyleGuide.configureSearchBar(bar)

        bar.delegate = self
        bar.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return bar
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

        super.restorationIdentifier = MediaLibraryViewController.restorationIdentifier
        restorationClass = MediaLibraryViewController.self

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

        registerForKeyboardNotifications()

        if let searchQuery = searchQuery,
            !searchQuery.isEmpty {

            // If we deleted the last asset, then clear the search
            if pickerDataSource.numberOfAssets() == 0 {
                clearSearch()
            } else {
                searchBar.text = searchQuery
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        selectedAsset = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        unregisterForKeyboardNotifications()

        if searchBar.isFirstResponder {
            searchQuery = searchBar.text
            searchBar.resignFirstResponder()
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
        searchBarContainer.addSubview(searchBar)
        searchBar.sizeToFit()
    }

    private func addNoResultsView() {
        guard let noResultsView = WPNoResultsView(title: nil,
                                               message: nil,
                                               accessoryView: UIImageView(image: UIImage(named: "media-no-results")),
                                               buttonTitle: nil) else { return }

        pickerViewController.collectionView?.addSubview(noResultsView)
        noResultsView.centerInSuperview()

        noResultsView.delegate = self

        self.noResultsView = noResultsView
    }

    // MARK: - Keyboard handling

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    private func unregisterForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    @objc private func keyboardDidChangeFrame(_ notification: Foundation.Notification) {
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.2

        UIView.animate(withDuration: duration) {
            self.noResultsView?.centerInSuperview()
        }
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

        if hasSearchQuery {
            let text = NSLocalizedString("No media files match your search for %@", comment: "Message displayed when no results are returned from a media library search. Should match Calypso.")
            noResultsView?.titleText = String.localizedStringWithFormat(text, pickerDataSource.searchQuery)
            noResultsView?.messageText = nil
            noResultsView?.buttonTitle = nil
        } else {
            noResultsView?.titleText = NSLocalizedString("You don't have any media.", comment: "Title displayed when the user doesn't have any media in their media library. Should match Calypso.")
            noResultsView?.messageText = NSLocalizedString("Would you like to upload something?", comment: "Prompt displayed when the user has an empty media library. Should match Calypso.")
            noResultsView?.buttonTitle = NSLocalizedString("Upload Media", comment: "Title for button displayed when the user has an empty media library")
        }

        noResultsView?.sizeToFit()
    }

    private func updateSearchBar(for assetCount: Int) {
        let shouldShowBar = hasSearchQuery || assetCount > 0

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

    private var hasSearchQuery: Bool {
        return (pickerDataSource.searchQuery ?? "").characters.count > 0
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

        let deletedItemsCount = assets.count

        let updateProgress = { (progress: Progress?) in
            let fractionCompleted = progress?.fractionCompleted ?? 0
            SVProgressHUD.showProgress(Float(fractionCompleted), status: NSLocalizedString("Deleting...", comment: "Text displayed in HUD while a media item is being deleted."))
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)

        // Initialize the progress HUD before we start
        updateProgress(nil)

        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteMedia(assets,
                            progress: updateProgress,
                            success: { [weak self] in
                                WPAppAnalytics.track(.mediaLibraryDeletedItems, withProperties: ["number_of_items_deleted": deletedItemsCount], with: self?.blog)
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

            strongSelf.updateViewState(for: strongSelf.pickerDataSource.numberOfAssets())

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

// MARK: - UISearchBarDelegate

extension MediaLibraryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        pickerDataSource.searchQuery = searchText
        pickerViewController.collectionView?.reloadData()

        updateNoResultsView(for: pickerDataSource.numberOfAssets())
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearSearch()
        searchBar.resignFirstResponder()
    }

    func clearSearch() {
        searchQuery = nil
        searchBar.text = nil
        pickerDataSource.searchQuery = nil
        pickerViewController.collectionView?.reloadData()

        updateNoResultsView(for: pickerDataSource.numberOfAssets())
    }
}

// MARK: - WPMediaPickerViewControllerDelegate

extension MediaLibraryViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPickingAssets assets: [Any]) {

    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor asset: WPMediaAsset) -> UIViewController? {
        WPAppAnalytics.track(.mediaLibraryPreviewedItem, with: blog)
        return mediaItemViewController(for: asset)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldSelect asset: WPMediaAsset) -> Bool {
        if isEditing { return true }

        if let viewController = mediaItemViewController(for: asset) {
            WPAppAnalytics.track(.mediaLibraryPreviewedItem, with: blog)
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

        return MediaItemViewController(media: asset)
    }
}

// MARK: - State restoration

extension MediaLibraryViewController: UIViewControllerRestoration {
    enum EncodingKey {
        static let blogURL = "blogURL"
    }

    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last as? String,
            identifier == MediaLibraryViewController.restorationIdentifier else {
                return nil
        }

        guard let blogURL = coder.decodeObject(forKey: EncodingKey.blogURL) as? URL else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: blogURL),
            let object = try? context.existingObject(with: objectID),
            let blog = object as? Blog else {
                return nil
        }
        return MediaLibraryViewController(blog: blog)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        coder.encode(blog.objectID.uriRepresentation(), forKey: EncodingKey.blogURL)
    }
}
