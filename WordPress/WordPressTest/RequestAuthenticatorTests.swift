import XCTest
@testable import WordPress
import OHHTTPStubs

private extension URLRequest {
    var httpBodyString: String? {
        return httpBody.flatMap({ data in
            return String(data: data, encoding: .utf8)
        })
    }
}

class RequestAuthenticatorTests: XCTestCase {
    let dotComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!
    let dotComUser = "comuser"
    let dotComToken = "comtoken"
    let siteLoginURL = URL(string: "https://example.com/wp-login.php")!
    let siteUser = "siteuser"
    let sitePassword = "x>73R9&9;r&ju9$J499FmZ?2*Nii/?$8"
    let sitePasswordEncoded = "x%3E73R9%269;r%26ju9$J499FmZ?2*Nii/?$8"

    // MARK: - Cookies

    let selfHostedAuthCookies = "wordpress_test_cookie=WP+Cookie+check; path=/; secure, wordpress_sec_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7C6b4639402efdc086cefdb23c022645bf5d6860c658bd5795014fcd47e0dac6ad; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/wp-content/plugins; SameSite=None, wordpress_sec_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7C6b4639402efdc086cefdb23c022645bf5d6860c658bd5795014fcd47e0dac6ad; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/wp-admin; SameSite=None, wordpress_logged_in_ef1631b592f07561aae70fbd1ee1e768=siteuser%7C1586285558%7CTLyGwaryk81cmBFnizrj2uQju5Y9K7Y4gVTc4M4N21F%7Cb7afb00b8d8400e841c6dca1ea0a70d083c1365698da93756fce705d17d3ce71; expires=Wed, 08 Apr 3020 06:52:38 GMT;secure; HttpOnly; path=/; SameSite=None"
    let wpComAuthCookies = "wordpress_test_cookie=WP+Cookie+check; path=/; domain=.wordpress.com; secure, recognized_logins=uNdWIS9WV3eDx26Krcur2-7FL3rT-yChl0fovl6JYznIoqxe2P6uelkXWmsdzeMmHd4Nxg22nsFbh00MDVj1; expires=Sat, 23-Sep-2023 07:58:01 GMT; Max-Age=110376000; path=/; domain=wordpress.com; secure; HttpOnly, wordpress=comuser%7C1679587881%7CZ6LgnUJJBPfwh7Tjszh7FbgQ1Klr70r2sIDfGQLMlMY%7C976df5f2b2edbabf7c0d098f6a1764c7f8ea948e39c747e673822fefed09a431; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-content/plugins; domain=.wordpress.com; HttpOnly, wordpress=comuser%7C1679587881%7CZ6LgnvJJbPmwh8Tjszh7Fbg1aKlr70r2sIDfGQLMlMY%7C976df5f2b0eddebf7c0d098f6a1764c7f8ea948e39c747e673822fefed09a431; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-admin; domain=.wordpress.com; HttpOnly, wordpress_logged_in=comuser%7C1679587881%uCz6LgnUJJvpmwh8Tjszh7FbgQ1Klr70r2sIDfGQLo0MY%7Ce8a22bb97b915bdefab8be0ab63ec4fe6f82d88c34b47c1a62bd9510c89b0073; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/; domain=.wordpress.com; HttpOnly, wordpress=comuser%7C1679587881%7CZ6LgnUjJBPmwh8Tjszh7FbgQ1Klr70o0sIDfGQLMlMY%7C976df5f2b0edbabf7c0d098f6a1764c7f8ea948e39c747e673822fefed09a431; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-content/plugins; domain=.wordpress.com; secure; HttpOnly, wordpress=comuser%7C1679597881%7CZ6LgnUJJBPmwh8Tjszh7FbgQ1Klr71Y2sIDfGQLMlMY%7C976df5f2b0edbabf7c0d098f6a1764c7f8ea948e39c747e673822fefed09a431; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-admin; domain=.wordpress.com; secure; HttpOnly, wordpress_logged_in=comuser%7C1679587881%7CZ6LgnUJJBPmwh8TjshY7FbgQ1Klr70r2sIDfGQLMlMY%7Ce8a22bb97b915bdefab8be0ab63ec4fe6f82d88c34b47c1a62bd9510c89b0073; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/; domain=.wordpress.com; secure; HttpOnly, wordpress_sec=comuser%7C1679587881%7CZ6LgnUJJBPmwh8Tjszh7F00Q1Klr70r2sIDfGQLMlMY%7Cc5577c02994f8e5ed884548e6ff344b7a0147607959598ab0adf7128272780c6; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-content/plugins; domain=.wordpress.com; secure; HttpOnly, wordpress_sec=comuser%7C1679587881%7CZ6LgnUJJBPmwh8TjZSh7FbgQ1Klr70r2sIDfGQLMlMY%7Cc5577c02994f8e5ed884548e6ff344b7a0147607959598ab0adf7128272780c6; expires=Fri, 24 Mar 2023 19:58:01 GMT;path=/wp-admin; domain=.wordpress.com; secure; HttpOnly"

    var dotComAuthenticator: RequestAuthenticator {
        return RequestAuthenticator(credentials: .dotCom(username: dotComUser, authToken: dotComToken, authenticationType: .regular))
    }

    var siteAuthenticator: RequestAuthenticator {
        return RequestAuthenticator(
            credentials: .siteLogin(loginURL: siteLoginURL, username: siteUser, password: sitePassword))
    }

    func testAuthenticatedSiteRequestWithoutCookie() {
        let url = URL(string: "https://example.com/some-page/?preview=true&preview_nonce=7ad6fc")!
        let authenticator = siteAuthenticator
        let cookieJar = MockCookieJar()
        let expectation = self.expectation(description: "Authorization cookies obtained")

        stub(condition: { request in
            return request.url! == self.siteLoginURL && request.httpMethod! == "POST"
        }) { _ in
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
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        let expectation = self.expectation(description: "Authorization cookies obtained")

        stub(condition: { request in
            return request.url! == self.dotComLoginURL && request.httpMethod! == "POST"
        }) { _ in
            return fixture(
                filePath: "",
                headers: [
                    "Content-Type": "text/html; charset=UTF-8",
                    "Set-Cookie": self.wpComAuthCookies])
        }

        authenticator.request(url: url, cookieJar: cookieJar) { request in
            cookieJar.hasWordPressComAuthCookie(username: self.dotComUser, atomicSite: false) { hasCookie in
                if hasCookie {
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 0.2)
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

    func testDecideActionForNavigationResponse() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.allow)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }

    func testDecideActionForNavigationResponse_RemoteLoginError() {
        let url = URL(string: "https://r-login.wordpress.com/remote-login.php?action=auth")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.reload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }

    func testDecideActionForNavigationResponse_ClientError() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.reload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }
}
