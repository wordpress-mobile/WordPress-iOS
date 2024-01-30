import UIKit
import WordPressUI

/// A class containing convenience methods for the the Jetpack branding experience
class JetpackBrandingCoordinator {

    static func presentOverlay(from viewController: UIViewController, redirectAction: (() -> Void)? = nil) {

        let action = redirectAction ?? {
            // Try to export WordPress data to a shared location before redirecting the user.
            ContentMigrationCoordinator.shared.startAndDo { _ in
                JetpackRedirector.redirectToJetpack()
            }
        }

        let jetpackOverlayViewController = JetpackOverlayViewController(viewFactory: makeJetpackOverlayView, redirectAction: action)
        let bottomSheet = BottomSheetViewController(childViewController: jetpackOverlayViewController, customHeaderSpacing: 0)
        bottomSheet.show(from: viewController)
    }

    static func makeJetpackOverlayView(redirectAction: (() -> Void)? = nil) -> UIView {
        JetpackOverlayView(buttonAction: redirectAction)
    }

    static func shouldShowBannerForJetpackDependentFeatures() -> Bool {
        let phase = JetpackFeaturesRemovalCoordinator.generalPhase()
        switch phase {
        case .two:
            fallthrough
        case .three:
            fallthrough
        case .staticScreens:
            return true
        default:
            return false
        }
    }
}
