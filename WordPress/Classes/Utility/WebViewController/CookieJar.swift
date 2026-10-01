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
        getCookies { [unowned self] cookies in
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

        // This fixes an issue with `getAllCookies` not calling its completion block (related: https://stackoverflow.com/q/55565188)
        // - adds timeout so the above failure will eventually return
        // - waits for the cookies on a background thread so that:
        //   1. we are not blocking the main thread for UI reasons
        //   2. cookies seem to never load when main thread is blocked (perhaps they dispatch to the main thread later on)

        DispatchQueue.global(qos: .userInitiated)
            .async {
                let group = DispatchGroup()
                group.enter()

                var allCookies: [HTTPCookie] = []

                DispatchQueue.main.async {
                    self.getAllCookies { cookies in
                        allCookies = cookies
                        group.leave()
                    }
                }

                let result = group.wait(timeout: .now() + .seconds(2))
                if result == .timedOut {
                    Loggers.app.warning("Time out waiting for WKHTTPCookieStore to get cookies")
                }

                DispatchQueue.main.async {
                    completion(allCookies)
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
        guard let cookie = cookies.last else {
            return completion()
        }

        DispatchQueue.main.async {
            self.setCookie(cookie) {
                self.setCookies(cookies.dropLast(), completion: completion)
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
