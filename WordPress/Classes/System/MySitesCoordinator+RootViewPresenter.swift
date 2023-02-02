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

    func navigateToReaderTag(_ topic: ReaderTagTopic) {
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
