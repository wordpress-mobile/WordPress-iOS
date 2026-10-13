import Foundation
import Testing
import WebKit
@testable import WordPress

@MainActor
struct WKCookieJarTests {
    // The cookie store stops storing cookies once its data store is deallocated.
    private let dataStore = WKWebsiteDataStore.nonPersistent()
    private var cookieJar: CookieJar {
        dataStore.httpCookieStore
    }

    init() async {
        await dataStore.httpCookieStore.setWordPressComCookie(username: "testuser")
        await dataStore.httpCookieStore.setWordPressCookie(username: "testuser", domain: "example.com")
    }

    @Test func hasWordPressComAuthCookieForMatchingUser() async {
        let hasCookie = await cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false)
        #expect(hasCookie)
    }

    @Test func hasNoWordPressComAuthCookieForAnotherUser() async {
        let hasCookie = await cookieJar.hasWordPressComAuthCookie(username: "anotheruser", atomicSite: false)
        #expect(!hasCookie)
    }

    @Test func selfHostedAuthCookieIsScopedToItsSite() async throws {
        let siteURL = try #require(URL(string: "https://example.com/wp-login.php"))
        let anotherSiteURL = try #require(URL(string: "https://example.org/wp-login.php"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: siteURL, username: "testuser")
        let hasCookieForAnotherSite = await cookieJar.hasWordPressSelfHostedAuthCookie(
            for: anotherSiteURL,
            username: "testuser"
        )

        #expect(hasCookie)
        #expect(!hasCookieForAnotherSite)
    }

    @Test func removeWordPressComCookiesKeepsOtherCookies() async {
        await cookieJar.removeWordPressComCookies()

        let cookies = await dataStore.httpCookieStore.allCookies()
        #expect(cookies.map(\.domain) == ["example.com"])
    }
}
