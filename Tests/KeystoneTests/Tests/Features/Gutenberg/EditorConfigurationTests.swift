import XCTest
import CoreData
import GutenbergKit
@testable import WordPress
@testable import WordPressData

class EditorConfigurationTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = ContextManager.forTesting().mainContext
    }

    override func tearDown() {
        // Clean up any cookies we added during testing
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        context = nil
        super.tearDown()
    }

    // MARK: - WordPress.com Private Site Cookie Tests

    func testEditorConfigurationIncludesCookieForPrivateWPComSiteWhenCookieExists() {
        // Given: A private WordPress.com site
        let blog = createPrivateWordPressComBlog()
        let expectedCookieValue = "testuser%1234567890abcdef"
        let blogHost = URL(string: blog.url ?? "")?.host ?? blog.primaryDomainAddress

        addWordPressLoggedInCookieToSystem(value: expectedCookieValue, domain: blogHost)

        // When: Creating an EditorConfiguration using the actual implementation
        let configuration = EditorConfiguration(blog: blog)

        // Then: The configuration should include the wordpress_logged_in cookie
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 1, "Should include wordpress_logged_in cookie for private WP.com sites when cookie exists")

        if let cookie = wordPressCookies.first {
            XCTAssertEqual(cookie.value, expectedCookieValue, "Cookie value should match the system cookie value")
            XCTAssertEqual(cookie.domain, blog.primaryDomainAddress, "Cookie domain should match the site domain")
            XCTAssertTrue(cookie.isSecure, "Cookie should be secure")
            XCTAssertEqual(cookie.path, "/", "Cookie path should be root")
        }
    }

    func testEditorConfigurationDoesNotIncludeCookieForPrivateWPComSiteWhenNoCookieExists() {
        // Given: A private WordPress.com site with no existing cookie
        let blog = createPrivateWordPressComBlog()
        // Ensure no wordpress_logged_in cookies exist
        removeAllWordPressLoggedInCookies()

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: The configuration should not include any wordpress_logged_in cookies
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 0, "Should not include wordpress_logged_in cookie when none exists in system storage")
    }

    func testEditorConfigurationDoesNotIncludeCookieForPublicWPComSite() {
        // Given: A public WordPress.com site with an existing cookie
        let blog = createPublicWordPressComBlog()
        let domain = URL(string: blog.url ?? "")?.host ?? blog.primaryDomainAddress

        addWordPressLoggedInCookieToSystem(value: "testuser%1234567890abcdef", domain: domain)

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: The configuration should not include wordpress_logged_in cookies for public sites
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 0, "Should not include wordpress_logged_in cookie for public WP.com sites")
    }

    func testEditorConfigurationDoesNotIncludeCookieForSelfHostedSite() {
        // Given: A self-hosted site (even if private)
        let blog = createSelfHostedBlog()
        let domain = URL(string: blog.url ?? "")?.host ?? blog.primaryDomainAddress

        addWordPressLoggedInCookieToSystem(value: "testuser%1234567890abcdef", domain: domain)

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: The configuration should not include wordpress_logged_in cookies for self-hosted sites
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 0, "Should not include wordpress_logged_in cookie for self-hosted sites")
    }

    func testEditorConfigurationIncludesCorrectCookieFromMultipleCandidates() {
        // Given: A private WordPress.com site with multiple wordpress_logged_in cookies
        let blog = createPrivateWordPressComBlog()
        let primaryCookieValue = "testuser%primary123"
        let secondaryCookieValue = "testuser%secondary456"
        let domain = (URL(string: blog.url ?? "")?.host) ?? blog.primaryDomainAddress

        // Add multiple cookies with different names
        addWordPressLoggedInCookieToSystem(name: "wordpress_logged_in", value: primaryCookieValue, domain: domain)
        addWordPressLoggedInCookieToSystem(name: "wordpress_logged_in_abc123", value: secondaryCookieValue, domain: domain)

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: Should include exactly one cookie (the first one found)
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 1, "Should include exactly one wordpress_logged_in cookie")

        if let cookie = wordPressCookies.first {
            // Should be one of the expected values (implementation determines which one is selected first)
            XCTAssertTrue([primaryCookieValue, secondaryCookieValue].contains(cookie.value),
                         "Cookie value should be one of the cookies from system storage")
        }
    }

    func testEditorConfigurationHandlesAtomicSiteCookieFormat() {
        // Given: A private Atomic WordPress.com site
        let blog = createPrivateAtomicBlog()
        let atomicCookieValue = "testuser|1544455667|KwKSrAKJsqIWCTtt2QImT3hFTgHuzDOaMprlWWZXQeQ|7f0a75827e7f72ce645ec817ac9a2ab58735e95752494494cc463d1ad5853add"
        let domain = (URL(string: blog.url ?? "")?.host) ?? blog.primaryDomainAddress

        addWordPressLoggedInCookieToSystem(value: atomicCookieValue, domain: domain)

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: Should handle atomic cookie format correctly
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 1, "Should include wordpress_logged_in cookie for private Atomic sites")

        if let cookie = wordPressCookies.first {
            XCTAssertEqual(cookie.value, atomicCookieValue, "Should preserve atomic cookie format")
            XCTAssertTrue(cookie.value.contains("|"), "Atomic cookie should contain pipe separators")
        }
    }

    func testEditorConfigurationCookieNamePreservation() {
        // Given: A private WordPress.com site with a hashed cookie name
        let blog = createPrivateWordPressComBlog()
        let hashedCookieName = "wordpress_logged_in_39d5e8179c238764ac288442f27d091b"
        let cookieValue = "testuser%1234567890abcdef"
        let domain = (URL(string: blog.url ?? "")?.host) ?? blog.primaryDomainAddress

        addWordPressLoggedInCookieToSystem(name: hashedCookieName, value: cookieValue, domain: domain)

        // When: Creating an EditorConfiguration
        let configuration = EditorConfiguration(blog: blog)

        // Then: Should preserve the original cookie name
        let wordPressCookies = configuration.cookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        XCTAssertEqual(wordPressCookies.count, 1, "Should include the hashed wordpress_logged_in cookie")

        if let cookie = wordPressCookies.first {
            XCTAssertEqual(cookie.name, hashedCookieName, "Should preserve the original hashed cookie name")
            XCTAssertEqual(cookie.value, cookieValue, "Should preserve the cookie value")
        }
    }

    // MARK: - Helper Methods

    private func createPrivateWordPressComBlog() -> Blog {
        return BlogBuilder(context)
            .with(isHostedAtWPCom: true)
            .with(siteName: "Private Site")
            .with(siteVisibility: .private)
            .with(url: "https://privatesite.wordpress.com")
            .build()
    }

    private func createPublicWordPressComBlog() -> Blog {
        return BlogBuilder(context)
            .with(isHostedAtWPCom: true)
            .with(siteName: "Public Site")
            .with(siteVisibility: .public)
            .with(url: "https://publicsite.wordpress.com")
            .build()
    }

    private func createSelfHostedBlog() -> Blog {
        return BlogBuilder(context)
            .with(isHostedAtWPCom: false)
            .with(siteName: "Self Hosted Site")
            .with(url: "https://selfhosted.example.com")
            .build()
    }

    private func createPrivateAtomicBlog() -> Blog {
        return BlogBuilder(context)
            .with(isHostedAtWPCom: true)
            .with(siteName: "Atomic Site")
            .with(atomic: true)
            .with(siteVisibility: .private)
            .with(url: "https://atomic.wordpress.com")
            .build()
    }

    private func addWordPressLoggedInCookieToSystem(name: String = "wordpress_logged_in", value: String, domain: String) {
        let cookie = HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: value,
            .secure: true
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
    }

    private func removeAllWordPressLoggedInCookies() {
        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        let wordPressCookies = allCookies.filter { $0.name.hasPrefix("wordpress_logged_in") }
        for cookie in wordPressCookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
