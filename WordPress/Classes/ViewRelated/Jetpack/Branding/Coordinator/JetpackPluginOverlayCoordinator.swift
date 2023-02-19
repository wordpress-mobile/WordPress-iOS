import WordPressAuthenticator

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
        guard let navigationController = viewController.navigationController else {
            return
        }

        let supportViewController = SupportTableViewController()
        supportViewController.sourceTag = Constants.supportSourceTag
        navigationController.pushViewController(supportViewController, animated: true)
    }

    func navigateToLinkRoute(url: URL, source: String) {
        let webViewController = WebViewControllerFactory.controller(url: url, source: source)
        let navigationController = UINavigationController(rootViewController: webViewController)
        presentingViewController.present(navigationController, animated: true)
    }
}

private extension JetpackPluginOverlayCoordinator {
    enum Constants {
        static let supportSourceTag = WordPressSupportSourceTag(
            name: "jetpackInstallFullPluginOverlay",
            origin: "origin:jp-install-full-plugin-overlay"
        )
    }
}
