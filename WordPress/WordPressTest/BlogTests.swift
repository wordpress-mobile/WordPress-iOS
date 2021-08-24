import CoreData
import XCTest
@testable import WordPress

final class BlogTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        context = TestContextManager().mainContext
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Atomic Tests
    func testIsAtomic() {
        let blog = BlogBuilder(context)
            .with(atomic: true)
            .build()

        XCTAssertTrue(blog.isAtomic())
    }

    func testIsNotAtomic() {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .build()

        XCTAssertFalse(blog.isAtomic())
    }

    // MARK: - Blog Lookup
    func testThatLookupByBlogIDWorks() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(Blog.lookup(withID: blog.dotComID!, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidBlogID() throws {
        XCTAssertNil(Blog.lookup(withID: NSNumber(integerLiteral: 1), in: context))
    }

    func testThatLookupByBlogIDWorksForIntegerBlogID() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(try Blog.lookup(withID: blog.dotComID!.intValue, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidIntegerBlogID() throws {
        XCTAssertNil(try Blog.lookup(withID: 1, in: context))
    }

    func testThatLookupBlogIDWorksForInt64BlogID() throws {
        let blog = BlogBuilder(context).build()
        XCTAssertNotNil(blog.dotComID)
        XCTAssertNotNil(try Blog.lookup(withID: blog.dotComID!.int64Value, in: context))
    }

    func testThatLookupByBlogIDFailsForInvalidInt64BlogID() throws {
        XCTAssertNil(try Blog.lookup(withID: Int64(1), in: context))
    }

    // MARK: - Plugin Management
    func testThatPluginManagementIsDisabledForSimpleSites() {
        let blog = BlogBuilder(context)
            .with(atomic: true)
            .build()

        XCTAssertFalse(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsEnabledForBusinessPlans() {
        let blog = BlogBuilder(context)
            .with(isHostedAtWPCom: true)
            .with(planID: 1008) // Business plan
            .with(isAdmin: true)
            .build()

        XCTAssertTrue(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsDisabledForPrivateSites() {
        let blog = BlogBuilder(context)
            .with(isHostedAtWPCom: true)
            .with(planID: 1008) // Business plan
            .with(isAdmin: true)
            .with(siteVisibility: .private)
            .build()

        XCTAssertTrue(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsEnabledForJetpack() {
        let blog = BlogBuilder(context)
            .withAnAccount()
            .withJetpack(version: "5.6", username: "test_user", email: "user@example.com")
            .with(isHostedAtWPCom: false)
            .with(isAdmin: true)
            .build()

        XCTAssertTrue(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsDisabledForWordPress54AndBelow() {
        let blog = BlogBuilder(context)
            .with(wordPressVersion: "5.4")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: true)
            .build()

        XCTAssertFalse(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsEnabledForWordPress55AndAbove() {
        let blog = BlogBuilder(context)
            .with(wordPressVersion: "5.5")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: true)
            .build()

        XCTAssertTrue(blog.supports(.pluginManagement))
    }

    func testThatPluginManagementIsDisabledForNonAdmins() {
        let blog = BlogBuilder(context)
            .with(wordPressVersion: "5.5")
            .with(username: "test_username")
            .with(password: "test_password")
            .with(isAdmin: false)
            .build()

        XCTAssertFalse(blog.supports(.pluginManagement))
    }

    func testStatsActiveForSitesHostedAtWPCom() {
        let blog = BlogBuilder(context)
            .isHostedAtWPcom()
            .with(modules: [""])
            .build()

        XCTAssertTrue(blog.isStatsActive())
    }

    func testStatsActiveForSitesNotHotedAtWPCom() {
        let blog = BlogBuilder(context)
            .isNotHostedAtWPcom()
            .with(modules: ["stats"])
            .build()

        XCTAssertTrue(blog.isStatsActive())
    }

    func testStatsNotActiveForSitesNotHotedAtWPCom() {
        let blog = BlogBuilder(context)
            .isNotHostedAtWPcom()
            .with(modules: [""])
            .build()

        XCTAssertFalse(blog.isStatsActive())
    }

    // MARK: - Blog.version string conversion testing
    func testTheVersionIsAStringWhenGivenANumber() {
        let blog = BlogBuilder(context)
            .set(blogOption: "software_version", value: 13.37)
            .build()

        XCTAssertTrue((blog.version as Any) is String)
        XCTAssertEqual(blog.version, "13.37")
    }

    func testTheVersionIsAStringWhenGivenAString() {
        let blog = BlogBuilder(context)
            .set(blogOption: "software_version", value: "5.5")
            .build()

        XCTAssertTrue((blog.version as Any) is String)
        XCTAssertEqual(blog.version, "5.5")
    }

    func testTheVersionDefaultsToAnEmptyStringWhenTheValueIsNotConvertible() {
        let blog = BlogBuilder(context)
            .set(blogOption: "software_version", value: NSObject())
            .build()

        XCTAssertTrue((blog.version as Any) is String)
        XCTAssertEqual(blog.version, "")
    }
}
