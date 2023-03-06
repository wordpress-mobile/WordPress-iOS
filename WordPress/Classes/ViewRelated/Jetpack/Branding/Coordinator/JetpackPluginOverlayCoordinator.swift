import WordPressAuthenticator

final class JetpackPluginOverlayCoordinator: JetpackOverlayCoordinator {

    // MARK: Dependencies

    private unowned let viewController: UIViewController
    private weak var installDelegate: JetpackRemoteInstallDelegate?
    private let blog: Blog

    // MARK: Methods

    init(blog: Blog, viewController: UIViewController, installDelegate: JetpackRemoteInstallDelegate? = nil) {
        self.blog = blog
        self.viewController = viewController
        self.installDelegate = installDelegate
    }

    func navigateToPrimaryRoute() {
        let viewModel = WPComJetpackRemoteInstallViewModel()
        let installViewController = JetpackRemoteInstallViewController(blog: blog,
                                                                       delegate: installDelegate,
                                                                       viewModel: viewModel)

        viewController.navigationController?.pushViewController(installViewController, animated: true)
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
        let presentingViewController = viewController.navigationController ?? viewController
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
