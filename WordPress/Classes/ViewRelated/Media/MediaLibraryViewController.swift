import UIKit
import Gridicons
import SVProgressHUD
import WordPressShared
import WPMediaPicker
import MobileCoreServices


/// Displays the user's media library in a grid
///
class MediaLibraryViewController: WPMediaPickerViewController {
    fileprivate static let restorationIdentifier = "MediaLibraryViewController"

    @objc let blog: Blog

    fileprivate let pickerDataSource: MediaLibraryPickerDataSource

    fileprivate var isLoading: Bool = false
    fileprivate let noResultsView = MediaNoResultsView()

    fileprivate var selectedAsset: Media? = nil

    fileprivate var capturePresenter: WPMediaCapturePresenter?

    // After 99% progress, we'll count a media item as being uploaded, and we'll
    // show an indeterminate spinner as the server processes it.
    fileprivate static let uploadCompleteProgress: Double = 0.99

    fileprivate var uploadObserverUUID: UUID?

    // MARK: - Initializers

    @objc init(blog: Blog) {
        WPMediaCollectionViewCell.appearance().placeholderTintColor = WPStyleGuide.greyLighten30()
        WPMediaCollectionViewCell.appearance().placeholderBackgroundColor = WPStyleGuide.darkGrey()
        WPMediaCollectionViewCell.appearance().loadingBackgroundColor = WPStyleGuide.lightGrey()

        self.blog = blog
        self.pickerDataSource = MediaLibraryPickerDataSource(blog: blog)
        self.pickerDataSource.includeUnsyncedMedia = true

        super.init(options: MediaLibraryViewController.pickerOptions())

        registerClass(forReusableCellOverlayViews: MediaCellProgressView.self)

        super.restorationIdentifier = MediaLibraryViewController.restorationIdentifier
        restorationClass = MediaLibraryViewController.self

        self.dataSource = pickerDataSource
        self.mediaPickerDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unregisterChangeObserver()
        unregisterUploadCoordinatorObserver()
    }

    private class func pickerOptions() -> WPMediaPickerOptions {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowMultipleSelection = false
        options.allowCaptureOfMedia = false
        options.showSearchBar = true

        return options
    }

    // MARK: - View Loading

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Media", comment: "Title for Media Library section of the app.")

        automaticallyAdjustsScrollViewInsets = false

        registerChangeObserver()
        registerUploadCoordinatorObserver()
        noResultsView.delegate = self

