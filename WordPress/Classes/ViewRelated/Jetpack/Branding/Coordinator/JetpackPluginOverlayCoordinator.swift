final class JetpackPluginOverlayCoordinator: JetpackOverlayCoordinator {
    private unowned let viewController: UIViewController

    private var presentingViewController: UIViewController {
        return viewController.navigationController ?? viewController
    }

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
        let webViewController = WebViewControllerFactory.controller(url: url, source: source)
        let navigationController = UINavigationController(rootViewController: webViewController)
        presentingViewController.present(navigationController, animated: true)
    }
}
