import Foundation
import WPMediaPicker
import WordPressShared
import Photos
import MobileCoreServices
import UniformTypeIdentifiers

// Encapsulates all of the interactions required to capture a new Gravatar image, and resize it.
//
class GravatarPickerViewController: UIViewController, WPMediaPickerViewControllerDelegate {
    // MARK: - Public Properties

    @objc var onCompletion: ((UIImage?) -> Void)?

    // MARK: - Private Properties

    fileprivate var mediaPickerViewController: WPNavigationMediaPickerViewController!

    fileprivate lazy var mediaPickerAssetDataSource = WPPHAssetDataSource()

    // MARK: - View Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildrenViewControllers()
    }


    // MARK: - WPMediaPickerViewControllerDelegate

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        // Export the UIImage Asset
        guard let asset = assets.first as? PHAsset else {
            onCompletion?(nil)
            return
        }

        let exporter = MediaAssetExporter(asset: asset)
        exporter.imageOptions = MediaImageExporter.Options()

        exporter.export(onCompletion: { [weak self](assetExport) in
            guard let strongSelf = self else {
                return
            }
            guard let rawGravatar = UIImage(contentsOfFile: assetExport.url.path) else {
                strongSelf.onCompletion?(nil)
                return
            }

            // Track
            WPAppAnalytics.track(.gravatarCropped)

            // Proceed Cropping
            let imageCropViewController = strongSelf.newImageCropViewController(rawGravatar)
            strongSelf.mediaPickerViewController.show(after: imageCropViewController)

            }, onError: { [weak self](error) in
                self?.onCompletion?(nil)
        })
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion?(nil)
    }

    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        let noResultsView = NoResultsViewController.controller()
        noResultsView.configureForNoAssets(userCanUploadMedia: false)
        return noResultsView
    }

    // MARK: - Private Methods

    // Instantiates a new MediaPickerViewController, and sets it up as a children ViewController.
    //
    fileprivate func setupChildrenViewControllers() {
        let pickerViewController = newMediaPickerViewController()

        pickerViewController.willMove(toParent: self)
        pickerViewController.view.bounds = view.bounds
        view.addSubview(pickerViewController.view)
        addChild(pickerViewController)
        pickerViewController.didMove(toParent: self)

        mediaPickerViewController = pickerViewController
    }

    // Returns a new WPMediaPickerViewController instance.
    //
    fileprivate func newMediaPickerViewController() -> WPNavigationMediaPickerViewController {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.preferFrontCamera = true
        options.allowMultipleSelection = false
        options.badgedUTTypes = [UTType.gif.identifier]
        options.preferredStatusBarStyle = WPStyleGuide.preferredStatusBarStyle

        let pickerViewController = WPNavigationMediaPickerViewController(options: options)
        pickerViewController.delegate = self
        pickerViewController.dataSource = mediaPickerAssetDataSource
        pickerViewController.startOnGroupSelector = false
        return pickerViewController
    }

    // Returns a new ImageCropViewController instance.
    //
    fileprivate func newImageCropViewController(_ rawGravatar: UIImage) -> ImageCropViewController {
        let imageCropViewController = ImageCropViewController(image: rawGravatar)
        imageCropViewController.onCompletion = { [weak self] image, _ in
            self?.onCompletion?(image)
            self?.dismiss(animated: true)
        }

        return imageCropViewController
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WPStyleGuide.preferredStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        return nil
    }

}
