import Foundation
import WPMediaPicker
import WordPressComAnalytics


// Encapsulates all of the interactions required to capture a new Gravatar image, and resize it.
//
class GravatarPickerViewController : UIViewController, WPMediaPickerViewControllerDelegate
{
    // MARK: - Public Properties

    var onCompletion : (UIImage? -> Void)?


    // MARK: - View Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildrenViewControllers()
    }


    // MARK: - WPMediaPickerViewControllerDelegate

    func mediaPickerController(picker: WPMediaPickerViewController, shouldShowAsset asset: WPMediaAsset) -> Bool {
        return asset.isKindOfClass(PHAsset)
    }

    func mediaPickerController(picker: WPMediaPickerViewController, didFinishPickingAssets assets: [AnyObject]) {
        // Export the UIImage Asset
        guard let asset = assets.first as? PHAsset else {
            onCompletion?(nil)
            return
        }

        asset.exportMaximumSizeImage { (image, info) in
            guard let rawGravatar = image else {
                self.onCompletion?(nil)
                return
            }

            // Track
            WPAppAnalytics.track(.GravatarCropped)

            // Proceed Cropping
            let imageCropViewController = self.newImageCropViewController(rawGravatar)
            picker.showAfterViewController(imageCropViewController)
        }
    }

    func mediaPickerControllerDidCancel(picker: WPMediaPickerViewController) {
        onCompletion?(nil)
    }


    // MARK: - Private Methods

    // Instantiates a new MediaPickerViewController, and sets it up as a children ViewController.
    //
    private func setupChildrenViewControllers() {
        let pickerViewController = newMediaPickerViewController()

        pickerViewController.willMoveToParentViewController(self)
        pickerViewController.view.bounds = view.bounds
        view.addSubview(pickerViewController.view)
        addChildViewController(pickerViewController)
        pickerViewController.didMoveToParentViewController(self)
    }

    // Returns a new WPMediaPickerViewController instance.
    //
    private func newMediaPickerViewController() -> WPMediaPickerViewController {
        let pickerViewController = WPMediaPickerViewController()
        pickerViewController.delegate = self
        pickerViewController.showMostRecentFirst = true
        pickerViewController.allowMultipleSelection = false
        pickerViewController.filter = .Image

        return pickerViewController
    }

    // Returns a new ImageCropViewController instance.
    //
    private func newImageCropViewController(rawGravatar: UIImage) -> ImageCropViewController {
        let imageCropViewController = ImageCropViewController(image: rawGravatar)
        imageCropViewController.onCompletion = { [weak self] image in
            self?.onCompletion?(image)
            self?.dismissViewControllerAnimated(true, completion: nil)
        }

        return imageCropViewController
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }

}