        updateViewState(for: pickerDataSource.totalAssetCount)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetNavigationColors()
    }

    /*
     This is to restore the navigation bar colors after the UIDocumentPickerViewController has been dismissed,
     either by uploading media or cancelling. Doing this in the UIDocumentPickerDelegate methods either did nothing
     or the resetting wasn't permanent.
     */
    fileprivate func resetNavigationColors() {
        WPStyleGuide.configureNavigationBarAppearance()
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

    // MARK: - Update view state

    fileprivate func updateViewState(for assetCount: Int) {
        updateNavigationItemButtons(for: assetCount)
        updateNoResultsView(for: assetCount)
        updateSearchBar(for: assetCount)
    }

    private func updateNavigationItemButtons(for assetCount: Int) {
        if isEditing {
            navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(editTapped)), animated: false)

            let trashButton = UIBarButtonItem(image: Gridicon.iconOfType(.trash), style: .plain, target: self, action: #selector(trashTapped))
            navigationItem.setRightBarButtonItems([trashButton], animated: true)
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.setLeftBarButton(nil, animated: false)

            var barButtonItems = [UIBarButtonItem]()

            if blog.userCanUploadMedia {
                let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
                barButtonItems.append(addButton)
            }

            if blog.supports(.mediaDeletion) && assetCount > 0 {
                let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
                barButtonItems.append(editButton)

                navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
            } else {
                navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
            }
        }
    }

    fileprivate func updateNoResultsView(for assetCount: Int) {
        guard assetCount == 0 else { return }

        if isLoading {
            noResultsView.updateForFetching()
        } else if hasSearchQuery {
            noResultsView.updateForNoSearchResult(with: pickerDataSource.searchQuery)
        } else {
            noResultsView.updateForNoAssets(userCanUploadMedia: blog.userCanUploadMedia)
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
            if let overlayView = cell.overlayView as? MediaCellProgressView {
                if progress < MediaLibraryViewController.uploadCompleteProgress {
                    overlayView.state = .progress(progress)
                } else {
                    overlayView.state = .indeterminate
                }

                configureAppearance(for: overlayView, with: media)
            }
        }
    }

    private func configureAppearance(for overlayView: MediaCellProgressView, with media: Media) {
        if media.localThumbnailURL != nil {
            overlayView.backgroundColor = overlayView.backgroundColor?.withAlphaComponent(0.5)
        } else {
            overlayView.backgroundColor = overlayView.backgroundColor?.withAlphaComponent(1)
        }
    }

    private func showUploadingStateForCell(for media: Media) {
        visibleCells(for: media).forEach { cell in
            if let overlayView = cell.overlayView as? MediaCellProgressView {
                overlayView.state = .indeterminate
            }
        }
    }

    private func showFailedStateForCell(for media: Media) {
        visibleCells(for: media).forEach { cell in
            if let overlayView = cell.overlayView as? MediaCellProgressView {
                overlayView.state = .retry
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
        showOptionsMenu()
    }

    private func showMediaPicker() {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.all]
        options.allowCaptureOfMedia = false

        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.dataSource = WPPHAssetDataSource()
        picker.delegate = self

        present(picker, animated: true, completion: nil)
    }

    private func showOptionsMenu() {
        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)

        if WPMediaCapturePresenter.isCaptureAvailable() {
            menuAlert.addDefaultActionWithTitle(NSLocalizedString("Take Photo or Video", comment: "Menu option for taking an image or video with the device's camera.")) { _ in
                self.presentMediaCapture()
            }
        }

        menuAlert.addDefaultActionWithTitle(NSLocalizedString("Photo Library", comment: "Menu option for selecting media from the device's photo library.")) { _ in
            self.showMediaPicker()
        }

        if #available(iOS 11.0, *) {
            menuAlert.addDefaultActionWithTitle(NSLocalizedString("Other Apps", comment: "Menu option used for adding media from other applications.")) { _ in
                self.showDocumentPicker()
            }
        }

        menuAlert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel button"))

        // iPad support
        menuAlert.popoverPresentationController?.sourceView = view
        menuAlert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        present(menuAlert, animated: true, completion: nil)
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
        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Delete", comment: "Title for button that permanently deletes one or more media items (photos / videos)"), handler: { action in
            self.deleteSelectedItems()
        })

        present(alertController, animated: true, completion: nil)
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
        let service = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.deleteMedia(assets, progress: updateProgress, success: { [weak self] () in
            WPAppAnalytics.track(.mediaLibraryDeletedItems, withProperties: ["number_of_items_deleted": deletedItemsCount], with: self?.blog)
            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Deleted!", comment: "Text displayed in HUD after successfully deleting a media item"))
        }, failure: { () in
            SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to delete all media items.", comment: "Text displayed in HUD if there was an error attempting to delete a group of media items."))
        })
    }

    fileprivate func presentRetryOptions(for media: Media) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addDestructiveActionWithTitle(NSLocalizedString("Cancel Upload", comment: "Media Library option to cancel an in-progress or failed upload.")) { _ in
            MediaCoordinator.shared.cancelUploadAndDeleteMedia(media)
        }

        if media.remoteStatus == .failed {
            if let error = media.error {
                alertController.message = error.localizedDescription
            }
            if media.absoluteLocalURL != nil {
                alertController.addDefaultActionWithTitle(NSLocalizedString("Retry Upload", comment: "User action to retry media upload.")) { _ in
                    MediaCoordinator.shared.retryMedia(media)
                }
            } else {
                alertController.addDefaultActionWithTitle(NSLocalizedString("Delete", comment: "User action to delete media.")) { _ in
                    MediaCoordinator.shared.delete(media: media)
                }
            }
        }

        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: ""))

        present(alertController, animated: true, completion: nil)
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

    // MARK: - Upload Coordinator Observer

    private func registerUploadCoordinatorObserver() {
        uploadObserverUUID = MediaCoordinator.shared.addObserver({ [weak self] (media, state) in
            switch state {
            case .progress(let progress) :
                self?.updateCellProgress(progress, for: media)
                break
            case .processing, .uploading:
                self?.showUploadingStateForCell(for: media)
            case .ended:
                self?.reloadCell(for: media)
            case .failed:
                self?.showFailedStateForCell(for: media)
            case .thumbnailReady:
                self?.showUploadingStateForCell(for: media)
            }
            }, for: nil)
    }

    private func unregisterUploadCoordinatorObserver() {
        if let uuid = uploadObserverUUID {
            MediaCoordinator.shared.removeObserver(withUUID: uuid)
        }
    }

    // MARK: - Document Picker

    private func showDocumentPicker() {
        let docTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docPicker.delegate = self
        WPStyleGuide.configureDocumentPickerNavBarAppearance()
        present(docPicker, animated: true, completion: nil)
    }

    // MARK: - Upload Media from Camera

    private func presentMediaCapture() {
        capturePresenter = WPMediaCapturePresenter(presenting: self)
        capturePresenter!.completionBlock = { [weak self] mediaInfo in
            if let mediaInfo = mediaInfo as NSDictionary? {
                self?.processMediaCaptured(mediaInfo)
            }
            self?.capturePresenter = nil
        }

        capturePresenter!.presentCapture()
    }

    private func processMediaCaptured(_ mediaInfo: NSDictionary) {
        let completionBlock: WPMediaAddedBlock = { [weak self] media, error in
            if error != nil || media == nil {
                print("Adding media failed: ", error?.localizedDescription ?? "no media")
                return
            }
            guard let blog = self?.blog,
                let media = media as? PHAsset else {
                return
            }

            MediaCoordinator.shared.addMedia(from: media, to: blog, origin: .mediaLibrary)
        }

        guard let mediaType = mediaInfo[UIImagePickerControllerMediaType] as? String else { return }

        switch mediaType {
        case String(kUTTypeImage):
            if let image = mediaInfo[UIImagePickerControllerOriginalImage] as? UIImage,
                let metadata = mediaInfo[UIImagePickerControllerMediaMetadata] as? [AnyHashable: Any] {
                WPPHAssetDataSource().add(image, metadata: metadata, completionBlock: completionBlock)
            }
        case String(kUTTypeMovie):
            if let mediaURL = mediaInfo[UIImagePickerControllerMediaURL] as? URL {
                WPPHAssetDataSource().addVideo(from: mediaURL, completionBlock: completionBlock)
            }
        default:
            break
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension MediaLibraryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for documentURL in urls as [NSURL] {
            MediaCoordinator.shared.addMedia(from: documentURL, to: blog, origin: .mediaLibrary)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WPNoResultsViewDelegate

extension MediaLibraryViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        addTapped()
    }
}

// MARK: - WPMediaPickerViewControllerDelegate

extension MediaLibraryViewController: WPMediaPickerViewControllerDelegate {

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        return noResultsView
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        updateNoResultsView(for: assetCount)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        // We're only interested in the upload picker
        guard picker != self else { return }
        pickerDataSource.searchCancelled()

        dismiss(animated: true, completion: nil)

        guard ReachabilityUtils.isInternetReachable() else {
            ReachabilityUtils.showAlertNoInternetConnection()
            return
        }

        guard let assets = assets as? [PHAsset],
            assets.count > 0 else { return }

        for asset in assets {
            MediaCoordinator.shared.addMedia(from: asset, to: blog, origin: .mediaLibrary)
        }
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        pickerDataSource.searchCancelled()

        dismiss(animated: true, completion: nil)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, willShowOverlayView overlayView: UIView, forCellFor asset: WPMediaAsset) {
        guard let overlayView = overlayView as? MediaCellProgressView,
            let media = asset as? Media else {
            return
        }
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
        if let media = asset as? Media {
            return media.remoteStatus != .sync
        }

        return false
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
        guard picker == self else {
            return true
        }

        guard let media = asset as? Media else {
            return false
        }

        guard !isEditing else {
            return media.remoteStatus == .sync
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

fileprivate extension Blog {
    var userCanUploadMedia: Bool {
        // Self-hosted non-Jetpack blogs have no capabilities, so we'll just assume that users can post media
        return capabilities != nil ? isUploadingFilesAllowed() : true
    }
}
