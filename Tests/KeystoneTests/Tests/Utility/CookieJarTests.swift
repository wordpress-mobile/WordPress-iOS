import Foundation
import Testing
@testable import WordPress

struct CookieJarTests {
    private let mockCookieJar = MockCookieJar()
    private var cookieJar: CookieJar {
        mockCookieJar
    }

    init() {
        mockCookieJar.setWordPressComCookie(username: "testuser")
        mockCookieJar.setWordPressCookie(username: "testuser", domain: "example.com")
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

        #expect(mockCookieJar.cookies?.map(\.domain) == ["example.com"])
    }
}
