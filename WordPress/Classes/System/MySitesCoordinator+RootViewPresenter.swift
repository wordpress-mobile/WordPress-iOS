import Foundation

/// `MySitesCoordinator` is used as the root presenter when Jetpack features are disabled
/// and the app's UI is simplified.
extension MySitesCoordinator: RootViewPresenter {

    // MARK: General

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

    var mySitesCoordinator: MySitesCoordinator! {
        return self
    }

    func showMySitesTab() {
        // Do nothing
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
    private func fallbackBehavior() {
        // TODO: Consider showing an overlay
        // TODO: Print a log statement
        // TODO: Consider tracking this
    }
}
