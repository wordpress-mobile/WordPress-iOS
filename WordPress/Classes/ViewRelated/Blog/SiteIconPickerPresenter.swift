import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressComAnalytics


/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
class SiteIconPickerPresenter: NSObject {

    /// MARK: - Public Properties

    var presentingViewController: UIViewController
    var blog: Blog
    var onCompletion: ((UIImage?) -> Void)?

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
    ///     - presentingViewController: The UIViewController that will present the picker.
    ///     - blog: The current blog.
    ///
    init(presentingViewController: UIViewController, blog: Blog) {
        self.presentingViewController = presentingViewController
        self.blog = blog
        super.init()
    }

    /// Presents a new WPMediaPickerViewController instance.
    ///
    func presentPicker() {
        presentingViewController.present(mediaPickerViewController, animated: true)
    }

    /// MARK: - Private Methods

    fileprivate func showLoadingMessage() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading...",
                                                         comment: "Text displayed in HUD while a media item's is being loaded."))
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
            imageCropViewController.onCompletion = { [weak self] image in
                self?.onCompletion?(image)
                self?.presentingViewController.dismiss(animated: true, completion: nil)
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
        onCompletion?(nil)
        self.presentingViewController.dismiss(animated: true, completion: nil)
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
            phAsset.exportMaximumSizeImage { [weak self] (image, info) in
                guard let image = image else {
                    self?.showErrorLoadingImageMessage()
                    return
                }
                self?.showImageCropViewController(image)
            }
        case let media as Media:
            showLoadingMessage()
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
