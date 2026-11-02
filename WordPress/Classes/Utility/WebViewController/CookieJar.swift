import Foundation
import WebKit

/// Provides a common interface to look for a logged-in WordPress cookie in different
/// cookie storage systems.
///
protocol CookieJar: AnyObject {
    func getCookies(completion: @escaping ([HTTPCookie]) -> Void)
    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void)
    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void)
}

extension CookieJar {
    func hasWordPressComAuthCookie(username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://wordpress.com/")!

        return hasWordPressAuthCookie(for: url, username: username, atomicSite: atomicSite, completion: completion)
    }

    func hasWordPressSelfHostedAuthCookie(for url: URL, username: String, completion: @escaping (Bool) -> Void) {
        hasWordPressAuthCookie(for: url, username: username, atomicSite: false, completion: completion)
    }

    private func hasWordPressAuthCookie(
        for url: URL,
        username: String,
        atomicSite: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        getCookies { cookies in
            let cookie =
                cookies
                .contains(where: { cookie in
                    cookie.matches(url: url) && cookie.isWordPressLoggedIn(username: username, atomic: atomicSite)
                })

            completion(cookie)
        }
    }

    func removeWordPressComCookies(completion: @escaping () -> Void) {
        getCookies { cookies in
            self.removeCookies(cookies.filter({ $0.domain.hasSuffix(".wordpress.com") }), completion: completion)
        }
    }
}

extension HTTPCookieStorage: CookieJar {
    func getCookies(completion: @escaping ([HTTPCookie]) -> Void) {
        completion(cookies ?? [])
    }

    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        cookies.forEach(deleteCookie(_:))
        completion()
    }

    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        for cookie in cookies {
            setCookie(cookie)
        }

        completion()
    }
}

extension WKHTTPCookieStore: CookieJar {
    func getCookies(completion: @escaping ([HTTPCookie]) -> Void) {
        // The cookie store has to be used on the main thread, which is also where it calls back.
        DispatchQueue.main.async {
            // `getAllCookies` can report no cookies while WebKit's network process is not running
            // for this data store, and does not start it. Reading the cookie policy does.
            //
            // Neither call has a timeout, deliberately. A slow reply reported as "no cookies"
            // would make `removeWordPressComCookies` remove nothing.
            self.getCookiePolicy { _ in
                self.getAllCookies(completion)
            }
        }
    }

    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        cookies
            .forEach({ [unowned self] cookie in
                group.enter()
                self.delete(
                    cookie,
                    completionHandler: {
                        group.leave()
                    }
                )
            })
        group.notify(queue: .main, execute: completion)
    }

    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        guard let cookie = cookies.first else {
            return completion()
        }

        DispatchQueue.main.async {
            self.setCookie(cookie) {
                self.setCookies(Array(cookies.dropFirst()), completion: completion)
            }
        }
    }
}

private let atomicLoggedInCookieNamePrefix = "wordpress_logged_in_"
private let loggedInCookieName = "wordpress_logged_in"

private extension HTTPCookie {
    func isWordPressLoggedIn(username: String, atomic: Bool) -> Bool {
        guard !atomic else {
            return isWordPressLoggedInAtomic(username: username)
        }

        return isWordPressLoggedIn(username: username)
    }

    private func isWordPressLoggedIn(username: String) -> Bool {
        guard name.hasPrefix(loggedInCookieName) else {
            return false
        }

        // WordPress sets the cookie value to `username|expiration|token|hmac`, and
        // PHP's `setcookie()` URL-encodes it: `|` becomes `%7C`, and characters like
        // `@` inside the username become percent escapes (spaces become `+`).
        // Split on the encoded delimiter first, then decode the username component,
        // so encoded characters in the username don't break the comparison.
        let encodedUsername = value.components(separatedBy: "%7C").first ?? value
        let decodedUsername = encodedUsername
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding ?? encodedUsername

        return decodedUsername == username
    }

    private func isWordPressLoggedInAtomic(username: String) -> Bool {
        name.hasPrefix(atomicLoggedInCookieNamePrefix)
            && value.components(separatedBy: "|").first == username
    }

    /// Matches the way `HTTPCookieStorage.cookies(for:)` does: expired cookies never match, hosts are
    /// compared case-insensitively, and a cookie path only matches whole path segments.
    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        if let expiresDate, expiresDate <= Date() {
            return false
        }

        let domain = domain.lowercased()
        let matchesDomain: Bool
        if domain.hasPrefix(".") {
            matchesDomain =
                host.hasSuffix(domain)
                || host == domain.dropFirst()
        } else {
            matchesDomain = host == domain
        }

        let urlPath = url.path(percentEncoded: false)
        let requestPath = urlPath.isEmpty ? "/" : urlPath
        let matchesPath =
            requestPath == path
            || (requestPath.hasPrefix(path)
                && (path.hasSuffix("/") || requestPath.dropFirst(path.count).hasPrefix("/")))

        return matchesDomain
            && matchesPath
            && (!isSecure || (url.scheme == "https"))
    }
}
