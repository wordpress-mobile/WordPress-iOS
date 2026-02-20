import Testing
@testable import WordPressData

@MainActor
@Suite("Blog Tests")
struct BlogTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - Atomic Tests

    @Test func isAtomic() {
        let blog = BlogBuilder(mainContext)
            .with(atomic: true)
            .build()

        #expect(blog.isAtomic)
    }

    @Test func isNotAtomic() {
        let blog = BlogBuilder(mainContext)
            .with(atomic: false)
            .build()

        #expect(!blog.isAtomic)
    }

    // MARK: - Blog Lookup

    @Test func lookupByBlogIDWorks() throws {
        let blog = BlogBuilder(mainContext).build()
        #expect(blog.dotComID != nil)
        #expect(Blog.lookup(withID: blog.dotComID!, in: mainContext) != nil)
    }

    @Test func lookupByBlogIDFailsForInvalidBlogID() {
        #expect(Blog.lookup(withID: NSNumber(integerLiteral: 1), in: mainContext) == nil)
    }

    @Test func lookupByBlogIDWorksForIntegerBlogID() throws {
        let blog = BlogBuilder(mainContext).build()
        #expect(blog.dotComID != nil)
        #expect(try Blog.lookup(withID: blog.dotComID!.intValue, in: mainContext) != nil)
    }

    @Test func lookupByBlogIDFailsForInvalidIntegerBlogID() throws {
        #expect(try Blog.lookup(withID: 1, in: mainContext) == nil)
    }

    @Test func lookupBlogIDWorksForInt64BlogID() throws {
        let blog = BlogBuilder(mainContext).build()
        #expect(blog.dotComID != nil)
        #expect(try Blog.lookup(withID: blog.dotComID!.int64Value, in: mainContext) != nil)
    }

    @Test func lookupByBlogIDFailsForInvalidInt64BlogID() throws {
        #expect(try Blog.lookup(withID: Int64(1), in: mainContext) == nil)
    }

    // MARK: - Post Lookup

    @Test func lookupPostWorks() {
        let context = contextManager.newDerivedContext()
        let blog = BlogBuilder(context)
            .set(blogOption: "foo", value: "bar")
            .build()
        let post = PostBuilder(context, blog: blog).build()
        post.postID = NSNumber(value: Int64.max)
        contextManager.saveContextAndWait(context)

        #expect(blog.lookupPost(withID: post.postID!, in: mainContext)?.managedObjectContext === mainContext)
        #expect(blog.lookupPost(withID: post.postID!, in: context)?.managedObjectContext === context)
    }

    // MARK: - Plugin Management

    @Test func pluginManagementIsDisabledForSimpleSites() {
        let blog = BlogBuilder(mainContext)
            .with(atomic: true)
            .build()

        #expect(!blog.supports(.pluginManagement))
    }

    @Test func pluginManagementIsEnabledForBusinessPlans() {
        let blog = BlogBuilder(mainContext)
            .with(isHostedAtWPCom: true)
            .with(planID: 1008) // Business plan
            .with(isAdmin: true)
            .build()

        #expect(blog.supports(.pluginManagement))
    }

    @Test func pluginManagementIsDisabledForPrivateSites() {
        let blog = BlogBuilder(mainContext)
            .with(isHostedAtWPCom: true)
            .with(planID: 1008) // Business plan
            .with(isAdmin: true)
            .with(siteVisibility: .private)
            .build()

        #expect(!blog.supports(.pluginManagement))
    }

    // FIXME: Crashes because WPAccount fixture sets username and triggers BuildSettings access
