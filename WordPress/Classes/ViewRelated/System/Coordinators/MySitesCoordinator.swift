import UIKit
import WordPressComStatsiOS

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

    func showStats(for blog: Blog, timePeriod: StatsPeriodType) {
        showBlogDetails(for: blog)

        if let blogDetailsViewController = mySitesNavigationController.topViewController as? BlogDetailsViewController {
            // Setting this user default is a bit of a hack, but it's by far the easiest way to
            // get the stats view controller displaying the correct period. I spent some time
            // trying to do it differently, but the existing stats view controller setup is
            // quite complex and contains many nested child view controllers. As we're planning
            // to revamp that section in the not too distant future, I opted for this simpler
            // configuration for now. 2018-07-11 @frosty
            UserDefaults.standard.set(timePeriod.rawValue, forKey: MySitesCoordinator.statsPeriodTypeDefaultsKey)

            blogDetailsViewController.showDetailView(for: .stats)
        }
    }

    func showActivityLog(for blog: Blog) {
        showBlogDetails(for: blog)

        if let blogDetailsViewController = mySitesNavigationController.topViewController as? BlogDetailsViewController {
            blogDetailsViewController.showDetailView(for: .activity)
        }
    }

    private static let statsPeriodTypeDefaultsKey = "LastSelectedStatsPeriodType"
}
