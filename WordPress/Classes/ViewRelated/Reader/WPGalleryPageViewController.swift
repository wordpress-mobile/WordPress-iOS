import UIKit

class WPGalleryPageViewController: UIPageViewController {

    // MARK: - Properties
    var images: [WPTextAttachment]?
    var initialIndex = 0

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
    open class func controllerWithImages(_ images: [WPTextAttachment], selectedIndex: Int) -> WPGalleryPageViewController {

        let storyboard = UIStoryboard(name: "Reader", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "GalleryPageViewController") as! WPGalleryPageViewController

        controller.images = images
        controller.initialIndex = selectedIndex

        return controller
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if let initalVC = imageViewControllerForIndex(index: initialIndex) {
            setViewControllers([initalVC], direction: .forward, animated: true, completion: nil)
        }

        dataSource = self
    }

    func imageViewControllerForIndex(index: Int) -> WPImageViewController? {

        guard index >= 0, let imageAttachment = images?[safe: index] else {
            return nil
        }

        let urlString = imageAttachment.attributes?["data-large-file"] ?? imageAttachment.src

        guard let url = URL(string: urlString) else {
            return nil
        }

        if WPImageViewController.isUrlSupported(url) {
            let vc = WPImageViewController(forGallery: url, andIndex: index as NSNumber)
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

        if let index = imageVC.index as? Int {
            return imageViewControllerForIndex(index: index + 1)
        }

        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let imageVC = viewController  as? WPImageViewController else {
            return nil
        }

        if let index = imageVC.index as? Int {
            return imageViewControllerForIndex(index: index - 1)
        }

        return nil
    }

}
