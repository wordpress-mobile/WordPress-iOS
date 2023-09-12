import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared
import WPMediaPicker
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

/// Displays the user's media library in a grid
///
class MediaLibraryViewController: WPMediaPickerViewController {
    fileprivate static let restorationIdentifier = "MediaLibraryViewController"

    @objc let blog: Blog

    fileprivate let pickerDataSource: MediaLibraryPickerDataSource

    fileprivate var isLoading: Bool = false
    fileprivate let noResultsView = NoResultsViewController.controller()
    fileprivate let addButton: SpotlightableButton = SpotlightableButton(type: .custom)

    fileprivate var kvoTokens: [NSKeyValueObservation]?

    fileprivate var selectedAsset: Media? = nil

    // After 99% progress, we'll count a media item as being uploaded, and we'll
    // show an indeterminate spinner as the server processes it.
    fileprivate static let uploadCompleteProgress: Double = 0.99

    fileprivate var uploadObserverUUID: UUID?

    fileprivate lazy var mediaPickingCoordinator: MediaLibraryMediaPickingCoordinator = {
        return MediaLibraryMediaPickingCoordinator(delegate: self)
    }()

    // MARK: - Initializers

    @objc init(blog: Blog) {
        WPMediaCollectionViewCell.appearance().placeholderTintColor = .neutral(.shade5)
        WPMediaCollectionViewCell.appearance().placeholderBackgroundColor = .neutral(.shade70)
        WPMediaCollectionViewCell.appearance().loadingBackgroundColor = .listBackground

        self.blog = blog
        self.pickerDataSource = MediaLibraryPickerDataSource(blog: blog)
        self.pickerDataSource.includeUnsyncedMedia = true

        super.init(options: MediaLibraryViewController.pickerOptions())

        registerClass(forReusableCellOverlayViews: CircularProgressView.self)

        super.restorationIdentifier = MediaLibraryViewController.restorationIdentifier
        restorationClass = MediaLibraryViewController.self

        self.dataSource = pickerDataSource
        self.mediaPickerDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showForBlog(_ blog: Blog, from sourceController: UIViewController) {
        let controller = MediaLibraryViewController(blog: blog)
        controller.navigationItem.largeTitleDisplayMode = .never
        sourceController.navigationController?.pushViewController(controller, animated: true)

        QuickStartTourGuide.shared.visited(.mediaScreen)
    }

    deinit {
        unregisterChangeObserver()
        unregisterUploadCoordinatorObserver()
        stopObservingNavigationBarClipsToBounds()
    }

    private class func pickerOptions() -> WPMediaPickerOptions {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowMultipleSelection = false
        options.allowCaptureOfMedia = false
        options.showSearchBar = true
        options.showActionBar = false
        options.badgedUTTypes = [UTType.gif.identifier]
        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle

        return options
    }

    // MARK: - View Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Media", comment: "Title for Media Library section of the app.")

        extendedLayoutIncludesOpaqueBars = true

        registerChangeObserver()
        registerUploadCoordinatorObserver()

        noResultsView.configureForNoAssets(userCanUploadMedia: blog.userCanUploadMedia)
        noResultsView.delegate = self

        updateViewState(for: pickerDataSource.totalAssetCount)

        if let collectionView = collectionView {
            WPStyleGuide.configureColors(view: view, collectionView: collectionView)
        }

        navigationController?.navigationBar.subviews.forEach ({ $0.clipsToBounds = false })
        startObservingNavigationBarClipsToBounds()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        selectedAsset = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if searchBar?.isFirstResponder == true {
            searchBar?.resignFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.mediaUpload)
    }

    // MARK: - Update view state

    fileprivate func updateViewState(for assetCount: Int) {
        updateNavigationItemButtons(for: assetCount)
        updateNoResultsView(for: assetCount)
        updateSearchBar(for: assetCount)
    }

