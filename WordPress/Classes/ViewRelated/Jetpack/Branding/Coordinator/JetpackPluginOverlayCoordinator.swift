import UIKit

final class JetpackPluginOverlayCoordinator: JetpackOverlayCoordinator {
    private unowned let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func navigateToPrimaryRoute() {
        // TODO
    }

    func navigateToSecondaryRoute() {
        // TODO
    }

    func navigateToLinkRoute(url: URL, source: String) {
        // TODO
    }
}
