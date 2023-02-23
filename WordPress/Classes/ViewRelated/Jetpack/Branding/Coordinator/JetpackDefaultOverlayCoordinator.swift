import UIKit

final class JetpackDefaultOverlayCoordinator: JetpackOverlayCoordinator {
    weak var viewModel: JetpackFullscreenOverlayViewModel?
    weak var navigationController: UINavigationController?

    func navigateToPrimaryRoute() {
        ContentMigrationCoordinator.shared.startAndDo { _ in
            JetpackRedirector.redirectToJetpack()
        }
    }

    func navigateToSecondaryRoute() {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.viewModel?.onDidDismiss?()
        }
    }

    func navigateToLinkRoute(url: URL, source: String) {
        let webViewController = WebViewControllerFactory.controller(url: url, source: source)
        let navController = UINavigationController(rootViewController: webViewController)
        navigationController?.present(navController, animated: true)
    }
}