    private func updateNavigationItemButtons(for assetCount: Int) {
        if isEditing {
            navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editTapped)), animated: false)

            let trashButton = UIBarButtonItem(image: .gridicon(.trash), style: .plain, target: self, action: #selector(trashTapped))
            trashButton.accessibilityLabel = NSLocalizedString("Trash", comment: "Accessibility label for trash button to delete items from the user's media library")
            trashButton.accessibilityHint = NSLocalizedString("Trash selected media", comment: "Accessibility hint for trash button to delete items from the user's media library")
            navigationItem.setRightBarButtonItems([trashButton], animated: true)
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.setLeftBarButton(nil, animated: false)

            var barButtonItems = [UIBarButtonItem]()

            if blog.userCanUploadMedia {
                addButton.spotlightOffset = Constants.addButtonSpotlightOffset
                let config = UIImage.SymbolConfiguration(textStyle: .body, scale: .large)
                let image = UIImage(systemName: "plus", withConfiguration: config) ?? .gridicon(.plus)
                addButton.setImage(image, for: .normal)
                addButton.contentEdgeInsets = Constants.addButtonContentInset
                addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
                addButton.accessibilityLabel = NSLocalizedString("Add", comment: "Accessibility label for add button to add items to the user's media library")
                addButton.accessibilityHint = NSLocalizedString("Add new media", comment: "Accessibility hint for add button to add items to the user's media library")

                let addBarButton = UIBarButtonItem(customView: addButton)
                barButtonItems.append(addBarButton)
            }

            if blog.supports(.mediaDeletion) && assetCount > 0 {
                let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
                editButton.accessibilityLabel = NSLocalizedString("Edit", comment: "Accessibility label for edit button to enable multi selection mode in the user's media library")
                editButton.accessibilityHint = NSLocalizedString("Enter edit mode to enable multi select to delete", comment: "Accessibility hint for edit button to enable multi selection mode in the user's media library")

                barButtonItems.append(editButton)

            }
            navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
        }
    }

    fileprivate func updateNoResultsView(for assetCount: Int) {

        guard assetCount == 0 else { return }

        if isLoading {
            noResultsView.configureForFetching()
        } else {
            noResultsView.removeFromView()

            if hasSearchQuery {
                noResultsView.configureForNoSearchResult()
            } else {
                noResultsView.configureForNoAssets(userCanUploadMedia: blog.userCanUploadMedia)
            }
        }
    }

    private func updateSearchBar(for assetCount: Int) {
        let shouldShowBar = hasSearchQuery || assetCount > 0

        if shouldShowBar {
            showSearchBar()
            if let searchBar = self.searchBar {
                WPStyleGuide.configureSearchBar(searchBar)
            }
        } else {
            hideSearchBar()
        }
    }

    private func reloadCell(for media: Media) {
        visibleCells(for: media).forEach { cell in
            cell.overlayView = nil
            cell.asset = media
        }
    }

    private func updateCellProgress(_ progress: Double, for media: Media) {
        visibleCells(for: media).forEach { cell in
            if let overlayView = cell.overlayView as? CircularProgressView {
                if progress < MediaLibraryViewController.uploadCompleteProgress {
                    overlayView.state = .progress(progress)
                } else {
                    overlayView.state = .indeterminate
                }

                configureAppearance(for: overlayView, with: media)
            }
        }
    }

    private func configureAppearance(for overlayView: CircularProgressView, with media: Media) {
        if media.localThumbnailURL != nil {
            overlayView.backgroundColor = overlayView.backgroundColor?.withAlphaComponent(0.5)
        } else {
            overlayView.backgroundColor = overlayView.backgroundColor?.withAlphaComponent(1)
        }
    }

    private func showUploadingStateForCell(for media: Media) {
        visibleCells(for: media).forEach { cell in
            if let overlayView = cell.overlayView as? CircularProgressView {
                overlayView.state = .indeterminate
            }
        }
    }

    private func showFailedStateForCell(for media: Media) {
        visibleCells(for: media).forEach { cell in
            if let overlayView = cell.overlayView as? CircularProgressView {
                overlayView.state = .retry
                configureAppearance(for: overlayView, with: media)
            }
        }
    }

    private func visibleCells(for media: Media) -> [WPMediaCollectionViewCell] {
        guard let cells = collectionView?.visibleCells as? [WPMediaCollectionViewCell] else {
            return []
        }

        return cells.filter({ ($0.asset as? Media) == media })
    }

    private var hasSearchQuery: Bool {
        return (pickerDataSource.searchQuery ?? "").count > 0
    }

    // MARK: - Actions

    @objc fileprivate func addTapped() {
        QuickStartTourGuide.shared.visited(.mediaUpload)
        addButton.shouldShowSpotlight = QuickStartTourGuide.shared.isCurrentElement(.mediaUpload)
        showOptionsMenu()
    }

    private func showOptionsMenu() {

        let pickingContext: MediaPickingContext
        if pickerDataSource.totalAssetCount > 0 {
            pickingContext = MediaPickingContext(origin: self, view: view, barButtonItem: navigationItem.rightBarButtonItem, blog: blog)
        } else {
            pickingContext = MediaPickingContext(origin: self, view: noResultsView.actionButton, blog: blog)
        }

        mediaPickingCoordinator.present(context: pickingContext)
    }

    @objc private func editTapped() {
        isEditing = !isEditing
    }

    @objc private func trashTapped() {
        let message: String
        if selectedAssets.count == 1 {
            message = NSLocalizedString("Are you sure you want to permanently delete this item?", comment: "Message prompting the user to confirm that they want to permanently delete a media item. Should match Calypso.")
        } else {
            message = NSLocalizedString("Are you sure you want to permanently delete these items?", comment: "Message prompting the user to confirm that they want to permanently delete a group of media items.")
        }

        let alertController = UIAlertController(title: nil,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Verb. Button title. Tapping cancels an action."))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Delete", comment: "Title for button that permanently deletes one or more media items (photos / videos)"), handler: { action in
            self.deleteSelectedItems()
        })

        present(alertController, animated: true)
    }

    private func deleteSelectedItems() {
        guard selectedAssets.count > 0 else { return }
        guard let assets = selectedAssets as? [Media] else { return }

        let deletedItemsCount = assets.count

        let updateProgress = { (progress: Progress?) in
            let fractionCompleted = progress?.fractionCompleted ?? 0
            SVProgressHUD.showProgress(Float(fractionCompleted), status: NSLocalizedString("Deleting...", comment: "Text displayed in HUD while a media item is being deleted."))
        }

        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)

        // Initialize the progress HUD before we start
        updateProgress(nil)
        isEditing = false

        MediaCoordinator.shared.delete(media: assets,
                                       onProgress: updateProgress,
                                       success: { [weak self] in
            WPAppAnalytics.track(.mediaLibraryDeletedItems, withProperties: ["number_of_items_deleted": deletedItemsCount], with: self?.blog)
            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Deleted!", comment: "Text displayed in HUD after successfully deleting a media item"))
        },
                                       failure: {
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete all media items.", comment: "Text displayed in HUD if there was an error attempting to delete a group of media items."))
        })
    }

    fileprivate func presentRetryOptions(for media: Media) {
        let style: UIAlertController.Style = UIDevice.isPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: style)
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Cancel Upload", comment: "Media Library option to cancel an in-progress or failed upload.")) { _ in
            MediaCoordinator.shared.delete(media: [media])
        }

        if media.remoteStatus == .failed {
            if let error = media.error {
                alertController.message = error.localizedDescription
            }
            if media.canRetry {
                alertController.addDefaultActionWithTitle(NSLocalizedString("Retry Upload", comment: "User action to retry media upload.")) { _ in
                    let info = MediaAnalyticsInfo(origin: .mediaLibrary(.wpMediaLibrary))
                    MediaCoordinator.shared.retryMedia(media, analyticsInfo: info)
                }
            }
        }

        alertController.addCancelActionWithTitle(
            NSLocalizedString(
                "mediaLibrary.retryOptionsAlert.dismissButton",
                value: "Dismiss",
                comment: "Verb. Button title. Tapping dismisses a prompt."
            )
        )

        present(alertController, animated: true)
    }

    override var isEditing: Bool {
        didSet {
            updateNavigationItemButtons(for: pickerDataSource.totalAssetCount)
            let options = self.options.copy() as! WPMediaPickerOptions
            options.allowMultipleSelection = isEditing
            self.options = options
            clearSelectedAssets(false)
        }
    }

    // MARK: - Media Library Change Observer

    private var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil

    private func registerChangeObserver() {
        assert(mediaLibraryChangeObserverKey == nil)
        mediaLibraryChangeObserverKey = pickerDataSource.registerChangeObserverBlock({ [weak self] _, removed, inserted, _, _ in
            guard let strongSelf = self else { return }
            guard removed.count > 0 || inserted.count > 0 else { return }

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

    // MARK: - Upload Coordinator Observer

    private func registerUploadCoordinatorObserver() {
        uploadObserverUUID = MediaCoordinator.shared.addObserver({ [weak self] (media, state) in
            switch state {
            case .progress(let progress):
                if media.remoteStatus == .failed {
                    self?.showFailedStateForCell(for: media)
                } else {
                    self?.updateCellProgress(progress, for: media)
                }
            case .processing, .uploading:
                self?.showUploadingStateForCell(for: media)
            case .ended:
                self?.reloadCell(for: media)
            case .failed:
                self?.showFailedStateForCell(for: media)
            case .thumbnailReady:
                if media.remoteStatus == .failed {
                    self?.showFailedStateForCell(for: media)
                } else {
                    self?.showUploadingStateForCell(for: media)
                }
            }
            }, for: nil)
    }

    private func unregisterUploadCoordinatorObserver() {
        if let uuid = uploadObserverUUID {
            MediaCoordinator.shared.removeObserver(withUUID: uuid)
        }
    }

    // MARK: ClipsToBounds KVO Observer

    /// The content view of the navigation bar causes the spotlight view on the add button to be clipped.
    /// This ensures that `clipsToBounds` of the content view is always `false`.
    /// Without this, `clipsToBounds` reverts to `true` at some point during the view lifecycle. This happens asynchronously,
    /// so we can't confidently reset it. Hence the need for KVO.
    private func startObservingNavigationBarClipsToBounds() {
        kvoTokens = navigationController?.navigationBar.subviews.map({ subview in
            return subview.observe(\.clipsToBounds, options: .new, changeHandler: { view, change in
                guard let newValue = change.newValue, newValue else { return }
                view.clipsToBounds = false
            })
        })
    }

    private func stopObservingNavigationBarClipsToBounds() {
        kvoTokens?.forEach({ $0.invalidate() })
    }
}

// MARK: - PHPickerViewControllerDelegate

extension MediaLibraryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        for result in results {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.deviceLibrary), selectionMethod: .fullScreenPicker)
            MediaCoordinator.shared.addMedia(from: result.itemProvider, to: blog, analyticsInfo: info)
        }
    }
}

