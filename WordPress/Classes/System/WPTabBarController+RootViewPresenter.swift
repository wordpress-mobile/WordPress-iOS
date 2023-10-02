import Foundation

/// `WPTabBarController` is used as the root presenter when Jetpack features are enabled
/// and the app's UI is normal.
extension WPTabBarController: RootViewPresenter {

    // MARK: General

    var rootViewController: UIViewController {
        return self
    }

    var currentViewController: UIViewController? {
        return viewControllers?[selectedIndex]
    }

    func showBlogDetails(for blog: Blog) {
        mySitesCoordinator.showBlogDetails(for: blog)
    }

    func getMeScenePresenter() -> ScenePresenter {
        meScenePresenter
    }

    func currentlyVisibleBlog() -> Blog? {
        guard selectedIndex == WPTab.mySites.rawValue else {
            return nil
        }
        return mySitesCoordinator.currentBlog
    }

    func willDisplayPostSignupFlow() {
        mySitesCoordinator.willDisplayPostSignupFlow()
    }

    // MARK: My Site

    func showPages(for blog: Blog) {
        mySitesCoordinator.showPages(for: blog)
    }

    func showPosts(for blog: Blog) {
        mySitesCoordinator.showPosts(for: blog)
    }

    func showMedia(for blog: Blog) {
        mySitesCoordinator.showMedia(for: blog)
    }

    // MARK: Me

    func showMeScreen() {
        showMeTab()
        popMeScreenToRoot()
    }

    func popMeScreenToRoot() {
        meNavigationController?.popToRootViewController(animated: false)
    }
}
