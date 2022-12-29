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

    func currentlySelectedScreen() -> String! {
        return "Blog List"
    }

    func currentlyVisibleBlog() -> Blog? {
        currentBlog
    }

    // MARK: Reader

    var readerTabViewController: ReaderTabViewController? {
        return nil
    }

    var readerCoordinator: ReaderCoordinator? {
        return nil
    }

    func showReaderTab() {
        fallbackBehavior()
    }

    func switchToDiscover() {
        fallbackBehavior()
    }

    func switchToSavedPosts() {
        fallbackBehavior()
    }

    func resetReaderDiscoverNudgeFlow() {
        fallbackBehavior()
    }

    func resetReaderTab() {
        fallbackBehavior()
    }

    func navigateToReaderSearch() {
        fallbackBehavior()
    }

    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        fallbackBehavior()
    }

    func switchToMyLikes() {
        fallbackBehavior()
    }

    func switchToFollowedSites() {
        fallbackBehavior()
    }

    func navigateToReaderSite(_ topic: ReaderSiteTopic) {
        fallbackBehavior()
    }

    func navigateToReaderTag(_ topic: ReaderTagTopic) {
        fallbackBehavior()
    }

    func navigateToReader(_ pushControlller: UIViewController?) {
        fallbackBehavior()
    }

    func showReaderTab(forPost: NSNumber!, onBlog: NSNumber!) {
        fallbackBehavior()
    }

    // MARK: My Site

    var mySitesCoordinator: MySitesCoordinator? {
        return self
    }

    func showMySitesTab() {
        // Do nothing
        // Landing here means we're trying to show the My Sites, but it's already showing.
    }

    // MARK: Notifications

    func showNotificationsTab() {
        fallbackBehavior()
    }

    func switchNotificationsTabToNotificationSettings() {
        fallbackBehavior()
    }

    func showNotificationsTabForNote(withID notificationID: String!) {
        fallbackBehavior()
    }

    func popNotificationsTabToRoot() {
        fallbackBehavior()
    }

    // MARK: Helpers

    /// Default implementation for functions that are not supported by the simplified UI.
    private func fallbackBehavior(callingFunction: String = #function) {
        let properties = ["calling_function": callingFunction]
        WPAnalytics.track(.jetpackFeatureIncorrectlyAccessed, properties: properties)
    }
}
