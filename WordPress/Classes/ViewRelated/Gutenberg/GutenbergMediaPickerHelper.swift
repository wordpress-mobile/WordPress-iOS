import Foundation
import CoreServices
import UIKit
import Photos
import WordPressShared
import WPMediaPicker
import Gutenberg

public typealias GutenbergMediaPickerHelperCallback = ([WPMediaAsset]?) -> Void

class GutenbergMediaPickerHelper: NSObject {

    fileprivate struct Constants {
        static let mediaPickerInsertText = NSLocalizedString(
            "Insert %@",
            comment: "Button title used in media picker to insert media (photos / videos) into a post. Placeholder will be the number of items that will be inserted."
        )
    }

    fileprivate let post: AbstractPost
    fileprivate unowned let context: UIViewController
    fileprivate weak var navigationPicker: WPNavigationMediaPickerViewController?
    fileprivate let noResultsView = NoResultsViewController.controller()

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: MediaLibraryPickerDataSource = {
        let dataSource = MediaLibraryPickerDataSource(post: self.post)
        dataSource.ignoreSyncErrors = true
        return dataSource
    }()

    /// Device Photo Library Data Source
    ///
    fileprivate lazy var devicePhotoLibraryDataSource = WPPHAssetDataSource()

    var didPickMediaCallback: GutenbergMediaPickerHelperCallback?

    init(context: UIViewController, post: AbstractPost) {
        self.context = context
        self.post = post
    }

    func presentMediaPickerFullScreen(animated: Bool,
                                      filter: WPMediaType,
                                      dataSourceType: MediaPickerDataSourceType = .device,
                                      allowMultipleSelection: Bool,
                                      callback: @escaping GutenbergMediaPickerHelperCallback) {

        didPickMediaCallback = callback

        let mediaPickerOptions = WPMediaPickerOptions.withDefaults(filter: filter, allowMultipleSelection: allowMultipleSelection)
        let picker = WPNavigationMediaPickerViewController(options: mediaPickerOptions)
        navigationPicker = picker
        switch dataSourceType {
        case .device:
            picker.dataSource = devicePhotoLibraryDataSource
        case .mediaLibrary:
            picker.startOnGroupSelector = false
            picker.showGroupSelector = false
            picker.dataSource = mediaLibraryDataSource
        @unknown default:
            fatalError()
        }

        picker.selectionActionTitle = Constants.mediaPickerInsertText
        picker.mediaPicker.options = mediaPickerOptions
        picker.delegate = self
        picker.mediaPicker.registerClass(forReusableCellOverlayViews: DisabledVideoOverlay.self)

        if FeatureFlag.mediaPickerPermissionsNotice.enabled {
            picker.mediaPicker.registerClass(forCustomHeaderView: DeviceMediaPermissionsHeader.self)
        }

        picker.previewActionTitle = NSLocalizedString("Edit %@", comment: "Button that displays the media editor to the user")
        picker.modalPresentationStyle = .currentContext
        context.present(picker, animated: true)
    }

    private lazy var cameraPicker: WPMediaPickerViewController = {
        let cameraPicker = WPMediaPickerViewController()
        cameraPicker.options = WPMediaPickerOptions.withDefaults()
        cameraPicker.mediaPickerDelegate = self
        cameraPicker.dataSource = WPPHAssetDataSource.sharedInstance()
        return cameraPicker
    }()

    func presentCameraCaptureFullScreen(animated: Bool,
                                        filter: WPMediaType,
                                        callback: @escaping GutenbergMediaPickerHelperCallback) {

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            callback(nil)
            return
        }

        didPickMediaCallback = callback
        //reset the selected assets from previous uses
        cameraPicker.resetState(false)
        cameraPicker.modalPresentationStyle = .currentContext
        cameraPicker.viewControllerToUseToPresent = context
        cameraPicker.options.filter = filter
        cameraPicker.options.allowMultipleSelection = false
        cameraPicker.showCapture()
    }
}

// MARK: - User messages for video limits allowances
//
extension GutenbergMediaPickerHelper: VideoLimitsAlertPresenter {}

