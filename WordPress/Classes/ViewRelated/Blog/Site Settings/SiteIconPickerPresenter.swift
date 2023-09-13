import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressShared
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
final class SiteIconPickerPresenter: NSObject {

    // MARK: - Public Properties

    @objc var blog: Blog
    /// Will be invoked with a Media item from the user library or an error
    @objc var onCompletion: ((Media?, Error?) -> Void)?
    @objc var onIconSelection: (() -> Void)?
    @objc var originalMedia: Media?

    // MARK: - Private Properties

    fileprivate let noResultsView = NoResultsViewController.controller()
    fileprivate var mediaLibraryChangeObserverKey: NSObjectProtocol? = nil

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: WPAndDeviceMediaLibraryDataSource = {
        return WPAndDeviceMediaLibraryDataSource(blog: self.blog)
    }()

    /// Media Picker View Controller
    ///
    fileprivate lazy var mediaPickerViewController: WPNavigationMediaPickerViewController = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.allowMultipleSelection = false
        options.showSearchBar = true
        options.badgedUTTypes = [UTType.gif.identifier]
        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle

        let pickerViewController = WPNavigationMediaPickerViewController(options: options)

        pickerViewController.dataSource = self.mediaLibraryDataSource
        pickerViewController.delegate = self
        pickerViewController.modalPresentationStyle = .formSheet

        return pickerViewController
    }()

    private var dataSource: AnyObject?
    private var mediaCapturePresenter: AnyObject?

    // MARK: - Public methods

    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - blog: The current blog.
    ///
    @objc init(blog: Blog) {
        self.blog = blog
        noResultsView.configureForNoAssets(userCanUploadMedia: false)
        super.init()
    }

    deinit {
        unregisterChangeObserver()
    }

    /// Presents a new WPMediaPickerViewController instance.
    ///
    @objc func presentPickerFrom(_ viewController: UIViewController) {
        viewController.present(mediaPickerViewController, animated: true)
        registerChangeObserver(forPicker: mediaPickerViewController.mediaPicker)
    }

    // MARK: - Private Methods

    fileprivate func showLoadingMessage() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading...",
                                                         comment: "Text displayed in HUD while a media item is being loaded."))
    }

    fileprivate func showErrorLoadingImageMessage() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Unable to load the image. Please choose a different one or try again later.",
                                                                         comment: "Text displayed in HUD if there was an error attempting to load a media image."))
    }

    /// Shows a new ImageCropViewController for the given image.
    ///
    func showImageCropViewController(_ image: UIImage, presentingViewController: UIViewController? = nil) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.maskShape = .square
            imageCropViewController.onCompletion = { [weak self] image, modified in
                guard let self = self else {
                    return
                }
                self.onIconSelection?()
                if !modified, let media = self.originalMedia {
                    self.onCompletion?(media, nil)
                } else {
                    let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                    let importService = MediaImportService(coreDataStack: ContextManager.sharedInstance())

                    WPAnalytics.track(.siteSettingsSiteIconCropped)

                    importService.createMedia(
                        with: image,
                        blog: self.blog,
                        post: nil,
                        receiveUpdate: nil,
                        thumbnailCallback: nil
                    ) { (media, error) in
                        guard let media = media, error == nil else {
                            WPAnalytics.track(.siteSettingsSiteIconUploadFailed)
                            self.onCompletion?(nil, error)
                            return
                        }
                        var uploadProgress: Progress?
                        mediaService.uploadMedia(media,
                                                 automatedRetry: false,
                                                 progress: &uploadProgress,
                                                 success: {
                            WPAnalytics.track(.siteSettingsSiteIconUploaded)
                            self.onCompletion?(media, nil)
                        }, failure: { (error) in
                            WPAnalytics.track(.siteSettingsSiteIconUploadFailed)
                            self.onCompletion?(nil, error)
                        })
                    }
                }
            }
            if let presentingViewController {
                imageCropViewController.shouldShowCancelButton = true
                imageCropViewController.onCancel = { [weak presentingViewController] in
                    // Dismiss the crop controller but not the picker
                    presentingViewController?.dismiss(animated: true)
                }
                let navigationController = UINavigationController(rootViewController: imageCropViewController)
                presentingViewController.present(navigationController, animated: true)
            } else {
                self.mediaPickerViewController.show(after: imageCropViewController)
            }
        }
    }

    fileprivate func registerChangeObserver(forPicker picker: WPMediaPickerViewController) {
        assert(mediaLibraryChangeObserverKey == nil)
        mediaLibraryChangeObserverKey = mediaLibraryDataSource.registerChangeObserverBlock({ [weak self] _, _, _, _, _ in

            self?.updateSearchBar(mediaPicker: picker)

            let isNotSearching = self?.mediaLibraryDataSource.searchQuery?.count ?? 0 != 0
            let hasNoAssets = self?.mediaLibraryDataSource.numberOfAssets() == 0

            if isNotSearching && hasNoAssets {
                self?.noResultsView.removeFromView()
                self?.noResultsView.configureForNoAssets(userCanUploadMedia: false)
            }
        })
    }

    fileprivate func unregisterChangeObserver() {
        if let mediaLibraryChangeObserverKey = mediaLibraryChangeObserverKey {
            mediaLibraryDataSource.unregisterChangeObserver(mediaLibraryChangeObserverKey)
        }
        mediaLibraryChangeObserverKey = nil
    }

    fileprivate func updateSearchBar(mediaPicker: WPMediaPickerViewController) {
        let isSearching = mediaLibraryDataSource.searchQuery?.count ?? 0 != 0
        let hasAssets = mediaLibraryDataSource.numberOfAssets() > 0

        if mediaLibraryDataSource.dataSourceType == .mediaLibrary && (isSearching || hasAssets) {
            mediaPicker.showSearchBar()
            if let searchBar = mediaPicker.searchBar {
                WPStyleGuide.configureSearchBar(searchBar)
            }
        } else {
            mediaPicker.hideSearchBar()
        }
    }
}

