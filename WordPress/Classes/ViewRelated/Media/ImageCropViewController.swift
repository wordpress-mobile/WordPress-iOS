import Foundation
import WordPressShared
import UIKit


/// This ViewController allows the user to resize and crop any given UIImage.
///
class ImageCropViewController : UIViewController, UIScrollViewDelegate
{
    // MARK: - Public Properties
    var onCompletion: (UIImage -> Void)?


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
                                                            style: .Plain,
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
        overlayView.borderColor = WPStyleGuide.newKidOnTheBlockBlue()
    }


    // MARK: - UIScrollViewDelegate Methods

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        // NO-OP:
        // Required to enable scrollView Zooming
    }


    // MARK: - Action Handlers
    @IBAction func btnCropWasPressed() {
        // Calculations!
        let screenScale     = UIScreen.mainScreen().scale
        let zoomScale       = scrollView.zoomScale
        let oldSize         = rawImage.size
        let resizeRect      = CGRect(x: 0, y: 0, width: oldSize.width * zoomScale, height: oldSize.height * zoomScale)
        let clippingRect    = CGRect(x: scrollView.contentOffset.x * screenScale,
                                     y: scrollView.contentOffset.y * screenScale,
                                     width: scrollView.frame.width * screenScale,
                                     height: scrollView.frame.height * screenScale)

        // Resize
        UIGraphicsBeginImageContextWithOptions(resizeRect.size, false, screenScale)
        rawImage?.drawInRect(resizeRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Crop
        guard let clippedImageRef = CGImageCreateWithImageInRect(scaledImage.CGImage, clippingRect.integral) else {
            return
        }

        let clippedImage = UIImage(CGImage: clippedImageRef, scale: screenScale, orientation: .Up)
        onCompletion?(clippedImage)
    }


    // MARK: - Private Constants
    private let maximumScaleFactor  = CGFloat(3)

    // MARK: - Private Properties
    private var rawImage                : UIImage!

    // MARK: - IBOutlets
    @IBOutlet private var scrollView    : UIScrollView!
    @IBOutlet private var imageView     : UIImageView!
    @IBOutlet private var overlayView   : GravatarOverlayView!
}
