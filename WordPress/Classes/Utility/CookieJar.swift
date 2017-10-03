import Foundation
import WebKit

/// Provides a common interface to look for a logged-in WordPress cookie in different
/// cookie storage systems, to aid with the transition from UIWebView to WebKit.
///
@objc protocol CookieJar {
    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void)
}

extension HTTPCookieStorage: CookieJar {
    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        let cookie = cookies(for: url)?
            .first(where: { cookie in
                return cookie.isWordPressLoggedIn(username: username)
            })

        completion(cookie != nil)
    }
}

@available(iOS 11.0, *)
extension WKHTTPCookieStore: CookieJar {
    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        getAllCookies { (cookies) in
            let cookie = cookies.first(where: { (cookie) -> Bool in
                return cookie.matches(url: url)
                    && cookie.isWordPressLoggedIn(username: username)
            })
            completion(cookie != nil)
        }
    }
}

private let loggedInCookieName = "wordpress_logged_in"
private extension HTTPCookie {
    func isWordPressLoggedIn(username: String) -> Bool {
        return name == loggedInCookieName
            && value.components(separatedBy: "%").first == username
    }

    func matches(url: URL) -> Bool {
        return domain == url.host
            && url.path.hasPrefix(path)
            && (!isSecure || (url.scheme == "https"))
    }
}

