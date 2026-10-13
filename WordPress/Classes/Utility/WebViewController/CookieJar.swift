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
        // WebKit's own `allCookies()` could suspend forever: `getAllCookies` does not always
        // call its completion handler (https://stackoverflow.com/q/55565188).
        await withCheckedContinuation { continuation in
            let continuation = CookiesContinuation(continuation)
            getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                if continuation.resume(returning: []) {
                    Loggers.app.warning("Time out waiting for WKHTTPCookieStore to get cookies")
                }
            }
        }
    }
}

/// Resumes a continuation with whichever arrives first: the cookies or the timeout.
@MainActor
private final class CookiesContinuation {
    private var continuation: CheckedContinuation<[HTTPCookie], Never>?

    init(_ continuation: CheckedContinuation<[HTTPCookie], Never>) {
        self.continuation = continuation
    }

    /// Returns `false` if the continuation was already resumed.
    @discardableResult
    func resume(returning cookies: [HTTPCookie]) -> Bool {
        guard let continuation else {
            return false
        }
        self.continuation = nil
        continuation.resume(returning: cookies)
        return true
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
        name.hasPrefix(loggedInCookieName)
            && value.components(separatedBy: "%").first == username
    }

    private func isWordPressLoggedInAtomic(username: String) -> Bool {
        name.hasPrefix(atomicLoggedInCookieNamePrefix)
            && value.components(separatedBy: "|").first == username
    }

    func matches(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        let matchesDomain: Bool
        if domain.hasPrefix(".") {
            matchesDomain =
                host.hasSuffix(domain)
                || host == domain.dropFirst()
        } else {
            matchesDomain = host == domain
        }
        return matchesDomain
            && url.path.hasPrefix(path)
            && (!isSecure || (url.scheme == "https"))
    }
}
