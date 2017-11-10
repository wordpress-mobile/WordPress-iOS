import Foundation
import WordPress

class MockCookieJar: HTTPCookieStorage {
    var _cookies = [HTTPCookie]()

    override func cookies(for URL: URL) -> [HTTPCookie]? {
        return _cookies
    }

    override var cookies: [HTTPCookie]? {
        return _cookies
    }

    override func deleteCookie(_ cookie: HTTPCookie) {
        if let index = _cookies.index(of: cookie) {
            _cookies.remove(at: index)
        }
    }

    override func setCookie(_ cookie: HTTPCookie) {
        guard !_cookies.contains(cookie) else {
            return
        }
        _cookies.append(cookie)
    }

    func setWordPressCookie(username: String, domain: String) {
        let cookie = HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .secure: true,
            .name: "wordpress_logged_in",
            .value: "\(username)%00000"
            ])!
        setCookie(cookie)
    }

    func setWordPressComCookie(username: String) {
        setWordPressCookie(username: username, domain: ".wordpress.com")
    }
}
