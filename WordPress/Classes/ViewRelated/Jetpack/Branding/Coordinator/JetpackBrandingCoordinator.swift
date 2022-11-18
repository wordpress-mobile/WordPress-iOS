import UIKit

/// A class containing convenience methods for the the Jetpack branding experience
class JetpackBrandingCoordinator {

    static func presentOverlay(from viewController: UIViewController, redirectAction: (() -> Void)? = nil) {

        let action = redirectAction ?? {
            guard let jetpackDeepLinkURL = URL(string: "\(AppConstants.deepLinkScheme)://app"),
                  let jetpackUniversalLinkURL = URL(string: "https://jetpack.com/app"),
                  let jetpackAppStoreURL = URL(string: "https://apps.apple.com/app/jetpack-website-builder/id1565481562") else {
                return
            }

            // First, check if the WordPress app can open Jetpack by testing its URL scheme.
            // if we can potentially open Jetpack app, let's open it through universal link to avoid scheme conflicts (e.g., a certain game :-).
            // finally, if the user might not have Jetpack installed, direct them to App Store page.
            let urlToOpen = UIApplication.shared.canOpenURL(jetpackDeepLinkURL) ? jetpackUniversalLinkURL : jetpackAppStoreURL
            UIApplication.shared.open(urlToOpen)
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
            return true
        default:
            return false
        }
    }
}
