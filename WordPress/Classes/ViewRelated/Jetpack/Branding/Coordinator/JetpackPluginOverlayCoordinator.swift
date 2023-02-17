final class JetpackPluginOverlayCoordinator: JetpackOverlayCoordinator {
    private unowned let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func navigateToPrimaryRoute() {
        // TODO: Navigate to the installation flow.
    }

    func navigateToSecondaryRoute() {
        // TODO: Contact support with support origin.
    }

    func navigateToLinkRoute(url: URL, source: String) {
        // TODO: Open wordpress.com/tos via in-app browser.
    }
}