// MARK: - ImagePickerControllerDelegate

extension MediaLibraryViewController: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)

        func addAsset(from exportableAsset: ExportableAsset) {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.camera), selectionMethod: .fullScreenPicker)
            MediaCoordinator.shared.addMedia(from: exportableAsset, to: blog, analyticsInfo: info)
        }

        guard let mediaType = info[.mediaType] as? String else {
            return
        }
        switch mediaType {
        case UTType.image.identifier:
            if let image = info[.originalImage] as? UIImage {
                addAsset(from: image)
            }

        case UTType.movie.identifier:
            guard let videoURL = info[.mediaURL] as? URL else {
                return
            }
            guard self.blog.canUploadVideo(from: videoURL) else {
                self.presentVideoLimitExceededAfterCapture(on: self)
                return
            }
            addAsset(from: videoURL as NSURL)
        default:
            break
        }
    }
}


// MARK: - UIDocumentPickerDelegate

extension MediaLibraryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for documentURL in urls as [NSURL] {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.otherApps), selectionMethod: .documentPicker)
            MediaCoordinator.shared.addMedia(from: documentURL, to: blog, analyticsInfo: info)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
    }
}

// MARK: - NoResultsViewControllerDelegate

extension MediaLibraryViewController: NoResultsViewControllerDelegate {
    func actionButtonPressed() {
        addTapped()
    }
}

