import Foundation

class JetpackRedirector {

    /// Used to "guess" if the Jetpack app is already installed.
    /// The check is done from the WordPress side.
    ///
    /// Note: The string values should kept in-sync with Jetpack's URL scheme.
    ///
    static var jetpackDeepLinkScheme: String {
        #if DEBUG
        return "jpdebug"
        #elseif INTERNAL_BUILD
        return "jpinternal"
        #elseif ALPHA_BUILD
        return "jpalpha"
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
        // finally, if the user might not have Jetpack installed, direct them to App Store page.
        let urlToOpen = UIApplication.shared.canOpenURL(jetpackDeepLinkURL) ? jetpackUniversalLinkURL : jetpackAppStoreURL
        UIApplication.shared.open(urlToOpen)
    }
}