// MARK: - Picker Delegate
//
extension GutenbergMediaPickerHelper: WPMediaPickerViewControllerDelegate {

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        if picker == cameraPicker,
           let asset = assets.first,
           !post.blog.canUploadAsset(asset) {
                presentVideoLimitExceededAfterCapture(on: self.context)
        } else {
            invokeMediaPickerCallback(asset: assets)
            picker.dismiss(animated: true, completion: nil)
        }
    }

    open func mediaPickerController(_ picker: WPMediaPickerViewController, handleError error: Error) -> Bool {
        let presenter = context.topmostPresentedViewController
        let alert = WPMediaPickerAlertHelper.buildAlertControllerWithError(error)
        presenter.present(alert, animated: true)
        return true
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        mediaLibraryDataSource.searchCancelled()
        context.dismiss(animated: true, completion: { self.invokeMediaPickerCallback(asset: nil) })
    }

    func mediaPickerControllerShouldShowCustomHeaderView(_ picker: WPMediaPickerViewController) -> Bool {
        guard FeatureFlag.mediaPickerPermissionsNotice.enabled,
              picker !== cameraPicker else {
            return false
        }

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

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShowOverlayViewForCellFor asset: WPMediaAsset) -> Bool {
        picker !== cameraPicker && !post.blog.canUploadAsset(asset)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldSelect asset: WPMediaAsset) -> Bool {
        if picker !== cameraPicker,
            !post.blog.canUploadAsset(asset) {

            presentVideoLimitExceededFromPicker(on: picker)
            return false
        }
        return true
    }

    fileprivate func invokeMediaPickerCallback(asset: [WPMediaAsset]?) {
        didPickMediaCallback?(asset)
        didPickMediaCallback = nil
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, previewViewControllerFor assets: [WPMediaAsset], selectedIndex selected: Int) -> UIViewController? {
        if let phAssets = assets as? [PHAsset], phAssets.allSatisfy({ $0.mediaType == .image }) {
            edit(fromMediaPicker: picker, assets: phAssets)
            return nil
        }

        return nil
    }

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        guard picker == navigationPicker?.mediaPicker else {
            return nil
        }
        return noResultsView
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        if (mediaLibraryDataSource.searchQuery?.count ?? 0) > 0 {
            noResultsView.configureForNoSearchResult()
        } else {
            noResultsView.removeFromView()
        }
    }

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        noResultsView.configureForFetching()
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        noResultsView.removeFromView()
        noResultsView.configureForNoAssets(userCanUploadMedia: false)
    }

}

// MARK: - Media Editing
//
extension GutenbergMediaPickerHelper {
        private func edit(fromMediaPicker picker: WPMediaPickerViewController, assets: [PHAsset]) {
            let mediaEditor = WPMediaEditor(assets)

            // When the photo's library is updated (eg.: a new photo is added)
            // the actionBar is appearing and conflicting with Media Editor.
            // We hide it to prevent that issue
            picker.actionBar?.isHidden = true

            mediaEditor.edit(from: picker,
                                  onFinishEditing: { [weak self] images, actions in
                                    guard let images = images as? [PHAsset] else {
                                        return
                                    }

                                    self?.didPickMediaCallback?(images)
                                    self?.context.dismiss(animated: false)
                }, onCancel: {
                    // Dismiss the Preview screen in Media Picker
                    picker.navigationController?.popViewController(animated: false)

                    // Show picker actionBar again
                    picker.actionBar?.isHidden = false
            })
        }
}

fileprivate extension WPMediaPickerOptions {
    static func withDefaults(
        showMostRecentFirst: Bool = true,
        filter: WPMediaType = [.image],
        allowCaptureOfMedia: Bool = false,
        showSearchBar: Bool = true,
        badgedUTTypes: Set<String> = [String(kUTTypeGIF)],
        allowMultipleSelection: Bool = false,
        preferredStatusBarStyle: UIStatusBarStyle = WPStyleGuide.preferredStatusBarStyle
    ) -> WPMediaPickerOptions {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = showMostRecentFirst
        options.filter = filter
        options.allowCaptureOfMedia = allowCaptureOfMedia
        options.showSearchBar = showSearchBar
        options.badgedUTTypes = badgedUTTypes
        options.allowMultipleSelection = allowMultipleSelection
        options.preferredStatusBarStyle = preferredStatusBarStyle

        return options
    }
}
