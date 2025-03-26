import UIKit
import WordPressShared

@objc
class MySitesCoordinator: NSObject {
    let becomeActiveTab: () -> Void

    @objc
    var currentBlog: Blog? {
        mySiteViewController.blog
    }

    @objc
    init(onBecomeActiveTab becomeActiveTab: @escaping () -> Void) {
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
        // `hidesBottomBarWhenPushed` doesn't work with `UISplitViewController`,
        // so it we have to use `UINavigationController` directly.
        return navigationController
    }

    @objc
    lazy var navigationController: UINavigationController = {
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
        MySiteViewController()
    }

    // MARK: - Navigation

    func showRootViewController() {
        becomeActiveTab()

        navigationController.viewControllers = [rootContentViewController]
    }

    // MARK: - Blog Details

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any]) {
        showRootViewController()

        mySiteViewController.blog = blog
        RecentSitesService().touch(blog: blog)

        if mySiteViewController.presentedViewController != nil {
            mySiteViewController.dismiss(animated: true, completion: nil)
        }

        if let subsection, let mySiteViewController = navigationController.topViewController as? MySiteViewController {
            mySiteViewController.showBlogDetailsSubsection(subsection, userInfo: userInfo)
        }
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
