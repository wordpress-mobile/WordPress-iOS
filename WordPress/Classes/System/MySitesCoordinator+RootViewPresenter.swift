import Foundation

/// `MySitesCoordinator` is used as the root presenter when Jetpack features are disabled
/// and the app's UI is simplified.
extension MySitesCoordinator: RootViewPresenter {

    // MARK: General

    func currentlySelectedScreen() -> String {
        return "Blog List"
    }

    func currentlyVisibleBlog() -> Blog? {
        currentBlog
    }

    // MARK: Reader

    func showReader(path: ReaderNavigationPath?) {
        unsupportedFeatureFallback()
    }

    // MARK: My Site

    func showMySitesTab() {
        // Do nothing
        // Landing here means we're trying to show the My Sites, but it's already showing.
    }

    // MARK: Notifications

    func showNotificationsTab(completion: ((NotificationsViewController) -> Void)?) {
        unsupportedFeatureFallback()
    }

    // MARK: Me

    var meViewController: MeViewController? {
        if let navigationController = rootViewController as? UINavigationController,
           let controller = navigationController.viewControllers.compactMap({ $0 as? MeViewController }).first {
               return controller
           }

        return nil
    }

    func showMeScreen(completion: ((MeViewController) -> Void)?) {
        guard let meViewController else {
            /// In order to show the Me screen, the My Sites screen must be visible (see: MySitesCoordinator.showMe)
            if let navigationController = rootViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
            if let viewController = showMe() {
                completion?(viewController)
            }
            return
        }

        meViewController.navigationController?.popToViewController(meViewController, animated: false)
        completion?(meViewController)
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
