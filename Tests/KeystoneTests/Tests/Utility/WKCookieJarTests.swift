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

    func testRemoveCookiesWhenTheCookieReadIsSlow() {
        let expectation = self.expectation(description: "removeCookies completion called")
        cookieJar.removeWordPressComCookies { [dataStore] in
            dataStore!.httpCookieStore
                .getAllCookies { cookies in
                    XCTAssertEqual(cookies.map(\.domain), ["example.com"])
                    expectation.fulfill()
                }
        }
        // WebKit replies on the main thread, so keeping it busy delays the cookie read.
        // The removal has to wait for that read, however long it takes.
        Thread.sleep(forTimeInterval: 2.5)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRemoveCookiesAfterTheCookieStoreIsReleased() {
        let expectation = self.expectation(description: "removeCookies completion called")
        // Once the pool drains, only the removal in progress holds the cookie store.
        autoreleasepool {
            let cookieJar: CookieJar = WKWebsiteDataStore.nonPersistent().httpCookieStore
            cookieJar.removeWordPressComCookies {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetCookiesFromADataStoreThatHasNotBeenUsedYet() {
        // `getAllCookies` can report no cookies for a data store that has not been in touch with
        // WebKit's network process yet, whatever that data store has saved.

        // Always the same identifier, so that a removal that fails leaves one data store behind
        // and not one for every run.
        let identifier = UUID(uuidString: "0DBBAB0A-FAFA-40CD-A8DF-32A08C939D3D")!
        addTeardownBlock {
            try? await WKWebsiteDataStore.remove(forIdentifier: identifier)
        }

        weak var dataStoreThatSavedTheCookie: WKWebsiteDataStore?
        autoreleasepool {
            let dataStore = WKWebsiteDataStore(forIdentifier: identifier)
            dataStoreThatSavedTheCookie = dataStore
            let cookie = HTTPCookie(properties: [
                .domain: ".wordpress.com",
                .path: "/",
                .name: "saved",
                .value: "value",
                .expires: Date(timeIntervalSinceNow: 3600)
            ])!
            let expectation = self.expectation(description: "cookie set")
            dataStore.httpCookieStore.setCookie(cookie) {
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
        }
        // WebKit hands out the same object, which has been in touch, for as long as it is alive.
        XCTAssertNil(dataStoreThatSavedTheCookie)

        autoreleasepool {
            let cookieJar: CookieJar = WKWebsiteDataStore(forIdentifier: identifier).httpCookieStore
            let expectation = self.expectation(description: "getCookies completion called")
            cookieJar.getCookies { cookies in
                XCTAssertEqual(cookies.map(\.name), ["saved"])
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
        }
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
