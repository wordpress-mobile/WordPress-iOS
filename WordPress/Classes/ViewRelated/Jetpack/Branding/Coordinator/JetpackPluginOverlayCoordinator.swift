import WordPressAuthenticator

final class JetpackPluginOverlayCoordinator: JetpackOverlayCoordinator {

    // MARK: Dependencies

    private unowned let viewController: UIViewController

    // MARK: Methods

    /// Convenience entry point to show the Jetpack Install Plugin overlay when needed.
    /// The overlay will only be shown when:
    ///     1. User accesses this `Blog` via their WordPress.com account,
    ///     2. The `Blog` has individual Jetpack plugin(s) installed, without the full Jetpack plugin,
    ///     3. The overlay has never been shown for this site before (overrideable by setting `force` to `true`).
    ///
    /// - Parameters:
    ///   - blog: The Blog that might need the full Jetpack plgin.
    ///   - presentingViewController: The view controller that will be presenting the overlay.
    ///   - force: Whether the overlay should be shown regardless if the overlay has been shown previously.
    static func presentOverlayIfNeeded(for blog: Blog?,
                                       in presentingViewController: UIViewController,
                                       force: Bool = false) {
        guard let blog,
              let siteURLString = blog.displayURL as? String, // just the host URL without the scheme.
              let plugin = JetpackPlugin(from: blog.jetpackConnectionActivePlugins),
              let helper = JetpackInstallPluginHelper(blog),
              helper.shouldShowOverlay || force else {
            return
        }

        let viewModel = JetpackPluginOverlayViewModel(siteName: siteURLString, plugin: plugin)
        let overlayViewController = JetpackFullscreenOverlayViewController(with: viewModel)
        let coordinator = JetpackPluginOverlayCoordinator(viewController: overlayViewController)
        viewModel.coordinator = coordinator

        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        let shouldUseFormSheet = WPDeviceIdentification.isiPad()
        navigationViewController.modalPresentationStyle = shouldUseFormSheet ? .formSheet : .fullScreen
        presentingViewController.present(navigationViewController, animated: true) {
            helper.markOverlayAsShown()
        }
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
