import Foundation

/// `MySitesCoordinator` is used as the root presenter when Jetpack features are disabled
/// and the app's UI is simplified.
extension MySitesCoordinator: RootViewPresenter {

    // MARK: Reader

    func showReaderTab() {
        fallbackBehavior()
    }

    func switchToDiscover() {
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

    // MARK: Helpers

    /// Default implementation for functions that are not supported by the simplified UI.
    private func fallbackBehavior() {
        // Do nothing
    }
}
