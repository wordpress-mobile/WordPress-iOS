import UIKit
import WebKit

extension WebKitViewController {
    func configureSandboxStore(_ completion: @escaping () -> Void) {
        let storeSandboxCookieName = "store_sandbox"
        let storeSandboxCookieDomain = ".wordpress.com"

        if let storeSandboxCookie = (HTTPCookieStorage.shared.cookies?.first {

            $0.properties?[.name] as? String == storeSandboxCookieName &&
            $0.properties?[.domain] as? String == storeSandboxCookieDomain
        }) {
            // this code will only run if a store sandbox cookie has been set
            let webView = self.webView
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            cookieStore.getAllCookies { cookies in

                    var newCookies = cookies
                    newCookies.append(storeSandboxCookie)

                    cookieStore.setCookies(newCookies) {
                        completion()
                    }
            }
        } else {
            completion()
        }
    }
}
