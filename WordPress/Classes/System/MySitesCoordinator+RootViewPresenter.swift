import Foundation

/// `MySitesCoordinator` is used as the root presenter when Jetpack features are disabled
/// and the app's UI is simplified.
extension MySitesCoordinator: RootViewPresenter {

    // MARK: General

    var currentViewController: UIViewController? {
        return rootViewController
    }

    func getMeScenePresenter() -> ScenePresenter {
        meScenePresenter
    }

    func currentlySelectedScreen() -> String {
        return "Blog List"
    }

    func currentlyVisibleBlog() -> Blog? {
        currentBlog
    }

    // MARK: Reader

    var readerTabViewController: ReaderTabViewController? {
        unsupportedFeatureFallback()
        return nil
    }

    var readerCoordinator: ReaderCoordinator? {
        unsupportedFeatureFallback()
        return nil
    }

    var readerNavigationController: UINavigationController? {
        unsupportedFeatureFallback()
        return nil
    }

    func showReaderTab() {
        unsupportedFeatureFallback()
    }

    func switchToDiscover() {
        unsupportedFeatureFallback()
    }

    func switchToSavedPosts() {
        unsupportedFeatureFallback()
    }

    func resetReaderDiscoverNudgeFlow() {
        unsupportedFeatureFallback()
    }

    func resetReaderTab() {
        unsupportedFeatureFallback()
    }

    func navigateToReaderSearch() {
        unsupportedFeatureFallback()
    }

    func navigateToReaderSearch(withSearchText: String) {
        unsupportedFeatureFallback()
    }

    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        unsupportedFeatureFallback()
    }

    func switchToMyLikes() {
        unsupportedFeatureFallback()
    }

    func switchToFollowedSites() {
        unsupportedFeatureFallback()
    }

    func navigateToReaderSite(_ topic: ReaderSiteTopic) {
        unsupportedFeatureFallback()
    }

    func navigateToReaderTag(_ tagSlug: String) {
        unsupportedFeatureFallback()
    }

    func navigateToReader(_ pushControlller: UIViewController?) {
        unsupportedFeatureFallback()
    }

    func showReaderTab(forPost: NSNumber, onBlog: NSNumber) {
        unsupportedFeatureFallback()
    }

    // MARK: My Site

    var mySitesCoordinator: MySitesCoordinator {
        return self
    }

    func showMySitesTab() {
        // Do nothing
        // Landing here means we're trying to show the My Sites, but it's already showing.
    }

    // MARK: Notifications

    var notificationsViewController: NotificationsViewController? {
        unsupportedFeatureFallback()
        return nil
    }

    func showNotificationsTab() {
        unsupportedFeatureFallback()
    }

    func switchNotificationsTabToNotificationSettings() {
        unsupportedFeatureFallback()
    }

    func showNotificationsTabForNote(withID notificationID: String) {
        unsupportedFeatureFallback()
    }

    func popNotificationsTabToRoot() {
        unsupportedFeatureFallback()
    }

    // MARK: Me

    var meViewController: MeViewController? {
        /// On iPhone, the My Sites root view controller is a navigation controller, and Me is pushed onto the stack
        if let navigationController = mySitesCoordinator.rootViewController as? UINavigationController,
           let controller = navigationController.viewControllers.compactMap({ $0 as? MeViewController }).first {
               return controller
           }

        /// On iPad, the My Sites root view controller is a split view controller, and Me is shown in the detail view controller
        if let splitViewController = mySitesCoordinator.rootViewController as? WPSplitViewController,
           let detailNavigationController = splitViewController.viewControllers.last as? UINavigationController,
           let controller = detailNavigationController.viewControllers.compactMap({ $0 as? MeViewController }).first {
            return controller
        }

        return nil
    }

    func showMeScreen() {
        guard let meViewController else {
            /// In order to show the Me screen, the My Sites screen must be visible (see: MySitesCoordinator.showMe)
            if let navigationController = mySitesCoordinator.rootViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
            mySitesCoordinator.showMe()
            return
        }

        meViewController.navigationController?.popToViewController(meViewController, animated: false)
    }

    func popMeScreenToRoot() {
        // Do nothing
    }

    // MARK: Helpers

    /// Default implementation for functions that are not supported by the simplified UI.
    func unsupportedFeatureFallback(callingFunction: String = #function) {
        // Display overlay
        displayJetpackOverlayForDisabledEntryPoint()

        // Track incorrect access
        let properties = ["calling_function": callingFunction]
        WPAnalytics.track(.jetpackFeatureIncorrectlyAccessed, properties: properties)
    }
}
