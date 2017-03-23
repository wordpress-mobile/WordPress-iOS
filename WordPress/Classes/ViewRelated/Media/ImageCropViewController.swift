import Foundation
import WordPressShared
import UIKit


/// This ViewController allows the user to resize and crop any given UIImage.
///
class ImageCropViewController: UIViewController, UIScrollViewDelegate {
    // MARK: - Public Properties
    var onCompletion: ((UIImage) -> Void)?


    // MARK: - Public Initializers

    convenience init(image: UIImage) {
        let nibName = ImageCropViewController.classNameWithoutNamespaces()
        self.init(nibName: nibName, bundle: nil)
        rawImage = image
    }


    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Title
        title = NSLocalizedString("Resize & Crop", comment: "")

        // Setup: NavigationItem
        let useButtonTitle = NSLocalizedString("Use", comment: "Use the current image as Gravatar")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: useButtonTitle,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(btnCropWasPressed))

        // Setup: ImageView
        imageView.image = rawImage

        // Setup: ScrollView
        let minimumScale = max(scrollView.frame.width / rawImage.size.width, scrollView.frame.height / rawImage.size.height)
        scrollView.minimumZoomScale = minimumScale
        scrollView.maximumZoomScale = minimumScale * maximumScaleFactor
        scrollView.zoomScale = minimumScale

        // Setup: Overlay
        overlayView.borderColor = WPStyleGuide.mediumBlue()
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
    @IBAction func btnCropWasPressed() {
        // Calculations!
        let screenScale     = UIScreen.main.scale
        let zoomScale       = scrollView.zoomScale
        let oldSize         = rawImage.size
        let resizeRect      = CGRect(x: 0, y: 0, width: oldSize.width * zoomScale, height: oldSize.height * zoomScale)
        let clippingRect    = CGRect(x: scrollView.contentOffset.x * screenScale,
                                     y: scrollView.contentOffset.y * screenScale,
                                     width: scrollView.frame.width * screenScale,
                                     height: scrollView.frame.height * screenScale)

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
        onCompletion?(clippedImage)
    }


    // MARK: - Private Constants
    fileprivate let maximumScaleFactor  = CGFloat(3)

    // MARK: - Private Properties
    fileprivate var rawImage: UIImage!

    // MARK: - IBOutlets
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var overlayView: GravatarOverlayView!
}
