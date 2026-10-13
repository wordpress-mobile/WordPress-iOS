import XCTest
import WebKit
@testable import WordPress

class CookieJarTests: XCTestCase {
    var mockCookieJar = MockCookieJar()
    var cookieJar: CookieJar {
        return mockCookieJar
    }
    let wordPressComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!

    override func setUp() {
        super.setUp()
        mockCookieJar = MockCookieJar()
    }

    func testGetCookies() {
        addCookies()

        let expectation = self.expectation(description: "getCookies completion called")
        cookieJar.getCookies(url: wordPressComLoginURL) { cookies in
            XCTAssertEqual(cookies.count, 2)
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
}

private extension CookieJarTests {
    func addCookies() {
        mockCookieJar.setWordPressComCookie(username: "testuser")
        mockCookieJar.setWordPressCookie(username: "testuser", domain: "example.com")
    }
}
