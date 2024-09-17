import UIKit
import WordPressAuthenticator

@objc
class MySitesCoordinator: NSObject {
    let meScenePresenter: ScenePresenter

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

        addSignInObserver()
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
        if MySitesCoordinator.isSplitViewEnabled {
            return splitViewController
        } else {
            // `hidesBottomBarWhenPushed` doesn't work with `UISplitViewController`,
            // so it we have to use `UINavigationController` directly.
            return navigationController
        }
    }

    @objc class var isSplitViewEnabled: Bool {
        if Feature.enabled(.sidebar) {
            return false
        } else {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }

    @objc
    lazy var splitViewController: WPSplitViewController = {
        let splitViewController = WPSplitViewController()

        splitViewController.presentsWithGesture = false
        splitViewController.setInitialPrimaryViewController(navigationController)
        splitViewController.tabBarItem = navigationController.tabBarItem

        return splitViewController
    }()

    @objc
    lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: rootContentViewController)

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem.image = UIImage(named: "tab-bar-home")
        navigationController.tabBarItem.accessibilityLabel = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")
        navigationController.tabBarItem.accessibilityIdentifier = "mySitesTabButton"
        navigationController.tabBarItem.title = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")

        return navigationController
    }()

    private lazy var mySiteViewController: MySiteViewController = {
        makeMySiteViewController()
    }()

    private func makeMySiteViewController() -> MySiteViewController {
        MySiteViewController()
    }

    // MARK: - Navigation

    func showRootViewController() {
        becomeActiveTab()

        navigationController.viewControllers = [rootContentViewController]
    }

    // MARK: - Blog Details

    @objc
    func showBlogDetails(for blog: Blog) {
        showRootViewController()

        mySiteViewController.blog = blog
        RecentSitesService().touch(blog: blog)

        if mySiteViewController.presentedViewController != nil {
            mySiteViewController.dismiss(animated: true, completion: nil)
        }
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection, userInfo: [AnyHashable: Any] = [:]) {
        showBlogDetails(for: blog)

        if let mySiteViewController = navigationController.topViewController as? MySiteViewController {
            mySiteViewController.showBlogDetailsSubsection(subsection, userInfo: userInfo)
        }
    }

    // MARK: - Stats

    func showStats(for blog: Blog) {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            unsupportedFeatureFallback()
            return
        }

        showBlogDetails(for: blog, then: .stats)
    }

    func showStats(for blog: Blog, source: BlogDetailsNavigationSource, tab: StatsTabType? = nil, unit: StatsPeriodUnit? = nil, date: Date? = nil) {
        guard JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures() else {
            unsupportedFeatureFallback()
            return
        }

        showBlogDetails(for: blog)

        if let date = date {
            UserPersistentStoreFactory.instance().set(date, forKey: SiteStatsDashboardViewController.lastSelectedStatsDateKey)
        }

        if let siteID = blog.dotComID?.intValue, let tab = tab {
            SiteStatsDashboardPreferences.setSelected(tabType: tab, siteID: siteID)
        }

        if let unit = unit {
            SiteStatsDashboardPreferences.setSelected(periodUnit: unit)
        }

        let userInfo: [AnyHashable: Any] = [BlogDetailsViewController.userInfoSourceKey(): NSNumber(value: source.rawValue)]
        mySiteViewController.showBlogDetailsSubsection(.stats, userInfo: userInfo)
    }

    func showActivityLog(for blog: Blog) {
        showBlogDetails(for: blog, then: .activity)
    }

    // MARK: - Post creation

    func showCreateSheet(for blog: Blog?) {
        let context = ContextManager.shared.mainContext
        guard let targetBlog = blog ?? Blog.lastUsedOrFirst(in: context) else {
            return
        }

        showBlogDetails(for: targetBlog)

        mySiteViewController.presentCreateSheet()
    }

    // MARK: - My Sites

    func showMe() -> MeViewController? {
        guard let mySiteViewController = navigationController.topViewController as? MySiteViewController else {
            return nil
        }
        return mySiteViewController.showBlogDetailsMeSubsection()
    }

    func showPages(for blog: Blog) {
        showBlogDetails(for: blog, then: .pages)
    }

    func showPosts(for blog: Blog) {
        showBlogDetails(for: blog, then: .posts)
    }

    func showMedia(for blog: Blog) {
        showBlogDetails(for: blog, then: .media)
    }

    func showMediaPicker(for blog: Blog) {
        showBlogDetails(for: blog, then: .media, userInfo: [BlogDetailsViewController.userInfoShowPickerKey(): true])
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

    func showSiteMonitoring(for blog: Blog, selectedTab: SiteMonitoringTab) {
        showBlogDetails(for: blog, then: .siteMonitoring, userInfo: [BlogDetailsViewController.userInfoSiteMonitoringTabKey(): selectedTab.rawValue])
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

    // MARK: Notifications Handling

    private func addSignInObserver() {
        let notificationName = NSNotification.Name(WordPressAuthenticator.WPSigninDidFinishNotification)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(signinDidFinish),
                                               name: notificationName,
                                               object: nil)
    }

    @objc func signinDidFinish() {
        mySiteViewController = makeMySiteViewController()
        navigationController.viewControllers = [rootContentViewController]
    }

    func displayJetpackOverlayForDisabledEntryPoint() {
        let viewController = mySiteViewController
        if viewController.isViewOnScreen() {
            JetpackFeaturesRemovalCoordinator.presentOverlayIfNeeded(in: viewController,
                                                                     source: .disabledEntryPoint,
                                                                     blog: viewController.blog)
        }
    }
}