// MARK: - User messages for video limits allowances
extension MediaLibraryViewController: VideoLimitsAlertPresenter {}

// MARK: - WPMediaPickerViewControllerDelegate

extension MediaLibraryViewController: WPMediaPickerViewControllerDelegate {

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        return noResultsView
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        updateNoResultsView(for: assetCount)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        // We're only interested in the upload picker
        guard picker != self else { return }
        pickerDataSource.searchCancelled()

        dismiss(animated: true)

        guard ReachabilityUtils.isInternetReachable() else {
            ReachabilityUtils.showAlertNoInternetConnection()
            return
        }

        guard let assets = assets as? [PHAsset],
            assets.count > 0 else { return }

        for asset in assets {
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.deviceLibrary), selectionMethod: .fullScreenPicker)
            MediaCoordinator.shared.addMedia(from: asset, to: blog, analyticsInfo: info)
        }
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        pickerDataSource.searchCancelled()

        dismiss(animated: true)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, willShowOverlayView overlayView: UIView, forCellFor asset: WPMediaAsset) {
        guard let overlayView = overlayView as? CircularProgressView,
            let media = asset as? Media else {
            return
        }
        WPStyleGuide.styleProgressViewForMediaCell(overlayView)
        switch media.remoteStatus {
        case .processing:
            if let progress = MediaCoordinator.shared.progress(for: media) {
                overlayView.state = .progress(progress.fractionCompleted)
            } else {
                overlayView.state = .indeterminate
            }
        case .pushing:
            if let progress = MediaCoordinator.shared.progress(for: media) {
                overlayView.state = .progress(progress.fractionCompleted)
            }
        case .failed:
            overlayView.state = .retry
        default: break
        }
        configureAppearance(for: overlayView, with: media)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShowOverlayViewForCellFor asset: WPMediaAsset) -> Bool {
        if picker != self, !blog.canUploadAsset(asset) {
            return true
        }
        if let media = asset as? Media {
            return media.remoteStatus != .sync
        }

        return false
    }

    func mediaPickerControllerShouldShowCustomHeaderView(_ picker: WPMediaPickerViewController) -> Bool {
        guard picker != self else {
            return false
        }

        // Show the device media permissions header if photo library access is limited
        return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
    }

    func mediaPickerControllerReferenceSize(forCustomHeaderView picker: WPMediaPickerViewController) -> CGSize {
        let header = DeviceMediaPermissionsHeader()
        header.translatesAutoresizingMaskIntoConstraints = false

        return header.referenceSizeInView(picker.view)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, configureCustomHeaderView headerView: UICollectionReusableView) {
        guard let headerView = headerView as? DeviceMediaPermissionsHeader else {
            return
        }

        headerView.presenter = picker
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor asset: WPMediaAsset) -> UIViewController? {
        guard picker == self else { return WPAssetViewController(asset: asset) }

        guard let media = asset as? Media,
            media.remoteStatus == .sync else {
                return nil
        }

        WPAppAnalytics.track(.mediaLibraryPreviewedItem, with: blog)
        return mediaItemViewController(for: asset)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldSelect asset: WPMediaAsset) -> Bool {
        if picker != self, !blog.canUploadAsset(asset) {
            presentVideoLimitExceededFromPicker(on: picker)
            return false
        }

        guard picker == self else {
            return true
        }

        guard let media = asset as? Media else {
            return false
        }

        guard !isEditing else {
            return media.remoteStatus == .sync || media.remoteStatus == .failed
        }

        switch media.remoteStatus {
        case .failed, .pushing, .processing:
            presentRetryOptions(for: media)
        case .sync:
            if let viewController = mediaItemViewController(for: asset) {
                WPAppAnalytics.track(.mediaLibraryPreviewedItem, with: blog)
                navigationController?.pushViewController(viewController, animated: true)
            }
        default: break
        }

        return false
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didSelect asset: WPMediaAsset) {
        guard picker == self else { return }

        updateNavigationItemButtonsForCurrentAssetSelection()
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didDeselect asset: WPMediaAsset) {
        guard picker == self else { return }

        updateNavigationItemButtonsForCurrentAssetSelection()
    }

    @objc func updateNavigationItemButtonsForCurrentAssetSelection() {
        if isEditing {
            // Check that our selected items haven't been deleted – we're notified
            // of changes to the data source before the collection view has
            // updated its selected assets.
            guard let assets = (selectedAssets as? [Media]) else { return }
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

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        guard picker == self else { return }

        isLoading = true

        updateNoResultsView(for: pickerDataSource.numberOfAssets())
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        guard picker == self else { return }

        isLoading = false

        updateViewState(for: pickerDataSource.numberOfAssets())
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, handleError error: Error) -> Bool {
        guard picker == self else { return false }

        let nserror = error as NSError
        if let mediaLibrary = self.blog.media, !mediaLibrary.isEmpty {
            let title = NSLocalizedString("Unable to Sync", comment: "Title of error prompt shown when a sync the user initiated fails.")
            WPError.showNetworkingNotice(title: title, error: nserror)
        }
        return true
    }
}

