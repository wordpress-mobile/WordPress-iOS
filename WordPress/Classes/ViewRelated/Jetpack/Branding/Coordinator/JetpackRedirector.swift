import Foundation
import StoreKit

class JetpackRedirector {

    /// Used to "guess" if the Jetpack app is already installed.
    /// The check is done from the WordPress side.
    ///
    /// Note: The string values should kept in-sync with Jetpack's URL scheme.
    ///
    static var jetpackDeepLinkScheme: String {
        /// Important: Multiple compiler flags are set for some builds
        /// so ordering matters.
        #if DEBUG
        return "jpdebug"
        #elseif ALPHA_BUILD
        return "jpalpha"
        #elseif INTERNAL_BUILD
        return "jpinternal"
        #else
        return "jetpack"
        #endif
    }

    static func redirectToJetpack() {
        guard let jetpackDeepLinkURL = URL(string: "\(jetpackDeepLinkScheme)://app"),
              let jetpackUniversalLinkURL = URL(string: "https://jetpack.com/app"),
              let jetpackAppStoreURL = URL(string: "https://apps.apple.com/app/jetpack-website-builder/id1565481562") else {
            return
        }

        // First, check if the WordPress app can open Jetpack by testing its URL scheme.
        // if we can potentially open Jetpack app, let's open it through universal link to avoid scheme conflicts (e.g., a certain game :-).
        // finally, if the user might not have Jetpack installed, open App Store view controller through StoreKit.
        if UIApplication.shared.canOpenURL(jetpackDeepLinkURL) {
            UIApplication.shared.open(jetpackUniversalLinkURL)
        } else {
            showJetpackAppInstallation(fallbackURL: jetpackAppStoreURL)
        }
    }

    private static func showJetpackAppInstallation(fallbackURL: URL) {
        let viewController = RootViewCoordinator.sharedPresenter.rootViewController
        let storeProductVC = SKStoreProductViewController()
        let appID = [SKStoreProductParameterITunesItemIdentifier: "1565481562"]

        storeProductVC.loadProduct(withParameters: appID) { (result, error) in
            if result {
                viewController.present(storeProductVC, animated: true)
            } else if let error = error {
                DDLogError("Failed loading Jetpack App product: \(error.localizedDescription)")
                UIApplication.shared.open(fallbackURL)
            }
        }
    }
}
