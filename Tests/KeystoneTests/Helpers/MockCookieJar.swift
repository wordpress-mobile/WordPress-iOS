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
    // Mirrors the real cookie format: WordPress sets `username|expiration|token|hmac`
    // and PHP's `setcookie()` URL-encodes the value, so `|` arrives as `%7C` and the
    // username itself is percent-encoded (with spaces as `+`).
    let encodedUsername = username
        .addingPercentEncoding(withAllowedCharacters: .alphanumerics)?
        .replacingOccurrences(of: "%20", with: "+") ?? username
    return HTTPCookie(properties: [
        .domain: domain,
        .path: "/",
        .secure: true,
        .name: "wordpress_logged_in",
        .value: "\(encodedUsername)%7C00000"
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
