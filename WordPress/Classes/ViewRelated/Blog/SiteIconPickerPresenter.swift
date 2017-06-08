import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressComAnalytics


/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
class SiteIconPickerPresenter: NSObject {

    /// MARK: - Public Properties

    var blog: Blog
    /// Will be invoked with a newly created image OR an existing media item to set
    /// as the site icon
    var onCompletion: ((Media?, Error?) -> Void)?
    var onIconSelection: (() -> Void)?
    var originalMedia: Media?

    /// MARK: - Private Properties

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: WPAndDeviceMediaLibraryDataSource = {
        return WPAndDeviceMediaLibraryDataSource(blog: self.blog)
    }()

    /// Media Picker View Controller
    ///
    fileprivate lazy var mediaPickerViewController: WPNavigationMediaPickerViewController = {
        let pickerViewController = WPNavigationMediaPickerViewController()

        pickerViewController.dataSource = self.mediaLibraryDataSource
        pickerViewController.showMostRecentFirst = true
        pickerViewController.allowMultipleSelection = false
        pickerViewController.filter = WPMediaType.image
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
    init(blog: Blog) {
        self.blog = blog
        super.init()
    }

    /// Presents a new WPMediaPickerViewController instance.
    ///
    func presentPickerFrom(_ viewController: UIViewController) {
        viewController.present(mediaPickerViewController, animated: true)
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
                    let mediaService = MediaService(managedObjectContext:ContextManager.sharedInstance().mainContext)
                    guard let blogId = self?.blog.objectID else {
                        self?.onCompletion?(nil, nil)
                        return
                    }
                    mediaService.createMedia(with: image,
                                             forBlogObjectID: blogId,
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
}

extension SiteIconPickerPresenter: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion?(nil, nil)
    }

    /// Retrieves the chosen image and triggers the ImageCropViewController display.
    ///
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPickingAssets assets: [Any]) {
        if assets.isEmpty {
            return
        }

        let asset = assets.first
        switch asset {
        case let phAsset as PHAsset:
            showLoadingMessage()
            originalMedia = nil
            phAsset.exportMaximumSizeImage { [weak self] (image, info) in
                guard let image = image else {
                    self?.showErrorLoadingImageMessage()
                    return
                }
                self?.showImageCropViewController(image)
            }
        case let media as Media:
            showLoadingMessage()
            originalMedia = media
            let mediaService = MediaService(managedObjectContext:ContextManager.sharedInstance().mainContext)
            mediaService.image(for: media, size: CGSize.zero, success: { [weak self] image in
                self?.showImageCropViewController(image)
            }, failure: { [weak self] _ in
                self?.showErrorLoadingImageMessage()
            })
        default:
            break
        }
    }
}
