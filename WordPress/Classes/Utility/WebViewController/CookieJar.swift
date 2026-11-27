import Foundation
import WebKit

/// Provides a common interface to look for a logged-in WordPress cookie in different
/// cookie storage systems.
///
/// `HTTPCookieStorage` and `WKHTTPCookieStore` satisfy `setCookie(_:)` and `deleteCookie(_:)`
/// with their own methods.
protocol CookieJar: Sendable {
    func getCookies() async -> [HTTPCookie]
    func setCookie(_ cookie: HTTPCookie) async
    func deleteCookie(_ cookie: HTTPCookie) async
}

extension CookieJar {
    func hasWordPressComAuthCookie(username: String, atomicSite: Bool) async -> Bool {
        let url = URL(string: "https://wordpress.com/")!

        return await hasWordPressAuthCookie(for: url, username: username, atomicSite: atomicSite)
    }

    func hasWordPressSelfHostedAuthCookie(for url: URL, username: String) async -> Bool {
        await hasWordPressAuthCookie(for: url, username: username, atomicSite: false)
    }

    private func hasWordPressAuthCookie(for url: URL, username: String, atomicSite: Bool) async -> Bool {
        await getCookies()
            .contains { cookie in
                cookie.matches(url: url) && cookie.isWordPressLoggedIn(username: username, atomic: atomicSite)
            }
    }

    func removeWordPressComCookies() async {
        for cookie in await getCookies() where cookie.isWordPressComCookie {
            await deleteCookie(cookie)
        }
    }

    func setCookies(_ cookies: [HTTPCookie]) async {
        for cookie in cookies {
            await setCookie(cookie)
        }
    }
}

extension HTTPCookieStorage: CookieJar {
    func getCookies() async -> [HTTPCookie] {
        cookies ?? []
    }
}

extension WKHTTPCookieStore: CookieJar {
    func getCookies() async -> [HTTPCookie] {
        // `allCookies()` can report no cookies while WebKit's network process is not running for
        // this data store, and does not start it. Reading the cookie policy does.
        //
        // Neither call has a timeout, deliberately. A slow reply reported as "no cookies" would
        // make `removeWordPressComCookies` remove nothing.
        _ = await cookiePolicy
        return await allCookies()
    }
}

extension HTTPCookie {
    var isWordPressComCookie: Bool {
        domain.hasSuffix(".wordpress.com")
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
