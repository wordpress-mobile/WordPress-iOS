import Foundation
import BuildSettingsKit

class JetpackRedirector {

    /// Used to "guess" if the Jetpack app is already installed.
    /// The check is done from the WordPress side.
    ///
    /// Note: The string values should kept in-sync with Jetpack's URL scheme.
    ///
    static var jetpackDeepLinkScheme: String {
        BuildSettings.current.jetpackAppURLScheme
    }

    static func redirectToJetpack() {
        guard let jetpackDeepLinkURL = URL(string: "\(jetpackDeepLinkScheme)://app"),
              let jetpackUniversalLinkURL = URL(string: "https://jetpack.com/app"),
              let jetpackAppStoreURL = URL(string: "https://apps.apple.com/app/jetpack-website-builder/id1565481562") else {
            return
        }

        // First, check if the WordPress app can open Jetpack by testing its URL scheme.
        // if we can potentially open Jetpack app, let's open it through universal link to avoid scheme conflicts (e.g., a certain game :-).
        // finally, if the user might not have Jetpack installed, open App Store
        if UIApplication.shared.canOpenURL(jetpackDeepLinkURL) {
            UIApplication.shared.open(jetpackUniversalLinkURL)
        } else {
            UIApplication.shared.open(jetpackAppStoreURL)
        }
    }
}