//    @Test func pluginManagementIsEnabledForJetpack() {
//        let blog = BlogBuilder(mainContext)
//            .withAnAccount()
//            .withJetpack(version: "5.6", username: "test_user", email: "user@example.com")
//            .with(isHostedAtWPCom: false)
//            .with(isAdmin: true)
//            .build()
//
//        #expect(blog.supports(.pluginManagement))
//    }

    @Test func pluginManagementIsDisabledForWordPress54AndBelow() {
        let blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.4")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: true)
            .build()

        #expect(!blog.supports(.pluginManagement))
    }

    @Test func pluginManagementIsEnabledForWordPress55AndAbove() {
        let blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.5")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: true)
            .build()

        withKnownIssue("Fails because it gets a nil WordPressOrgRestApi instance") {
            #expect(blog.supports(.pluginManagement))
        }
    }

    @Test func pluginManagementIsDisabledForNonAdmins() {
        let blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.5")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: false)
            .build()

        #expect(!blog.supports(.pluginManagement))
    }

    // MARK: - Stats

    @Test func statsActiveForSitesHostedAtWPCom() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(modules: [""])
            .build()

        #expect(blog.isStatsActive())
    }

    @Test func statsActiveForSitesNotHostedAtWPCom() {
        let blog = BlogBuilder(mainContext)
            .isNotHostedAtWPcom()
            .with(modules: ["stats"])
            .build()

        #expect(blog.isStatsActive())
    }

    @Test func statsNotActiveForSitesNotHostedAtWPCom() {
        let blog = BlogBuilder(mainContext)
            .isNotHostedAtWPcom()
            .with(modules: [""])
            .build()

        #expect(!blog.isStatsActive())
    }

    // MARK: - Blog.version String Conversion

    @Test func versionIsAStringWhenGivenANumber() {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "software_version", value: 13.37)
            .build()

        #expect((blog.version as Any) is String)
        #expect(blog.version == "13.37")
    }

    @Test func versionIsAStringWhenGivenAString() {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "software_version", value: "5.5")
            .build()

        #expect((blog.version as Any) is String)
        #expect(blog.version == "5.5")
    }

    @Test func versionDefaultsToEmptyStringWhenValueIsNotConvertible() {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "software_version", value: NSObject())
            .build()

        #expect((blog.version as Any) is String)
        #expect(blog.version == "")
    }

    // FIXME: Crashes because WPAccount fixture sets username and triggers BuildSettings access
