import UIKit

class JetpackWebViewControllerFactory {

    static func settingsController(siteID: Int) -> UIViewController? {
        guard let url = URL(string: "https://wordpress.com/settings/jetpack/\(siteID)") else {
            return nil
        }
        return WebViewControllerFactory.controller(url: url, source: "jetpack_web_settings")
    }

}
