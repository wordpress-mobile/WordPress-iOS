import XCTest
@testable import WordPress

private extension URLRequest {
    var httpBodyString: String? {
        return httpBody.flatMap({ data in
            return String(data: data, encoding: .utf8)
        })
    }
}

class WebViewAuthenticatorTests: XCTestCase {
    let dotComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!
    let dotComUser = "comuser"
    let dotComToken = "comtoken"
    let siteLoginURL = URL(string: "http://example.com/wp-login.php")!
    let siteUser = "siteuser"
    let sitePassword = "x>73R9&9;r&ju9$J499FmZ?2*Nii/?$8"
    let sitePasswordEncoded = "x%3E73R9%269;r%26ju9$J499FmZ?2*Nii/?$8"

    var dotComAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(credentials: .dotCom(username: dotComUser, authToken: dotComToken))
    }

    var siteAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(credentials: .siteLogin(loginURL: siteLoginURL, username: siteUser, password: sitePassword))
    }

    func testAuthenticatedSiteRequestWithoutCookie() {
        let expectedRedirect = "http://example.com/some-page/?preview%3Dtrue%26preview_nonce%3D7ad6fc"
        let url = URL(string: "http://example.com/some-page/?preview=true&preview_nonce=7ad6fc")!
        let authenticator = siteAuthenticator

        let cookieJar = MockCookieJar()
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
        XCTAssertEqual(request.httpBodyString, "log=\(siteUser)&pwd=\(sitePasswordEncoded)&rememberme=true&redirect_to=\(expectedRedirect)")
    }

    func testAuthenticatedDotComRequestWithoutCookie() {
        let expectedRedirect = "https://wordpress.com/?wpios_redirect%3Dhttps://example.wordpress.com/some-page/"
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar()
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
        XCTAssertEqual(request.httpBodyString, "log=\(dotComUser)&rememberme=true&redirect_to=\(expectedRedirect)")
    }

    func testUnauthenticatedDotComRequestWithCookie() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)
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
