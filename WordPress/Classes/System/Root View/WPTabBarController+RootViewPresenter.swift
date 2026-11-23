import UIKit
import WordPressData
import WordPressShared

/// `WPTabBarController` is used as the root presenter when Jetpack features are enabled
/// and the app's UI is normal.
extension WPTabBarController: RootViewPresenter {

    // MARK: General

    var rootViewController: UIViewController {
        return self
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsRowKind?, userInfo: [String: Any]) {
        mySitesCoordinator.showBlogDetails(for: blog, then: subsection, userInfo: userInfo)
    }

    func currentlyVisibleBlog() -> Blog? {
        guard selectedAppTab == .mySites else {
            return nil
        }
        return mySitesCoordinator.currentBlog
    }

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        // Tab selection must run on the main thread.
        wpAssert(Thread.isMainThread)

        selectTab(.notifications)

        // A tab with the Moved-to-Jetpack poster has no list, so the request ends on the poster.
        if let notificationsViewController {
            completion?(notificationsViewController)
        }
    }

    // MARK: Me

    @objc var isAppSidebarAvailable: Bool {
        if #available(iOS 27, *) {
            return sidebar.isAvailable
        }
        return UIDevice.isPad() && traitCollection.horizontalSizeClass != .compact
    }

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        if isAppSidebarAvailable, let appSidebarCoordinator {
            appSidebarCoordinator.showAccount(completion: completion)
            return
        }
        showMeTab()
        meNavigationController.popToRootViewController(animated: false)
        completion?(meViewController)
    }
}
