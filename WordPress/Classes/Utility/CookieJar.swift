import Foundation
import WebKit

/// Provides a common interface to look for a logged-in WordPress cookie in different
/// cookie storage systems.
///
@objc protocol CookieJar {
    func getCookies(url: URL, completion: @escaping ([HTTPCookie]) -> Void)
    func getCookies(completion: @escaping ([HTTPCookie]) -> Void)
    func hasWordPressSelfHostedAuthCookie(for url: URL, username: String, completion: @escaping (Bool) -> Void)
    func hasWordPressComAuthCookie(username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void)
    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void)
    func removeWordPressComCookies(completion: @escaping () -> Void)
    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void)
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
    func _hasWordPressComAuthCookie(username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://wordpress.com/")!

        return _hasWordPressAuthCookie(for: url, username: username, atomicSite: atomicSite, completion: completion)
    }

    func _hasWordPressAuthCookie(for url: URL, username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void) {
        getCookies(url: url) { (cookies) in
            let cookie = cookies
                .contains(where: { cookie in
                    return cookie.isWordPressLoggedIn(username: username, atomic: atomicSite)
                })

            completion(cookie)
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

    func hasWordPressComAuthCookie(username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void) {
        _hasWordPressComAuthCookie(username: username, atomicSite: atomicSite, completion: completion)
    }

    func hasWordPressSelfHostedAuthCookie(for url: URL, username: String, completion: @escaping (Bool) -> Void) {
        _hasWordPressAuthCookie(for: url, username: username, atomicSite: false, completion: completion)
    }

    func removeCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        cookies.forEach(deleteCookie(_:))
        completion()
    }

    func removeWordPressComCookies(completion: @escaping () -> Void) {
        _removeWordPressComCookies(completion: completion)
    }

    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        for cookie in cookies {
            setCookie(cookie)
        }

        completion()
    }
}

extension WKHTTPCookieStore: CookieJarSharedImplementation {
    func getCookies(url: URL, completion: @escaping ([HTTPCookie]) -> Void) {

        // This fixes an issue with `getAllCookies` not calling its completion block (related: https://stackoverflow.com/q/55565188)
        // - adds timeout so the above failure will eventually return
        // - waits for the cookies on a background thread so that:
        //   1. we are not blocking the main thread for UI reasons
        //   2. cookies seem to never load when main thread is blocked (perhaps they dispatch to the main thread later on)

        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            group.enter()

            var urlCookies: [HTTPCookie] = []

            DispatchQueue.main.async {
                self.getAllCookies { (cookies) in
                    urlCookies = cookies.filter({ (cookie) in
                        return cookie.matches(url: url)
                    })
                    group.leave()
                }
            }

            let result = group.wait(timeout: .now() + .seconds(2))
            if result == .timedOut {
                DDLogWarn("Time out waiting for WKHTTPCookieStore to get cookies")
            }

            DispatchQueue.main.async {
                completion(urlCookies)
            }
        }
    }

    func getCookies(completion: @escaping ([HTTPCookie]) -> Void) {
        getAllCookies(completion)
    }

    func hasWordPressComAuthCookie(username: String, atomicSite: Bool, completion: @escaping (Bool) -> Void) {
        _hasWordPressComAuthCookie(username: username, atomicSite: atomicSite, completion: completion)
    }

    func hasWordPressSelfHostedAuthCookie(for url: URL, username: String, completion: @escaping (Bool) -> Void) {
        _hasWordPressAuthCookie(for: url, username: username, atomicSite: false, completion: completion)
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

    func setCookies(_ cookies: [HTTPCookie], completion: @escaping () -> Void) {
        guard let cookie = cookies.last else {
            return completion()
        }

        DispatchQueue.main.async {
            self.setCookie(cookie) { [weak self] in
                self?.setCookies(cookies.dropLast(), completion: completion)
            }
        }
    }
}

#if DEBUG
    func __removeAllWordPressComCookies() {
        var jars = [CookieJarSharedImplementation]()
        jars.append(HTTPCookieStorage.shared)
        jars.append(WKWebsiteDataStore.default().httpCookieStore)

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
        return name.hasPrefix(loggedInCookieName)
            && value.components(separatedBy: "%").first == username
    }

    private func isWordPressLoggedInAtomic(username: String) -> Bool {
        return name.hasPrefix(atomicLoggedInCookieNamePrefix)
            && value.components(separatedBy: "|").first == username
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
