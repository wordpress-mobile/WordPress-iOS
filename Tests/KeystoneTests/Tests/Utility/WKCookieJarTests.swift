import XCTest
import WebKit
@testable import WordPress

class WKCookieJarTests: XCTestCase {
    // The cookie store stops storing cookies once its data store is deallocated.
    var dataStore: WKWebsiteDataStore!
    var cookieJar: CookieJar {
        return dataStore.httpCookieStore
    }

    override func setUp() {
        super.setUp()
        dataStore = WKWebsiteDataStore.nonPersistent()
        addCookies()
    }

    override func tearDown() {
        dataStore = nil
        super.tearDown()
    }

    func testHasCookieMatching() {
        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false) { matches in
            XCTAssertTrue(matches, "Cookies should exist for wordpress.com + testuser")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testHasCookieNotMatching() {
        let expectation = self.expectation(description: "hasCookie completion called")
        cookieJar.hasWordPressComAuthCookie(username: "anotheruser", atomicSite: false) { matches in
            XCTAssertFalse(matches, "Cookies should not exist for wordpress.com + anotheruser")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSelfHostedAuthCookieIsScopedToItsSite() {
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
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRemoveCookies() {
        let expectation = self.expectation(description: "removeCookies completion called")
        cookieJar.removeWordPressComCookies { [dataStore] in
            dataStore!.httpCookieStore.getAllCookies { cookies in
                XCTAssertEqual(cookies.map(\.domain), ["example.com"])
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}

private extension WKCookieJarTests {
    func addCookies() {
        let expectation = self.expectation(description: "cookies set")
        expectation.expectedFulfillmentCount = 2
        dataStore.httpCookieStore.setWordPressComCookie(username: "testuser") {
            expectation.fulfill()
        }
        dataStore.httpCookieStore.setWordPressCookie(username: "testuser", domain: "example.com") {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
