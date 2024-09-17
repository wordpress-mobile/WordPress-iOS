import Foundation

/// `StaticScreensTabBarWrapper` is used as the root presenter when Jetpack features are disabled
///  but not fully removed. The class wraps around `WPTabBarController`
///  but disables all Reader and Notifications functionality
class StaticScreensTabBarWrapper: RootViewPresenter {

    // MARK: Private Variables

    private let tabBarController = WPTabBarController(staticScreens: true)

    // MARK: General

    var rootViewController: UIViewController {
        return tabBarController
    }

    func currentlySelectedScreen() -> String {
        tabBarController.currentlySelectedScreen()
    }

    func showBlogDetails(for blog: Blog, then subsection: BlogDetailsSubsection?, userInfo: [AnyHashable: Any]) {
        tabBarController.showBlogDetails(for: blog, then: subsection, userInfo: userInfo)
    }

    func currentlyVisibleBlog() -> Blog? {
        tabBarController.currentlyVisibleBlog()
    }

    // MARK: Reader

    func showReaderTab() {
        tabBarController.showReaderTab()
    }

    func showReaderTab(forPost: NSNumber, onBlog: NSNumber) {
        // Do nothing
    }

    func switchToDiscover() {
        // Do nothing
    }

    func navigateToReaderSearch() {
        // Do nothing
    }

    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        // Do nothing
    }

    func switchToMyLikes() {
        // Do nothing
    }

    func switchToFollowedSites() {
        // Do nothing
    }

    func navigateToReaderSite(_ topic: ReaderSiteTopic) {
        // Do nothing
    }

    func navigateToReaderTag(_ tagSlug: String) {
        // Do nothing
    }

    func navigateToReader(_ pushControlller: UIViewController?) {
        // Do nothing
    }

    // MARK: My Site

    var mySitesCoordinator: MySitesCoordinator {
        return tabBarController.mySitesCoordinator
    }

    func showMySitesTab() {
        tabBarController.showMySitesTab()
    }

    // MARK: Notifications

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        tabBarController.showNotificationsTab(completion: completion)
    }

    // MARK: Me

    var meViewController: MeViewController? {
        return tabBarController.meViewController
    }

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        tabBarController.showMeTab()
        tabBarController.meNavigationController.popToRootViewController(animated: false)
        completion?(tabBarController.meViewController)
    }
}
