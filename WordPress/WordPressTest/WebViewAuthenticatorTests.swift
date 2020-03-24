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
    let siteLoginURL = URL(string: "https://example.com/wp-login.php")!
    let siteUser = "siteuser"
    let sitePassword = "x>73R9&9;r&ju9$J499FmZ?2*Nii/?$8"
    let sitePasswordEncoded = "x%3E73R9%269;r%26ju9$J499FmZ?2*Nii/?$8"

    // MARK: - Cookies

    let selfHostedAuthCookies = "wordpress_test_cookie=WP+Cookie+check; path=/; secure, wordpress_sec_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7C6b4639402efdc086cefdb23c022645bf5d6860c658bd5795014fcd47e0dac6ad; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/wp-content/plugins; SameSite=None, wordpress_sec_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7C6b4639402efdc086cefdb23c022645bf5d6860c658bd5795014fcd47e0dac6ad; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/wp-admin; SameSite=None, wordpress_logged_in_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7Cb7afb00b8d8400e841c6dca1ea0a70d083c1365698da93756fce705d17d3ce71; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/; SameSite=None"

    var dotComAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(credentials: .dotCom(username: dotComUser, authToken: dotComToken, authenticationType: .regular))
    }

    var siteAuthenticator: WebViewAuthenticator {
        return WebViewAuthenticator(
            credentials: .siteLogin(loginURL: siteLoginURL, username: siteUser, password: sitePassword))
    }

    func testAuthenticatedSiteRequestWithoutCookie() {
        let loginURL = URL(string: "https://example.com/wp-login.php")
        let url = URL(string: "https://example.com/some-page/?preview=true&preview_nonce=7ad6fc")!
        let authenticator = siteAuthenticator
        let expectation = self.expectation(description: "Authorization cookies obtained")
        let cookieJar = MockCookieJar()

        stub(condition: { request in
            return request.url! == loginURL && request.httpMethod! == "POST"
        }) { _ in
            //let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(
                filePath: "",
                headers: [
                    "Content-Type": "text/html; charset=UTF-8",
                    "Set-Cookie": self.selfHostedAuthCookies])
        }

        authenticator.request(url: url, cookieJar: cookieJar) { request in
            cookieJar.hasWordPressSelfHostedAuthCookie(for: url, username: self.siteUser) { hasCookie in
                if hasCookie {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 0.2)
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
