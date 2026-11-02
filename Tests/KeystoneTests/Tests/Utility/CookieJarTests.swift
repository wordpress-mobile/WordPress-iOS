import XCTest
import WebKit
@testable import WordPress

class CookieJarTests: XCTestCase {
    var mockCookieJar = MockCookieJar()
    var cookieJar: CookieJar {
        return mockCookieJar
    }

    override func setUp() {
        super.setUp()
        mockCookieJar = MockCookieJar()
    }

    func testSelfHostedAuthCookieIsScopedToItsSite() {
        addCookies()

        let siteURL = URL(string: "https://example.com/wp-login.php")!
        let anotherSiteURL = URL(string: "https://example.org/wp-login.php")!

        let expectation = self.expectation(description: "hasCookie completion called")
        expectation.expectedFulfillmentCount = 2
        cookieJar.hasWordPressSelfHostedAuthCookie(for: siteURL, username: "testuser") { matches in
            XCTAssertTrue(matches)
            expectation.fulfill()
        }
        cookieJar.hasWordPressSelfHostedAuthCookie(for: anotherSiteURL, username: "testuser") { matches in
            XCTAssertFalse(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHasCookieMatching() {
        addCookies()

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false) { matches in
            XCTAssertTrue(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    func testHasCookieNotMatching() {
        addCookies()

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressComAuthCookie(username: "anotheruser", atomicSite: false) { matches in
            XCTAssertFalse(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHasCookieMatchingUsernameWithEncodedCharacters() {
        // Usernames containing characters that PHP URL-encodes (e.g. `@` in
        // `user@example.com`) arrive percent-encoded in the cookie value.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/26115
        mockCookieJar.setWordPressCookie(username: "user@example.com", domain: "example.com")

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressSelfHostedAuthCookie(for: URL(string: "https://example.com/")!, username: "user@example.com") { matches in
            XCTAssertTrue(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHasCookieMatchingUsernameWithSpaces() {
        // PHP's urlencode turns spaces into `+`.
        mockCookieJar.setWordPressCookie(username: "john doe", domain: "example.com")

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressSelfHostedAuthCookie(for: URL(string: "https://example.com/")!, username: "john doe") { matches in
            XCTAssertTrue(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHasCookieNotMatchingDifferentUsernameWithEncodedCharacters() {
        mockCookieJar.setWordPressCookie(username: "user@example.com", domain: "example.com")

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressSelfHostedAuthCookie(for: URL(string: "https://example.com/")!, username: "other@example.com") { matches in
            XCTAssertFalse(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveCookies() {
        addCookies()

        let expectation = self.expectation(description: "removeCookies completion called")
        cookieJar.removeWordPressComCookies { [mockCookieJar] in
            XCTAssertEqual(mockCookieJar.cookies?.count, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExpiredAuthCookieDoesNotMatch() {
        mockCookieJar.setCookie(
            loggedInCookie(domain: ".wordpress.com", path: "/", expires: Date(timeIntervalSinceNow: -60))
        )

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false) { matches in
            XCTAssertFalse(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAuthCookieMatchesHostCaseInsensitively() {
        mockCookieJar.setCookie(loggedInCookie(domain: "example.com", path: "/"))

        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressSelfHostedAuthCookie(
            for: URL(string: "https://Example.com/wp-login.php")!,
            username: "testuser"
        ) { matches in
            XCTAssertTrue(matches)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAuthCookiePathMatchesWholeSegments() {
        mockCookieJar.setCookie(loggedInCookie(domain: "example.com", path: "/blog"))

        let urls: [(String, Bool)] = [
            ("https://example.com/blog", true),
            ("https://example.com/blog/", true),
            ("https://example.com/blog/wp-login.php", true),
            ("https://example.com/blogger/wp-login.php", false),
            ("https://example.com/wp-login.php", false)
        ]
        let expectation = self.expectation(description: "hasCookie completion called")
        expectation.expectedFulfillmentCount = urls.count
        for (url, expected) in urls {
            cookieJar.hasWordPressSelfHostedAuthCookie(for: URL(string: url)!, username: "testuser") { matches in
                XCTAssertEqual(matches, expected, url)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}

private extension CookieJarTests {
    func addCookies() {
        mockCookieJar.setWordPressComCookie(username: "testuser")
        mockCookieJar.setWordPressCookie(username: "testuser", domain: "example.com")
    }

    func loggedInCookie(domain: String, path: String, expires: Date? = nil) -> HTTPCookie {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .domain: domain,
            .path: path,
            .name: "wordpress_logged_in",
            .value: "testuser%7C00000"
        ]
        properties[.expires] = expires
        return HTTPCookie(properties: properties)!
    }
}