extension SiteIconPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let presentingViewController = picker.presentingViewController else {
            return
        }
        presentingViewController.dismiss(animated: true)

        guard let result = results.first else {
            return
        }
        WPAnalytics.track(.siteSettingsSiteIconGalleryPicked)
        self.originalMedia = nil
        PHPickerResult.loadImage(for: result) { [weak self] image, error in
            if let image {
                self?.showImageCropViewController(image, presentingViewController: presentingViewController)
            } else {
                DDLogError("Failed to load image: \(String(describing: error))")
                self?.showErrorLoadingImageMessage()
            }
        }
    }
}

extension SiteIconPickerPresenter: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let presentingViewController = picker.presentingViewController else {
            return
        }
        presentingViewController.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.showImageCropViewController(image, presentingViewController: presentingViewController)
            }
        }
    }
}

extension SiteIconPickerPresenter: WPMediaPickerViewControllerDelegate {

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.configureForFetching()
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        noResultsView.removeFromView()
        noResultsView.configureForNoAssets(userCanUploadMedia: false)
        updateSearchBar(mediaPicker: picker)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        noResultsView.removeFromView()

        if (mediaLibraryDataSource.searchQuery?.count ?? 0) > 0 {
            noResultsView.configureForNoSearchResult()
        }
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        mediaLibraryDataSource.searchCancelled()
        onCompletion?(nil, nil)
    }

    /// Retrieves the chosen image and triggers the ImageCropViewController display.
    ///
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        dataSource = nil
        mediaLibraryDataSource.searchCancelled()
        if assets.isEmpty {
            return
        }

        let asset = assets.first

        WPAnalytics.track(.siteSettingsSiteIconGalleryPicked)

        switch asset {
        case let phAsset as PHAsset:
            showLoadingMessage()
            originalMedia = nil
            let exporter = MediaAssetExporter(asset: phAsset)
            exporter.imageOptions = MediaImageExporter.Options()

            exporter.export(onCompletion: { [weak self](assetExport) in
                guard let image = UIImage(contentsOfFile: assetExport.url.path) else {
                    self?.showErrorLoadingImageMessage()
                    return
                }
                self?.showImageCropViewController(image)

            }, onError: { [weak self](error) in
                self?.showErrorLoadingImageMessage()
            })
        case let media as Media:
            showLoadingMessage()
            originalMedia = media
            MediaThumbnailCoordinator.shared.thumbnail(for: media, with: CGSize.zero, onCompletion: { [weak self] (image, error) in
                guard let image = image else {
                    self?.showErrorLoadingImageMessage()
                    return
                }
                if FeatureFlag.nativePhotoPicker.enabled {
                    self?.showImageCropViewController(image, presentingViewController: picker)
                } else {
                    self?.showImageCropViewController(image)
                }
            })
        default:
            break
        }
    }

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        return noResultsView
    }
}
