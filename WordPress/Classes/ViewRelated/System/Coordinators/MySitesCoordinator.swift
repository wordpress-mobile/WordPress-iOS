import UIKit

@objc
class MySitesCoordinator: NSObject {
    static let splitViewControllerRestorationID = "MySiteSplitViewControllerRestorationID"
    static let navigationControllerRestorationID = "MySiteNavigationControllerRestorationID"

    private let meScenePresenter: ScenePresenter

    let becomeActiveTab: () -> Void

    @objc
    var currentBlog: Blog? {
        mySiteViewController.blog
    }

    @objc
    init(meScenePresenter: ScenePresenter, onBecomeActiveTab becomeActiveTab: @escaping () -> Void) {
        self.meScenePresenter = meScenePresenter
        self.becomeActiveTab = becomeActiveTab

        super.init()
    }

    // MARK: - Root View Controller

    private var rootContentViewController: UIViewController {
        mySiteViewController
    }

    // MARK: - VCs

    /// The view controller that should be presented by the tab bar controller.
    ///
    @objc
    var rootViewController: UIViewController {
        return splitViewController
    }

    @objc
    lazy var splitViewController: WPSplitViewController = {
        let splitViewController = WPSplitViewController()

        splitViewController.restorationIdentifier = MySitesCoordinator.splitViewControllerRestorationID
        splitViewController.presentsWithGesture = false
        splitViewController.setInitialPrimaryViewController(navigationController)
        splitViewController.tabBarItem = navigationController.tabBarItem

        return splitViewController
    }()

    @objc
    lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: rootContentViewController)

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.restorationIdentifier = MySitesCoordinator.navigationControllerRestorationID
        navigationController.navigationBar.isTranslucent = false

        let tabBarImage = AppStyleGuide.mySiteTabIcon
        navigationController.tabBarItem.image = tabBarImage
        navigationController.tabBarItem.selectedImage = tabBarImage
        navigationController.tabBarItem.accessibilityLabel = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")
        navigationController.tabBarItem.accessibilityIdentifier = "mySitesTabButton"
        navigationController.tabBarItem.title = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")

        return navigationController
    }()

    @objc
    private(set) lazy var blogListViewController: BlogListViewController = {
        BlogListViewController(meScenePresenter: self.meScenePresenter)
    }()

    private lazy var mySiteViewController: MySiteViewController = {
        MySiteViewController(meScenePresenter: self.meScenePresenter)
    }()

    // MARK: - Navigation

    func showRootViewController() {
        becomeActiveTab()

        navigationController.viewControllers = [rootContentViewController]
    }

    // MARK: - Sites List

    private func showSitesList() {
        showRootViewController()

        let navigationController = UINavigationController(rootViewController: blogListViewController)
        navigationController.modalPresentationStyle = .formSheet
        mySiteViewController.present(navigationController, animated: true)
    }

    // MARK: - Blog Details

    @objc
    func showBlogDetails(for blog: Blog) {
        showRootViewController()

        mySiteViewController.blog = blog
        if mySiteViewController.presentedViewController != nil {
            mySiteViewController.dismiss(animated: true, completion: nil)
        }
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection) {
        showBlogDetails(for: blog)

        if let mySiteViewController = navigationController.topViewController as? MySiteViewController {
            mySiteViewController.showBlogDetailsSubsection(subsection)
        } else if let blogDetailsViewController = navigationController.topViewController as? BlogDetailsViewController {
            blogDetailsViewController.showDetailView(for: subsection)
        }
    }

    // MARK: - Stats

    func showStats(for blog: Blog) {
        showBlogDetails(for: blog, then: .stats)
    }

    func showStats(for blog: Blog, timePeriod: StatsPeriodType, date: Date? = nil) {
        showBlogDetails(for: blog)

        if let date = date {
            UserDefaults.standard.set(date, forKey: SiteStatsDashboardViewController.lastSelectedStatsDateKey)
        }

        guard let key = SiteStatsDashboardViewController.lastSelectedStatsPeriodTypeKey else {
            return
        }

        UserDefaults.standard.set(timePeriod.rawValue, forKey: key)

        mySiteViewController.showDetailView(for: .stats)
    }

    func showActivityLog(for blog: Blog) {
        showBlogDetails(for: blog, then: .activity)
    }

    // MARK: - Adding a new site

    func showSiteCreation() {
        showRootViewController()
        mySiteViewController.launchSiteCreation(source: "my_site")
    }

    @objc
    func showAddNewSite() {
        showRootViewController()
        mySiteViewController.presentInterfaceForAddingNewSite()
    }

    // MARK: - Post creation

    func showCreateSheet(for blog: Blog?) {
        let context = ContextManager.shared.mainContext
        let service = BlogService(managedObjectContext: context)
        guard let targetBlog = blog ?? service.lastUsedOrFirstBlog() else {
            return
        }

        showBlogDetails(for: targetBlog)

        mySiteViewController.presentCreateSheet()
    }

    // MARK: - My Sites

    func showPages(for blog: Blog) {
        showBlogDetails(for: blog, then: .pages)
    }

    func showPosts(for blog: Blog) {
        showBlogDetails(for: blog, then: .posts)
    }

    func showMedia(for blog: Blog) {
        showBlogDetails(for: blog, then: .media)
    }

    func showComments(for blog: Blog) {
        showBlogDetails(for: blog, then: .comments)
    }

    func showSharing(for blog: Blog) {
        showBlogDetails(for: blog, then: .sharing)
    }

    func showPeople(for blog: Blog) {
        showBlogDetails(for: blog, then: .people)
    }

    func showPlugins(for blog: Blog) {
        showBlogDetails(for: blog, then: .plugins)
    }

    func showManagePlugins(for blog: Blog) {
        guard blog.supports(.pluginManagement) else {
            return
        }

        // PerformWithoutAnimation is required here, otherwise the view controllers
        // potentially get added to the navigation controller out of order
        // (ShowDetailViewController, used by BlogDetailsViewController is animated)
        UIView.performWithoutAnimation {
            showBlogDetails(for: blog, then: .plugins)
        }

        guard let site = JetpackSiteRef(blog: blog),
              let navigationController = splitViewController.topDetailViewController?.navigationController else {
            return
        }

        let query = PluginQuery.all(site: site)
        let listViewController = PluginListViewController(site: site, query: query)

        navigationController.pushViewController(listViewController, animated: false)
    }
}