//    @Test func removeDuplicates() async throws {
//        let xmlrpc = "https://xmlrpc.test.wordpress.com"
//        let account = try await contextManager.performAndSave { context in
//            let account = WPAccount.fixture(context: context)
//            account.blogs = Set(
//                (1...10).map { _ in
//                    let blog = BlogBuilder(context).build()
//                    blog.xmlrpc = xmlrpc
//                    return blog
//                }
//            )
//            return account
//        }
//        #expect(try mainContext.count(for: Blog.fetchRequest()) == 10)
//
//        try await contextManager.performAndSave { context in
//            let accountInContext = try #require(context.existingObject(with: account.objectID) as? WPAccount)
//            let blog = Blog.lookup(xmlrpc: xmlrpc, andRemoveDuplicateBlogsOf: accountInContext, in: context)
//            #expect(blog != nil)
//        }
//
//        #expect(try mainContext.count(for: Blog.fetchRequest()) == 1)
//    }

    // MARK: - Blog Feature: Domains

    @Test func blogSupportsDomainsHostedAtWPcom() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .build()

        #expect(blog.supports(.domains), "Domains should be supported for WPcom hosted blogs")
    }

    @Test func blogSupportsDomainsAtomic() {
        let blog = BlogBuilder(mainContext)
            .isNotHostedAtWPcom()
            .with(atomic: true)
            .with(isAdmin: true)
            .build()

        #expect(blog.supports(.domains), "Domains should be supported for Atomic blogs")
    }

    @Test func domainsNotSupportedForNonAdmin() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: false)
            .build()

        #expect(!blog.supports(.domains), "Domains should not be supported for non-admin users")
    }

    @Test func domainsNotSupportedForP2Sites() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .with(isWPForTeamsSite: true)
            .build()

        #expect(!blog.supports(.domains), "Domains should not be supported when the site is P2 site")
    }

    // MARK: - displayURL

    @Test func displayURLStripsHTTP() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()

        #expect(blog.displayURL == "example.com")
    }

    @Test func displayURLStripsHTTPS() {
        let blog = BlogBuilder(mainContext)
            .with(url: "https://example.com")
            .build()

        #expect(blog.displayURL == "example.com")
    }

    @Test func displayURLStripsTrailingSlash() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com/")
            .build()

        #expect(blog.displayURL == "example.com")
    }

    @Test func displayURLPreservesPath() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com/sub")
            .build()

        #expect(blog.displayURL == "example.com/sub")
    }

    @Test func displayURLReturnsNilForNilURL() {
        let blog = BlogBuilder(mainContext).build()
        blog.url = nil

        #expect(blog.displayURL == nil)
    }

    @Test func displayURLIsCaseInsensitiveForProtocol() {
        let blog = BlogBuilder(mainContext)
            .with(url: "HTTP://example.com")
            .build()

        #expect(blog.displayURL == "example.com")
    }

    @Test func displayURLDecodesIDNPunycode() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://test.xn--soymao-0wa.com")
            .build()

        #expect(blog.displayURL == "test.soymaño.com")
    }

    // MARK: - homeURL

    @Test func homeURLReturnsOptionWhenSet() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .set(blogOption: "home_url", value: "http://home.example.com")
            .build()

        #expect(blog.homeURL == "http://home.example.com")
    }

    @Test func homeURLFallsBackToURL() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()

        #expect(blog.homeURL == "http://example.com")
    }

    // MARK: - hostname

    @Test func hostnameExtractsFromXmlrpc() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()
        blog.xmlrpc = "http://example.com/xmlrpc.php"

        #expect(blog.hostname == "example.com")
    }

    @Test func hostnameStripsPath() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com/blog")
            .build()
        blog.xmlrpc = nil

        #expect(blog.hostname == "example.com")
    }

    // MARK: - loginURL

    @Test func loginURLReturnsOptionWhenSet() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .set(blogOption: "login_url", value: "http://example.com/custom-login")
            .build()

        #expect(blog.loginURL == URL(string: "http://example.com/custom-login"))
    }

    @Test func loginURLFallsBackToWpLogin() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()
        blog.xmlrpc = "http://example.com/xmlrpc.php"

        #expect(blog.loginURL == URL(string: "http://example.com/wp-login.php"))
    }

    // MARK: - urlWithPath

    @Test func urlWithPathReplacesXmlrpc() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()
        blog.xmlrpc = "http://example.com/xmlrpc.php"

        #expect(blog.url(withPath: "wp-admin/") == "http://example.com/wp-admin/")
    }

    @Test func urlWithPathReturnsNilForNilXmlrpc() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()
        blog.xmlrpc = nil

        #expect(blog.url(withPath: "wp-login.php") == nil)
    }

    @Test func urlWithPathWorksWithSubdirectory() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com/blog")
            .build()
        blog.xmlrpc = "http://example.com/blog/xmlrpc.php"

        #expect(blog.url(withPath: "wp-login.php") == "http://example.com/blog/wp-login.php")
    }

    // MARK: - makeAdminURL

    @Test func makeAdminURLUsesOptionWhenSet() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .set(blogOption: "admin_url", value: "http://example.com/wp-admin/")
            .build()

        #expect(blog.makeAdminURL(path: "options.php") == URL(string: "http://example.com/wp-admin/options.php"))
    }

    @Test func makeAdminURLFallsBackToXmlrpcBased() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .build()
        blog.xmlrpc = "http://example.com/xmlrpc.php"

        #expect(blog.makeAdminURL(path: "options.php") == URL(string: "http://example.com/wp-admin/options.php"))
    }

    @Test func makeAdminURLAddsTrailingSlash() {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .set(blogOption: "admin_url", value: "http://example.com/wp-admin")
            .build()

        #expect(blog.makeAdminURL(path: "options.php") == URL(string: "http://example.com/wp-admin/options.php"))
    }

    // MARK: - timeZone

    @Test func timeZoneDefaultsToGMTWhenNoOptions() {
        let blog = BlogBuilder(mainContext).build()

        #expect(blog.timeZone == TimeZone(secondsFromGMT: 0))
    }

    @Test func timeZoneDefaultsToGMTForNilOptions() {
        let blog = BlogBuilder(mainContext).build()
        blog.options = nil

        #expect(blog.timeZone == TimeZone(secondsFromGMT: 0))
    }

    @Test func timeZoneDefaultsToGMTForEmptyOptions() {
        let blog = BlogBuilder(mainContext).build()
        blog.options = [:]

        #expect(blog.timeZone == TimeZone(secondsFromGMT: 0))
    }

    @Test func timeZoneUsesTimeZoneNameOption() {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "timezone", value: "America/Chicago")
            .build()

        #expect(blog.timeZone == TimeZone(identifier: "America/Chicago"))
    }

    @Test(arguments: [
        (-5, -5 * 3600),
        (5.5, 5 * 3600 + 1800),
    ] as [(Double, Int)])
    func timeZoneUsesGMTOffsetOption(offset: Double, expectedSeconds: Int) {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "gmt_offset", value: offset)
            .build()

        #expect(blog.timeZone == TimeZone(secondsFromGMT: expectedSeconds))
    }

    @Test(arguments: [
        ("-11", -11 * 3600),
        ("5.5", 5 * 3600 + 1800),
    ] as [(String, Int)])
    func timeZoneUsesXMLRPCTimeZoneOption(value: String, expectedSeconds: Int) {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "time_zone", value: value)
            .build()

        #expect(blog.timeZone == TimeZone(secondsFromGMT: expectedSeconds))
    }

    @Test func timeZonePrefersNameOverGMTOffset() {
        let blog = BlogBuilder(mainContext)
            .set(blogOption: "timezone", value: "America/Chicago")
            .set(blogOption: "gmt_offset", value: 0)
            .build()

        #expect(blog.timeZone == TimeZone(identifier: "America/Chicago"))
    }

    // MARK: - postFormatTextFromSlug

    @Test func postFormatTextReturnsDisplayName() {
        let blog = BlogBuilder(mainContext)
            .with(postFormats: ["standard": "Standard", "aside": "Aside"])
            .build()

        #expect(blog.postFormatText(fromSlug: "aside") == "Aside")
    }

    @Test func postFormatTextFallsBackToStandardForNilSlug() {
        let blog = BlogBuilder(mainContext)
            .with(postFormats: ["standard": "Standard", "aside": "Aside"])
            .build()

        #expect(blog.postFormatText(fromSlug: nil) == "Standard")
    }

    @Test func postFormatTextFallsBackToStandardForUnknownSlug() {
        let blog = BlogBuilder(mainContext)
            .with(postFormats: ["standard": "Standard"])
            .build()

        #expect(blog.postFormatText(fromSlug: "unknown") == "unknown")
    }

    @Test func postFormatTextReturnsSlugWhenNoFormats() {
        let blog = BlogBuilder(mainContext).build()

        #expect(blog.postFormatText(fromSlug: "aside") == "aside")
    }

    @Test func postFormatTextReturnsNilForNilSlugAndNoStandard() {
        let blog = BlogBuilder(mainContext)
            .with(postFormats: ["aside": "Aside"])
            .build()

        #expect(blog.postFormatText(fromSlug: nil) == nil)
    }

    // MARK: - isPrivate

    @Test func isPrivateWhenVisibilityIsPrivate() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .private)
            .build()

        #expect(blog.isPrivate)
    }

    @Test func isNotPrivateWhenVisibilityIsPublic() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .public)
            .build()

        #expect(!blog.isPrivate)
    }

    @Test func isNotPrivateWhenVisibilityIsHidden() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .hidden)
            .build()

        #expect(!blog.isPrivate)
    }

    // MARK: - siteVisibility

    @Test func siteVisibilityReturnsPrivate() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .private)
            .build()

        #expect(blog.siteVisibility == .private)
    }

    @Test func siteVisibilityReturnsPublic() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .public)
            .build()

        #expect(blog.siteVisibility == .public)
    }

    @Test func siteVisibilityReturnsHidden() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .hidden)
            .build()

        #expect(blog.siteVisibility == .hidden)
    }

    @Test func siteVisibilitySetterUpdatesPrivacy() {
        let blog = BlogBuilder(mainContext)
            .with(siteVisibility: .public)
            .build()

        blog.siteVisibility = .private
        #expect(blog.isPrivate)

        blog.siteVisibility = .public
        #expect(!blog.isPrivate)
    }

    // MARK: - Blog URL Parsing

    @Test func blogUrlParseableForSimpleUrl() throws {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(url: "http://example.com")
            .build()

        #expect(try blog.wordPressClientParsedUrl().url() == "http://example.com/")
    }

    @Test func blogUrlParseableForMappedDomain() throws {
        let blog = BlogBuilder(mainContext)
            .with(url: "http://example.com")
            .withMappedDomain(mappedDomainUrl: "http://example2.com")
            .build()

        #expect(try blog.wordPressClientParsedUrl().url() == "http://example.com/")
    }

    @Test func dotComIdShouldBeJetpackSiteID() throws {
        let blog = BlogBuilder(mainContext, dotComID: nil)
            .set(blogOption: "jetpack_client_id", value: "123")
            .build()
        #expect(blog.jetpack?.siteID?.int64Value == 123)

        #expect(try Blog.lookup(withID: 123, in: mainContext) == nil)
        try mainContext.save()

        #expect(try Blog.lookup(withID: 123, in: mainContext) != nil)

        contextManager.performAndSave { context in
            #expect((try? Blog.lookup(withID: 123, in: context)) != nil)
        }
    }

    // MARK: - Username For Site

    @Test func effectiveUsernameReturnsBlogUsername() {
        let blog = BlogBuilder(mainContext)
            .with(username: "self_hosted_user")
            .build()

        #expect(blog.effectiveUsername == "self_hosted_user")
    }

    @Test func effectiveUsernameReturnsNilWithoutUsernameOrAccount() {
        let blog = BlogBuilder(mainContext).build()

        #expect(blog.effectiveUsername == nil)
    }

    // FIXME: Crashes because WPAccount fixture sets username and triggers BuildSettings access
//    @Test func effectiveUsernameReturnsAccountUsername() {
//        let blog = BlogBuilder(mainContext)
//            .withAnAccount(username: "wpcom_user")
//            .build()
//
//        #expect(blog.effectiveUsername == "wpcom_user")
//    }
}
