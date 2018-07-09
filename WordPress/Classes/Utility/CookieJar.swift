import Foundation
import WebKit

/// Provides a common interface to look for a logged-in WordPress cookie in different
/// cookie storage systems, to aid with the transition from UIWebView to WebKit.
///
@objc protocol CookieJar {
    func getCookies(url: URL, completion: @escaping ([HTTPCookie]) -> Void)
    func getCookies(completion: @escaping ([HTTPCookie]) -> Void)
    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void)
    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void)
    func removeWordPressComCookies(completion: @escaping () -> Void)
}

// As long as CookieJar is @objc, we can't have shared methods in protocol
// extensions, as it needs to be accessible to Obj-C.
// Whenever we migrate enough code so this doesn't need to be called from Swift,
// a regular CookieJar protocol with shared implementation on an extension would suffice.
//
// Also, although you're not supposed to use this outside this file, it can't be private
// since we're subclassing HTTPCookieStorage (which conforms to this) in MockCookieJar in
// the test target, and the swift compiler will crash when doing that ¯\_(ツ)_/¯
//
// https://bugs.swift.org/browse/SR-2370
//
protocol CookieJarSharedImplementation: CookieJar {
}

extension CookieJarSharedImplementation {
    func _hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        getCookies(url: url) { (cookies) in
            let cookie = cookies
                .first(where: { cookie in
                    return cookie.isWordPressLoggedIn(username: username)
                })

            completion(cookie != nil)
        }
    }

    func _removeWordPressComCookies(completion: @escaping () -> Void) {
        getCookies { [unowned self] (cookies) in
            self.removeCookies(cookies.filter({ $0.domain.hasSuffix(".wordpress.com") }), completion: completion)
        }
    }
}

extension HTTPCookieStorage: CookieJarSharedImplementation {
    func getCookies(url: URL, completion: @escaping ([HTTPCookie]) -> Void) {
        completion(cookies(for: url) ?? [])
    }

    func getCookies(completion: @escaping ([HTTPCookie]) -> Void) {
        completion(cookies ?? [])
    }

    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        _hasCookie(url: url, username: username, completion: completion)
    }

    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        cookies.forEach(deleteCookie(_:))
        completion()
    }

    func removeWordPressComCookies(completion: @escaping () -> Void) {
        _removeWordPressComCookies(completion: completion)
    }
}

@available(iOS 11.0, *)
extension WKHTTPCookieStore: CookieJarSharedImplementation {
    func getCookies(url: URL, completion: @escaping ([HTTPCookie]) -> Void) {

        var urlCookies: [HTTPCookie] = []

        DispatchQueue.main.async {
            let group = DispatchGroup()
            group.enter()

            self.getAllCookies { (cookies) in
                urlCookies = cookies.filter({ (cookie) in
                    return cookie.matches(url: url)
                })
                group.leave()
            }

            let result = group.wait(timeout: .now() + .seconds(2))
            if result == .timedOut {
                DDLogWarn("Time out waiting for WKHTTPCookieStore to get cookies")
            }
            completion(urlCookies)
        }
    }

    func getCookies(completion: @escaping ([HTTPCookie]) -> Void) {
        getAllCookies(completion)
    }

    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        _hasCookie(url: url, username: username, completion: completion)
    }

    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        cookies
            .forEach({ [unowned self] (cookie) in
                group.enter()
                self.delete(cookie, completionHandler: {
                    group.leave()
                })
            })
        let result = group.wait(timeout: .now() + .seconds(2))
        if result == .timedOut {
            DDLogWarn("Time out waiting for WKHTTPCookieStore to remove cookies")
        }
        completion()
    }

    func removeWordPressComCookies(completion: @escaping () -> Void) {
        _removeWordPressComCookies(completion: completion)
    }
}

#if DEBUG
    func __removeAllWordPressComCookies() {
        var jars = [CookieJarSharedImplementation]()
        jars.append(HTTPCookieStorage.shared)
        if #available(iOS 11.0, *) {
            jars.append(WKWebsiteDataStore.default().httpCookieStore)
        }
        let group = DispatchGroup()
        jars.forEach({ jar in
            group.enter()
            jar.removeWordPressComCookies {
                group.leave()
            }
        })
        _ = group.wait(timeout: .now() + .seconds(5))
    }
#endif

private let loggedInCookieName = "wordpress_logged_in"
private extension HTTPCookie {
    func isWordPressLoggedIn(username: String) -> Bool {
        return name == loggedInCookieName
            && value.components(separatedBy: "%").first == username
    }

    func matches(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        let matchesDomain: Bool
        if domain.hasPrefix(".") {
            matchesDomain = host.hasSuffix(domain)
                || host == domain.dropFirst()
        } else {
            matchesDomain = host == domain
        }
        return matchesDomain
            && url.path.hasPrefix(path)
            && (!isSecure || (url.scheme == "https"))
    }
}
