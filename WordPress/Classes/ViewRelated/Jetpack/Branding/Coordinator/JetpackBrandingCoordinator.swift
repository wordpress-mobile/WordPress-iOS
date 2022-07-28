import UIKit

/// A class containing convenience methods for the the Jetpack branding experience
class JetpackBrandingCoordinator {

    static func presentOverlay(from viewController: UIViewController, redirectAction: (() -> Void)? = nil) {

        let action = redirectAction ?? {
            // TODO: Add here the default action to redirect to the jp app
        }

        let jetpackOverlayViewController = JetpackOverlayViewController(redirectAction: action)
        let bottomSheet = BottomSheetViewController(childViewController: jetpackOverlayViewController, customHeaderSpacing: 0)
        bottomSheet.show(from: viewController)
    }
}
