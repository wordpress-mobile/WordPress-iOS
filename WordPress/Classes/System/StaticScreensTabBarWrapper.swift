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

    var currentViewController: UIViewController? {
        return tabBarController.currentViewController
    }

    func getMeScenePresenter() -> ScenePresenter {
        tabBarController.getMeScenePresenter()
    }

    func currentlySelectedScreen() -> String {
        tabBarController.currentlySelectedScreen()
    }

    func showBlogDetails(for blog: Blog) {
        tabBarController.showBlogDetails(for: blog)
    }

    func currentlyVisibleBlog() -> Blog? {
        tabBarController.currentlyVisibleBlog()
    }

    func willDisplayPostSignupFlow() {
        tabBarController.willDisplayPostSignupFlow()
    }

    // MARK: Reader

    var readerTabViewController: ReaderTabViewController? {
        return nil
    }

    var readerCoordinator: ReaderCoordinator? {
        return nil
    }

    var readerNavigationController: UINavigationController? {
        return nil
    }

    func showReaderTab() {
        tabBarController.showReaderTab()
    }

    func showReaderTab(forPost: NSNumber, onBlog: NSNumber) {
        // Do nothing
    }

    func switchToDiscover() {
        // Do nothing
    }

    func switchToSavedPosts() {
        // Do nothing
    }

    func resetReaderDiscoverNudgeFlow() {
        // Do nothing
    }

    func resetReaderTab() {
        // Do nothing
    }

    func navigateToReaderSearch() {
        // Do nothing
    }

    func navigateToReaderSearch(withSearchText: String) {
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

    func showPages(for blog: Blog) {
        tabBarController.showPages(for: blog)
    }

    func showPosts(for blog: Blog) {
        tabBarController.showPosts(for: blog)
    }

    func showMedia(for blog: Blog) {
        tabBarController.showMedia(for: blog)
    }

    // MARK: Notifications

    var notificationsViewController: NotificationsViewController? {
        return nil
    }

    func showNotificationsTab() {
        tabBarController.showNotificationsTab()
    }

    func showNotificationsTabForNote(withID notificationID: String) {
        tabBarController.showNotificationsTab()
    }

    func switchNotificationsTabToNotificationSettings() {
        tabBarController.showNotificationsTab()
    }

    func popNotificationsTabToRoot() {
        // Do nothing since static notification tab will never have a stack
    }

    // MARK: Me

    var meViewController: MeViewController? {
        return tabBarController.meViewController
    }

    func showMeScreen() {
        tabBarController.showMeTab()
    }

    func popMeScreenToRoot() {
        tabBarController.meNavigationController?.popToRootViewController(animated: false)
    }
}
