import UIKit

@objc
class MySitesCoordinator: NSObject {
    let mySitesNavigationController: UINavigationController
    let blogListViewController: BlogListViewController

    @objc
    init(mySitesNavigationController: UINavigationController,
         blogListViewController: BlogListViewController) {
        self.mySitesNavigationController = mySitesNavigationController
        self.blogListViewController = blogListViewController

        super.init()
    }

    private func prepareToNavigate() {
        WPTabBarController.sharedInstance().showMySitesTab()

        mySitesNavigationController.viewControllers = [blogListViewController]
    }

    func showBlogDetails(for blog: Blog) {
        prepareToNavigate()

        blogListViewController.setSelectedBlog(blog, animated: false)
    }

    func showStats(for blog: Blog) {
        showBlogDetails(for: blog)

        if let blogDetailsViewController = mySitesNavigationController.topViewController as? BlogDetailsViewController {
            blogDetailsViewController.showDetailView(for: .stats)
        }
    }

    func showActivityLog(for blog: Blog) {
        showBlogDetails(for: blog)

        if let blogDetailsViewController = mySitesNavigationController.topViewController as? BlogDetailsViewController {
            blogDetailsViewController.showDetailView(for: .activity)
        }
    }
}
