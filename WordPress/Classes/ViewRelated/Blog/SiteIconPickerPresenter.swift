import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressShared


/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
class SiteIconPickerPresenter: NSObject {

    /// MARK: - Public Properties

    @objc var blog: Blog
    /// Will be invoked with a Media item from the user library or an error
    @objc var onCompletion: ((Media?, Error?) -> Void)?
    @objc var onIconSelection: (() -> Void)?
    @objc var originalMedia: Media?

    /// MARK: - Private Properties

    fileprivate let noResultsView = MediaNoResultsView()
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

        let pickerViewController = WPNavigationMediaPickerViewController(options: options)

        pickerViewController.dataSource = self.mediaLibraryDataSource
        pickerViewController.delegate = self
        pickerViewController.modalPresentationStyle = .formSheet

        return pickerViewController
    }()

    /// MARK: - Public methods

    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - blog: The current blog.
    ///
    @objc init(blog: Blog) {
        self.blog = blog
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

    /// MARK: - Private Methods

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
    fileprivate func showImageCropViewController(_ image: UIImage) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.maskShape = .square
            imageCropViewController.onCompletion = { [weak self] image, modified in
                self?.onIconSelection?()
                if !modified, let media = self?.originalMedia {
                    self?.onCompletion?(media, nil)
                } else {
                    let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                    guard let blogId = self?.blog.objectID else {
                        self?.onCompletion?(nil, nil)
                        return
                    }
                    mediaService.createMedia(with: image,
                                             objectID: blogId,
                                             progress: nil,
                                             thumbnailCallback: nil,
                                             completion: { (media, error) in
                        guard let media = media, error == nil else {
                            self?.onCompletion?(nil, error)
                            return
                        }
                        var uploadProgress: Progress?
                        mediaService.uploadMedia(media,
                                                 progress: &uploadProgress,
                                                 success: {
                            self?.onCompletion?(media, nil)
                        }, failure: { (error) in
                            self?.onCompletion?(nil, error)
                        })
                    })
                }
            }
            self.mediaPickerViewController.show(after: imageCropViewController)
        }
    }

    fileprivate func registerChangeObserver(forPicker picker: WPMediaPickerViewController) {
        assert(mediaLibraryChangeObserverKey == nil)
        mediaLibraryChangeObserverKey = mediaLibraryDataSource.registerChangeObserverBlock({ [weak self] _, _, _, _, _ in

            self?.updateSearchBar(mediaPicker: picker)

            let isNotSearching = self?.mediaLibraryDataSource.searchQuery?.count ?? 0 != 0
            let hasNoAssets = self?.mediaLibraryDataSource.numberOfAssets() == 0

            if isNotSearching && hasNoAssets {
                self?.noResultsView.updateForNoAssets(userCanUploadMedia: false)
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

extension SiteIconPickerPresenter: WPMediaPickerViewControllerDelegate {

    func mediaPickerControllerWillBeginLoadingData(_ picker: WPMediaPickerViewController) {
        updateSearchBar(mediaPicker: picker)
        noResultsView.updateForFetching()
    }

    func mediaPickerControllerDidEndLoadingData(_ picker: WPMediaPickerViewController) {
        noResultsView.updateForNoAssets(userCanUploadMedia: false)
        updateSearchBar(mediaPicker: picker)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didUpdateSearchWithAssetCount assetCount: Int) {
        if let searchQuery = mediaLibraryDataSource.searchQuery {
            noResultsView.updateForNoSearchResult(with: searchQuery)
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
        mediaLibraryDataSource.searchCancelled()
        if assets.isEmpty {
            return
        }

        let asset = assets.first
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
            let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            mediaService.thumbnailImage(for: media,
                                        preferredSize: CGSize.zero,
                                        completion: { [weak self] (image, error) in
                                            guard let image = image else {
                                                self?.showErrorLoadingImageMessage()
                                                return
                                            }
                                            self?.showImageCropViewController(image)
            })
        default:
            break
        }
    }

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        return noResultsView
    }
}
