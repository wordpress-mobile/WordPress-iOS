import UIKit

class WPGalleryPageViewController: UIPageViewController {

    // MARK: - Properties
    let largeImageKey = "data-large-file"
    var images = [WPTextAttachment]()
    var initialIndex = 0
    var currentVC : WPImageViewController?
    var imageViewControllers = [WPImageViewController : Int]()

    // MARK: - Convenience Factories


    /// Convenience method for instantiating an instance of WPGalleryPageViewController
    /// for a particular topic.
    ///
    /// - Parameters:
    ///     - images:  Array of images to be displayed.
    ///     - selectedIndex: Index of image selected by user
    ///
    /// - Return: A WPGalleryPageViewController instance.
    ///
    open class func controllerWithImages(with images: [WPTextAttachment], selectedIndex: Int) -> WPGalleryPageViewController {

        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "GalleryPageViewController") as! WPGalleryPageViewController

        controller.images = images
        controller.initialIndex = selectedIndex

        return controller
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        if let initialVC = imageViewControllerFor(index: initialIndex) {
            setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
            currentVC = initialVC
        }

        dataSource = self
        delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        /// Clear out uneeded view controllers to save memory
        ///
        if let currentVC = currentVC, let index = imageViewControllers[currentVC] {
                imageViewControllers.removeAll()
                imageViewControllers[currentVC] = index
        }
    }

    func imageViewControllerFor(index: Int) -> WPImageViewController? {

        guard index >= 0, let imageAttachment = images[safe: index] else {
            return nil
        }

        let urlString = imageAttachment.attributes?[largeImageKey] ?? imageAttachment.src

        guard let url = URL(string: urlString) else {
            return nil
        }
        
        
        //Check if we already have one
        let previouslyInitializedViewController = imageViewControllers.first(where: { $0.value == index})?.key

        if let vc = previouslyInitializedViewController {
            return vc
        }
        
        if WPImageViewController.isUrlSupported(url),  let vc = WPImageViewController(url: url)  {
           
            imageViewControllers[vc] = index
            return vc
        }

        return nil
    }

}

extension WPGalleryPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let imageVC = viewController  as? WPImageViewController else {
            return nil
        }
    
        guard let index = imageViewControllers[imageVC] else {
            return nil
        }

        return imageViewControllerFor(index: index + 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let imageVC = viewController  as? WPImageViewController else {
            return nil
        }
        
        guard let index = imageViewControllers[imageVC] else {
            return nil
        }
        
        return imageViewControllerFor(index: index - 1)
    }

}

extension WPGalleryPageViewController : UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if finished, let currentVC = previousViewControllers.first as? WPImageViewController  {
            self.currentVC =  currentVC
        }
    }
}
