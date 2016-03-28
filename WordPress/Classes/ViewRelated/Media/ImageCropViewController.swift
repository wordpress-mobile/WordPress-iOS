import Foundation


///
///
class ImageCropViewController : UIViewController, UIScrollViewDelegate
{
    // MARK: - Public Initializers
    
    convenience init(image: UIImage) {
        let nibName = ImageCropViewController.classNameWithoutNamespaces()
        self.init(nibName: nibName, bundle: nil)
        rawImage = image
    }
    
    
    // MARK: - UIViewController Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = rawImage
        
        // Setup the ScrollView
        let minimumScale = max(scrollView.frame.width / rawImage.size.width, scrollView.frame.height / rawImage.size.height)
        scrollView.minimumZoomScale = minimumScale
        scrollView.maximumZoomScale = minimumScale * 3
        scrollView.zoomScale = minimumScale
    }
    
    
    // MARK: - UIScrollViewDelegate Methods
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        
    }
    
    
    // MARK: - Private Properties
    private var rawImage                : UIImage!
    
    // MARK: - IBOutlets
    @IBOutlet private var scrollView    : UIScrollView!
    @IBOutlet private var imageView     : UIImageView!
}
