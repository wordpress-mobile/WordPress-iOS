import UIKit
import WordPressData
import WordPressShared

@objc
public class MySitesCoordinator: NSObject {
    let becomeActiveTab: () -> Void

    @objc
    public var currentBlog: Blog? {
        mySiteViewController.blog
    }

    @objc
    public init(onBecomeActiveTab becomeActiveTab: @escaping () -> Void) {
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
    public var rootViewController: UIViewController {
        if adaptiveContent == nil {
            configureAdaptiveContent(for: Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext))
        }
        return containerViewController
    }

    @objc
    public lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController(rootViewController: rootContentViewController)

        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem.image = UIImage(named: "tab-bar-home")
        navigationController.tabBarItem.accessibilityLabel = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")
        navigationController.tabBarItem.accessibilityIdentifier = "tabbar_mysites"
        navigationController.tabBarItem.title = NSLocalizedString("My Site", comment: "The accessibility value of the my site tab.")

        return navigationController
    }()

    private lazy var mySiteViewController: MySiteViewController = {
        makeMySiteViewController()
    }()

    private func makeMySiteViewController() -> MySiteViewController {
        let controller = MySiteViewController()
        controller.supportsDashboardInRegularWidth = true
        controller.onSiteSelected = { [weak self] in self?.selectSite($0) }
        controller.onShowDestination = { [weak self] in self?.adaptiveContent?.pushDetail($0, animated: true) }
        return controller
    }

    private let containerViewController = UIViewController()
    private(set) var adaptiveContent: AdaptiveListDetailViewController?
    private var siteMenu: SiteMenuViewController?
    private var isPushingDestination = false

    private func configureAdaptiveContent(for blog: Blog?) {
        if let previous = adaptiveContent {
            previous.willMove(toParent: nil)
            previous.view.removeFromSuperview()
            previous.removeFromParent()
        }
        mySiteViewController.blog = blog
        let showsDashboard =
            blog.map {
                JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && $0.isAccessibleThroughWPCom
            } ?? false
        let content: AdaptiveListDetailViewController
        if showsDashboard, let blog {
            let menu = SiteMenuViewController(blog: blog, usesAdaptiveNavigation: true)
            menu.delegate = self
            siteMenu = menu
            content = AdaptiveListDetailViewController(
                list: UINavigationController(rootViewController: menu),
                detail: navigationController,
                usesDetailForCompactWidth: true
            )
        } else {
            // Without a dashboard the existing My Site menu is the list and compact landing screen.
            siteMenu = nil
            content = AdaptiveListDetailViewController(list: navigationController)
        }
        adaptiveContent = content
        content.onCollapseStateChanged = { [weak self] _ in
            self?.mySiteViewController.configureNavBarAppearance(animated: false)
        }
        content.onListVisibilityChanged = { [weak self] isVisible in
            self?.mySiteViewController.isSiteMenuVisible = showsDashboard && isVisible
        }
        content.onDetailDidShow = { [weak self] controller in
            guard let self, controller === self.mySiteViewController else { return }
            self.siteMenu?.selectSubsection(.home)
        }
        containerViewController.tabBarItem = navigationController.tabBarItem
        containerViewController.addChild(content)
        containerViewController.view.addSubview(content.view)
        content.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.view.leadingAnchor.constraint(equalTo: containerViewController.view.leadingAnchor),
            content.view.trailingAnchor.constraint(equalTo: containerViewController.view.trailingAnchor),
            content.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor),
            content.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor)
        ])
        content.didMove(toParent: containerViewController)
        siteMenu?.loadViewIfNeeded()
    }

    func selectSite(_ blog: Blog?) {
        becomeActiveTab()
        guard currentBlog?.objectID != blog?.objectID else { return }
        if let blog { RecentSitesService().touch(blog: blog) }
        mySiteViewController = makeMySiteViewController()
        navigationController.setViewControllers([mySiteViewController], animated: false)
        configureAdaptiveContent(for: blog)
    }

    // MARK: - Navigation

    func showRootViewController() {
        becomeActiveTab()

        navigationController.viewControllers = [rootContentViewController]
        if siteMenu == nil { adaptiveContent?.resetDetail() }
        siteMenu?.selectSubsection(.home)
    }

    // MARK: - Blog Details

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsRowKind?, userInfo: [String: Any]) {
        if adaptiveContent != nil {
            mySiteViewController.presentedViewController?.dismiss(animated: true)
            selectSite(blog)
            if let subsection {
                isPushingDestination = true
                defer { isPushingDestination = false }
                if let siteMenu {
                    siteMenu.showSubsection(subsection, userInfo: userInfo)
                } else {
                    mySiteViewController.showBlogDetailsSubsection(subsection, userInfo: userInfo)
                }
            } else {
                showRootViewController()
            }
            return
        }
        switchToBlog(blog)

        if mySiteViewController.presentedViewController != nil {
            mySiteViewController.dismiss(animated: true, completion: nil)
        }

        if let subsection, let mySiteViewController = navigationController.topViewController as? MySiteViewController {
            mySiteViewController.showBlogDetailsSubsection(subsection, userInfo: userInfo)
        }
    }

    /// Shows `blog` at the root of My Site, leaving anything presented over the app on screen.
    ///
    /// `showBlogDetails(for:)` also closes what's presented, which is right when the user asked to go to the site,
    /// but not when the app only keeps two layouts on the same site.
    func switchToBlog(_ blog: Blog) {
        showRootViewController()

        mySiteViewController.blog = blog
        RecentSitesService().touch(blog: blog)
    }

    // MARK: - My Sites

    func showMe() -> MeViewController? {
        guard let mySiteViewController = navigationController.topViewController as? MySiteViewController else {
            return nil
        }
        return mySiteViewController.showBlogDetailsMeSubsection()
    }

    // MARK: Notifications Handling

    private func addSignInObserver() {
        let notificationName = NSNotification.Name(WordPressAuthenticationManager.WPSigninDidFinishNotification)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(signinDidFinish),
                                               name: notificationName,
                                               object: nil)
    }

    @objc func signinDidFinish() {
        // The code below raises an exception during unit tests. Adding a `try?` to ignore the error.
        // The exception is Error Domain=NSRangeException Code=0 "(null)". I'm not exactly sure what code (probably
        // deep in UIKit) throws this exception, but I don't see any reason the code below would cause crash in production.
        try? WPException.objcTry {
            self.mySiteViewController = self.makeMySiteViewController()
            self.navigationController.viewControllers = [self.rootContentViewController]
            if self.adaptiveContent != nil {
                self.configureAdaptiveContent(for: Blog.lastUsedOrFirst(in: ContextManager.shared.mainContext))
            }
        }
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

extension MySitesCoordinator: SiteMenuViewControllerDelegate {
    func siteMenuViewController(
        _ siteMenuViewController: SiteMenuViewController,
        showDetailsViewController controller: UIViewController
    ) {
        guard let adaptiveContent else { return }
        if controller is MySiteViewController {
            adaptiveContent.showDetail(mySiteViewController)
        } else if isPushingDestination {
            adaptiveContent.pushDetail(controller, animated: true)
        } else {
            adaptiveContent.showDetail(controller, keeping: mySiteViewController)
        }
    }
}
