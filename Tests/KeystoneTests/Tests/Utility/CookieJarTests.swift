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

    @Test func hasCookieMatchingUsernameWithEncodedCharacters() async throws {
        // Usernames containing characters that PHP URL-encodes (e.g. `@` in
        // `user@example.com`) arrive percent-encoded in the cookie value.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/26115
        mockCookieJar.setWordPressCookie(username: "user@example.com", domain: "example.com")
        let url = try #require(URL(string: "https://example.com/"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: url, username: "user@example.com")
        #expect(hasCookie)
    }

    @Test func hasCookieMatchingUsernameWithSpaces() async throws {
        // PHP's urlencode turns spaces into `+`.
        mockCookieJar.setWordPressCookie(username: "john doe", domain: "example.com")
        let url = try #require(URL(string: "https://example.com/"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: url, username: "john doe")
        #expect(hasCookie)
    }

    @Test func hasCookieNotMatchingDifferentUsernameWithEncodedCharacters() async throws {
        mockCookieJar.setWordPressCookie(username: "user@example.com", domain: "example.com")
        let url = try #require(URL(string: "https://example.com/"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: url, username: "other@example.com")
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

    @Test func expiredAuthCookieDoesNotMatch() async {
        let cookieJar = makeCookieJar(
            holding: loggedInCookie(domain: ".wordpress.com", path: "/", expires: Date(timeIntervalSinceNow: -60))
        )

        let hasCookie = await cookieJar.hasWordPressComAuthCookie(username: "testuser", atomicSite: false)
        #expect(!hasCookie)
    }

    @Test func authCookieMatchesHostCaseInsensitively() async throws {
        let cookieJar = makeCookieJar(holding: loggedInCookie(domain: "example.com", path: "/"))
        let url = try #require(URL(string: "https://Example.com/wp-login.php"))

        let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(for: url, username: "testuser")
        #expect(hasCookie)
    }

    @Test func authCookiePathMatchesWholeSegments() async throws {
        let cookieJar = makeCookieJar(holding: loggedInCookie(domain: "example.com", path: "/blog"))

        let urls: [(String, Bool)] = [
            ("https://example.com/blog", true),
            ("https://example.com/blog/", true),
            ("https://example.com/blog/wp-login.php", true),
            ("https://example.com/blogger/wp-login.php", false),
            ("https://example.com/wp-login.php", false)
        ]
        for (url, expected) in urls {
            let hasCookie = await cookieJar.hasWordPressSelfHostedAuthCookie(
                for: try #require(URL(string: url)),
                username: "testuser"
            )
            #expect(hasCookie == expected, "\(url)")
        }
    }
}

private extension CookieJarTests {
    /// A cookie jar without the cookies that `init` adds, so that only `cookie` can match.
    func makeCookieJar(holding cookie: HTTPCookie) -> CookieJar {
        let cookieJar = MockCookieJar()
        cookieJar.setCookie(cookie)
        return cookieJar
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
