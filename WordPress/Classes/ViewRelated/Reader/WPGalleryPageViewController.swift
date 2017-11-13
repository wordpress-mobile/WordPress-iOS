//
//  WPGalleryPageViewController.swift
//  WordPress
//
//  Created by Jeff Jacka on 11/12/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import UIKit


extension Array {
    subscript(safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

class WPGalleryPageViewController: UIPageViewController {

    // MARK: - Properties
    var images: [WPTextAttachment]?
    var initialIndex: Int = 0

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
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func imageViewControllerForIndex(index: Int) -> WPImageViewController? {

        guard index >= 0 else {
            return nil
        }

        guard let imageAttachment = images?[safe: index] else {
            return nil
        }

        var urlString: String?

        if let largeUrl = imageAttachment.attributes?["data-large-file"] {
            urlString = largeUrl
        } else {
            urlString = imageAttachment.src
        }

        guard let url = urlString, let finalUrl = URL(string: url) else {
            return nil
        }

        if WPImageViewController.isUrlSupported(finalUrl) {
            let vc = WPImageViewController(forGallery: finalUrl)
            vc?.index = index as NSNumber
            return vc
        }

        return nil
    }




    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
