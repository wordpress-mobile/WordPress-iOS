import Foundation
import WordPress
import WebKit

class MockCookieJar: HTTPCookieStorage {
    var _cookies = [HTTPCookie]()

    override func cookies(for URL: URL) -> [HTTPCookie]? {
        return _cookies
    }

    override var cookies: [HTTPCookie]? {
        return _cookies
    }

    override func deleteCookie(_ cookie: HTTPCookie) {
        if let index = _cookies.firstIndex(of: cookie) {
            _cookies.remove(at: index)
        }
    }

    override func setCookie(_ cookie: HTTPCookie) {
        guard !_cookies.contains(cookie) else {
            return
        }
        _cookies.append(cookie)
    }
}

fileprivate func wordPressCookie(username: String, domain: String) -> HTTPCookie {
    return HTTPCookie(properties: [
        .domain: domain,
        .path: "/",
        .secure: true,
        .name: "wordpress_logged_in",
        .value: "\(username)%00000"
    ])!
}

extension HTTPCookieStorage {
    func setWordPressCookie(username: String, domain: String) {
        let cookie = wordPressCookie(username: username, domain: domain)
        setCookie(cookie)
    }

    func setWordPressComCookie(username: String) {
        setWordPressCookie(username: username, domain: ".wordpress.com")
    }
}

extension WKHTTPCookieStore {
    func setWordPressCookie(username: String, domain: String) {
        let cookie = wordPressCookie(username: username, domain: domain)
        setCookie(cookie)
    }

    func setWordPressComCookie(username: String) {
        setWordPressCookie(username: username, domain: ".wordpress.com")
    }
}
