import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressComAnalytics


/// Encapsulates the interactions required to capture a new site icon image, cropt it and resize it.
///
class SiteIconPickerViewController: UIViewController, WPMediaPickerViewControllerDelegate {
    /// MARK: - Public Properties

    var onCompletion: ((UIImage?) -> Void)?
    var blog: Blog

    /// MARK: - Private Properties

    /// Media Picker View Controller
    ///
    fileprivate var mediaPickerViewController: WPNavigationMediaPickerViewController!

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: WPAndDeviceMediaLibraryDataSource = {
        return WPAndDeviceMediaLibraryDataSource(blog: self.blog)
    }()

    /// MARK: - View Lifecycle Methods

    init(blog: Blog) {
        self.blog = blog
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildrenViewControllers()
    }


    /// MARK: - WPMediaPickerViewControllerDelegate

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion?(nil)
    }

    /// Retrieves the chosen image and triggers the ImageCropViewController display
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
            break
        case let media as Media:
            showLoadingMessage()
            let mediaService = MediaService(managedObjectContext:ContextManager.sharedInstance().mainContext)
            mediaService.image(for: media, size: CGSize.zero, success: { [weak self] image in
                self?.showImageCropViewController(image)
            }, failure: { [weak self] _ in
                self?.showErrorLoadingImageMessage()
            })
            break
        default:
            break
        }
    }

    /// MARK: - Private Methods

    fileprivate func showLoadingMessage() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading...",
                                                         comment: "Text displayed in HUD while a media item's is being laoded."))
    }

    fileprivate func showErrorLoadingImageMessage() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Unable to load the image, please chose a different one or try again later.",
                                                                         comment: "Text displayed in HUD if there was an error attempting to load a media image."))
    }

    /// Instantiates a new MediaPickerViewController, and sets it up as a children ViewController.
    ///
    fileprivate func setupChildrenViewControllers() {
        let pickerViewController = newMediaPickerViewController()

        pickerViewController.willMove(toParentViewController: self)
        pickerViewController.view.bounds = view.bounds
        view.addSubview(pickerViewController.view)
        addChildViewController(pickerViewController)
        pickerViewController.didMove(toParentViewController: self)

        mediaPickerViewController = pickerViewController
    }

    /// Returns a new WPMediaPickerViewController instance.
    ///
    fileprivate func newMediaPickerViewController() -> WPNavigationMediaPickerViewController {
        let pickerViewController = WPNavigationMediaPickerViewController()

        pickerViewController.delegate = self
        pickerViewController.showMostRecentFirst = true
        pickerViewController.allowMultipleSelection = false
        pickerViewController.filter = .image
        pickerViewController.dataSource = mediaLibraryDataSource

        return pickerViewController
    }

    /// Shows a new ImageCropViewController for the given image.
    ///
    fileprivate func showImageCropViewController(_ image: UIImage) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.square = true
            imageCropViewController.onCompletion = { [weak self] image in
                self?.onCompletion?(image)
                self?.dismiss(animated: true, completion: nil)
            }
            self.mediaPickerViewController.show(after: imageCropViewController)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }

}
