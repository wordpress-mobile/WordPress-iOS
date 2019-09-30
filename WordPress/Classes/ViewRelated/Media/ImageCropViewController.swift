import Foundation
import WordPressShared
import UIKit


/// This ViewController allows the user to resize and crop any given UIImage.
///
class ImageCropViewController: UIViewController, UIScrollViewDelegate {
    // MARK: - Public Properties
    /// Will be invoked with the cropped and scaled image and a boolean indicating
    /// whether or not the original image was modified
    @objc var onCompletion: ((UIImage, Bool) -> Void)?
    @objc var onCancel: (() -> Void)?
    @objc var maskShape: ImageCropOverlayMaskShape = .circle
    @objc var shouldShowCancelButton = false

    // MARK: - Public Initializers

    @objc convenience init(image: UIImage) {
        let nibName = ImageCropViewController.classNameWithoutNamespaces()
        self.init(nibName: nibName, bundle: nil)
        rawImage = image
    }


    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Title
        title = NSLocalizedString("Resize & Crop", comment: "Screen title. Resize and crop an image.")

        view.backgroundColor = .basicBackground

        // Setup: NavigationItem
        let useButtonTitle = NSLocalizedString("Use", comment: "Use the current image")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: useButtonTitle,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(cropWasPressed))

        if shouldShowCancelButton {
            let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel the crop")
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: cancelButtonTitle,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancelWasPressed))
        }

        // Setup: ImageView
        imageView.image = rawImage

        // Setup: ScrollView
        let minimumScale = max(scrollView.frame.width / rawImage.size.width, scrollView.frame.height / rawImage.size.height)
        scrollView.minimumZoomScale = minimumScale
        scrollView.maximumZoomScale = minimumScale * maximumScaleFactor
        scrollView.zoomScale = minimumScale

        // Setup: Overlay
        overlayView.borderColor = .primary(.shade40)
        overlayView.outerColor = overlayColor
        overlayView.maskShape = maskShape
    }


    // MARK: - UIScrollViewDelegate Methods

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // NO-OP:
        // Required to enable scrollView Zooming
    }


    // MARK: - Action Handlers
    @IBAction func cropWasPressed() {
        // Calculations!
        let screenScale     = UIScreen.main.scale
        let zoomScale       = scrollView.zoomScale
        let oldSize         = rawImage.size
        let resizeRect      = CGRect(x: 0, y: 0, width: oldSize.width * zoomScale, height: oldSize.height * zoomScale)
        let clippingRect    = CGRect(x: scrollView.contentOffset.x * screenScale,
                                     y: scrollView.contentOffset.y * screenScale,
                                     width: scrollView.frame.width * screenScale,
                                     height: scrollView.frame.height * screenScale)

        if scrollView.contentOffset.x == 0 &&
            scrollView.contentOffset.y == 0 &&
            oldSize.width == clippingRect.width &&
            oldSize.height == clippingRect.height {
            onCompletion?(rawImage, false)
            return
        }

        // Resize
        UIGraphicsBeginImageContextWithOptions(resizeRect.size, false, screenScale)
        rawImage?.draw(in: resizeRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Crop
        guard let clippedImageRef = scaledImage!.cgImage!.cropping(to: clippingRect.integral) else {
            return
        }

        let clippedImage = UIImage(cgImage: clippedImageRef, scale: screenScale, orientation: .up)
        onCompletion?(clippedImage, true)
    }

    @IBAction func cancelWasPressed() {
        onCancel?()
    }

    private let overlayColor = UIColor.basicBackground.withAlphaComponent(0.78)

    // MARK: - Private Constants
    private let maximumScaleFactor  = CGFloat(3)

    // MARK: - Private Properties
    private var rawImage: UIImage!

    // MARK: - IBOutlets
    @IBOutlet private var scrollView: UIScrollView! {
        didSet {
            scrollView.backgroundColor = .basicBackground
        }
    }
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var overlayView: ImageCropOverlayView!
    @IBOutlet private var topView: UIView! {
        didSet {
            topView.backgroundColor = overlayColor
        }
    }
    @IBOutlet private var bottomView: UIView! {
        didSet {
            bottomView.backgroundColor = overlayColor
        }
    }
    @IBOutlet private var rightView: UIView! {
        didSet {
            rightView.backgroundColor = overlayColor
        }
    }
    @IBOutlet private var leftView: UIView! {
        didSet {
            leftView.backgroundColor = overlayColor
        }
    }
}
