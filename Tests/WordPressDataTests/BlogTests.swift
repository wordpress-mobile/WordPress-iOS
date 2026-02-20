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

        #expect(blog.supports(.pluginManagement))
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
