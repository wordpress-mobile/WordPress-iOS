import XCTest
@testable import WordPress

private extension URLRequest {
    var httpBodyString: String? {
        return httpBody.flatMap({ data in
            return String(data: data, encoding: .utf8)
        })
    }
}

private class MockCookieJar: CookieJar {
    let implementation: (URL, String) -> Bool
    init(_ implementation: @escaping (URL, String) -> Bool) {
        self.implementation = implementation
    }

    func hasCookie(url: URL, username: String, completion: @escaping (Bool) -> Void) {
        completion(implementation(url, username))
    }
}

class WebViewAuthenticatorTests: XCTestCase {
    let dotComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!
    let dotComUser = "comuser"
    let dotComToken = "comtoken"
    let siteLoginURL = URL(string: "http://example.com/wp-login.php")!
    let siteUser = "siteuser"
    let sitePassword = "x>73R9&9;r&ju9$J499FmZ?2*Nii/?$8"
    let sitePasswordEncoded = "x%3E73R9%269%3Br%26ju9%24J499FmZ%3F2*Nii%2F%3F%248"

    var dotComAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(credentials: .dotCom(dotComUser, dotComToken))
    }

    var siteAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(credentials: .siteLogin(siteLoginURL, siteUser, sitePassword))
    }

    func testAuthenticatedSiteRequestWithoutCookie() {
        let url = URL(string: "http://example.com/some-page/?preview=true&preview_nonce=7ad6fc")!
        let authenticator = siteAuthenticator

        let cookieJar = MockCookieJar({ (url, username) in
            return false
        })
        var authenticatedRequest: URLRequest? = nil
        authenticator.request(url: url, cookieJar: cookieJar) {
            authenticatedRequest = $0
        }
        guard let request = authenticatedRequest else {
            XCTFail("The authenticator should return a valid request")
            return
        }

        XCTAssertEqual(request.url, siteLoginURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(request.httpBodyString, "log=\(siteUser)&pwd=\(sitePasswordEncoded)&redirect_to=http%3A%2F%2Fexample.com%2Fsome-page%2F%3Fpreview%3Dtrue%26preview_nonce%3D7ad6fc")
    }

    func testAuthenticatedDotComRequestWithoutCookie() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar({ (url, username) in
            return false
        })
        var authenticatedRequest: URLRequest? = nil
        authenticator.request(url: url, cookieJar: cookieJar) {
            authenticatedRequest = $0
        }
        guard let request = authenticatedRequest else {
            XCTFail("The authenticator should return a valid request")
            return
        }
        XCTAssertEqual(request.url, dotComLoginURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(dotComToken)")
        XCTAssertEqual(request.httpBodyString, "log=\(dotComUser)&redirect_to=https%3A%2F%2Fexample.wordpress.com%2Fsome-page%2F")
    }

    func testUnauthenticatedDotComRequestWithCookie() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar({ (url, username) in
            return true
        })
        var authenticatedRequest: URLRequest? = nil
        authenticator.request(url: url, cookieJar: cookieJar) {
            authenticatedRequest = $0
        }
        guard let request = authenticatedRequest else {
            XCTFail("The authenticator should return a valid request")
            return
        }
        XCTAssertEqual(request.url, url)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

}