// MARK: - State restoration

extension MediaLibraryViewController: UIViewControllerRestoration {
    enum EncodingKey {
        static let blogURL = "blogURL"
    }

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        guard let identifier = identifierComponents.last,
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

fileprivate extension Blog {
    var userCanUploadMedia: Bool {
        // Self-hosted non-Jetpack blogs have no capabilities, so we'll just assume that users can post media
        return capabilities != nil ? isUploadingFilesAllowed() : true
    }
}

// MARK: Stock Photos Picker Delegate

extension MediaLibraryViewController: StockPhotosPickerDelegate {
    func stockPhotosPicker(_ picker: StockPhotosPicker, didFinishPicking assets: [StockPhotosMedia]) {
        guard assets.count > 0 else {
            return
        }

        let mediaCoordinator = MediaCoordinator.shared
        assets.forEach { stockPhoto in
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.stockPhotos), selectionMethod: .fullScreenPicker)
            mediaCoordinator.addMedia(from: stockPhoto, to: blog, analyticsInfo: info)
            WPAnalytics.track(.stockMediaUploaded)
        }
    }
}

// MARK: Tenor Picker Delegate

extension MediaLibraryViewController: TenorPickerDelegate {
    func tenorPicker(_ picker: TenorPicker, didFinishPicking assets: [TenorMedia]) {
        guard assets.count > 0 else {
            return
        }

        let mediaCoordinator = MediaCoordinator.shared
        assets.forEach { tenorMedia in
            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.tenor), selectionMethod: .fullScreenPicker)
            mediaCoordinator.addMedia(from: tenorMedia, to: blog, analyticsInfo: info)
            WPAnalytics.track(.tenorUploaded)
        }
    }
}

// MARK: Constants

extension MediaLibraryViewController {
    private enum Constants {
        static let addButtonSpotlightOffset = UIOffset(horizontal: 20, vertical: -10)
        static let addButtonContentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
    }
}
