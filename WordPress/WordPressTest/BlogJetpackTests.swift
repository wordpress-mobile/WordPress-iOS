import XCTest
import CoreData
import OHHTTPStubs
import Nimble
@testable import WordPress

class BlogJetpackTests: CoreDataTestCase {

    // Properties

    private let timeout: TimeInterval = 2.0

    lazy private var blog: Blog = {
        makeBlog()
    }()

    lazy private var accountService: AccountService = {
        .init(coreDataStack: contextManager)
    }()

    lazy private var blogService: BlogService = {
        .init(coreDataStack: contextManager)
    }()

    override func tearDown() {
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    // MARK: - Tests

    func testJetpackInstalled() {
        XCTAssertTrue(jetpackState.isInstalled)
        blog.options = nil
        XCTAssertNil(blog.jetpack)
    }

    func testJetpackVersion() {
        XCTAssertEqual(jetpackState.version, "1.8.2")
    }

    func testJetpackSiteId() {
        XCTAssertEqual(jetpackState.siteID?.intValue, 3)
    }

    func testJetpackUsername() {
        XCTAssertNil(jetpackState.connectedUsername)
    }

    func testJetpackSetupDoesntReplaceDotcomAccount() throws {
        let account = try createOrUpdateAccount(username: "user", authToken: "token")
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext)

        // the newly added account should be assigned as the default
        XCTAssertEqual(account, defaultAccount)

        // try to add a new account
        _ = try createOrUpdateAccount(username: "test1", authToken: "token1")

        // ensure that the previous default account isn't replaced by the new one
        XCTAssertEqual(account, defaultAccount)
    }

    func testWPCCShouldntDuplicateBlogs() throws {
        HTTPStubs.stubRequest(forEndpoint: "me/sites",
                              withFileAtPath: OHPathForFile("me-sites-with-jetpack.json", Self.self)!)

        let wpComAccount = try createOrUpdateAccount(username: "user", authToken: "token")
        let dotcomBlog = Blog.createBlankBlog(with: wpComAccount)
        dotcomBlog.xmlrpc = "https://dotcom1.wordpress.com/xmlrpc.php"
        dotcomBlog.url = "https://dotcom1.wordpress.com/"
        dotcomBlog.dotComID = NSNumber(integerLiteral: 1)

        let jetpackLegacyBlog = Blog.createBlankBlog(in: mainContext)
        jetpackLegacyBlog.username = "jetpack"
        jetpackLegacyBlog.xmlrpc = "http://jetpack.example.com/xmlrpc.php"
        jetpackLegacyBlog.url = "http://jetpack.example.com/"
        jetpackLegacyBlog.options = makeBlogOptions(version: "1.8.2", clientID: "2")

        contextManager.saveContextAndWait(mainContext)

        // wp.com + jetpack
        XCTAssertEqual(1, try WPAccount.lookupNumberOfAccounts(in: mainContext))
        // wp.com + jetpack (legacy)
        XCTAssertEqual(2, Blog.count(in: mainContext))
        // dotcom1.wordpress.com
        XCTAssertEqual(1, wpComAccount.blogs.count)

        XCTAssertNotNil(wpComAccount.blogs.first { $0.dotComID?.intValue == 1 })

        let syncExpectation = expectation(description: "Blogs sync")
        blogService.syncBlogs(for: wpComAccount) {
            syncExpectation.fulfill()
        } failure: { _ in
            XCTFail("Sync blogs shouldn't fail")
        }
        wait(for: [syncExpectation], timeout: 5.0)

        // wp.com
        XCTAssertEqual(1, try WPAccount.lookupNumberOfAccounts(in: mainContext))
        // dotcom1.wordpress.com + jetpack.example.com
        XCTAssertEqual(2, wpComAccount.blogs.count)
        // wp.com + jetpack (wpcc)
        XCTAssertEqual(2, Blog.count(in: mainContext))

        let testBlog = wpComAccount.blogs.first { $0.dotComID?.intValue == 1 }
        XCTAssertNotNil(testBlog)
        XCTAssertEqual(testBlog?.xmlrpc, "https://dotcom1.wordpress.com/xmlrpc.php")

        let testBlog2 = wpComAccount.blogs.first { $0.dotComID?.intValue == 2 }
        XCTAssertNotNil(testBlog2)
        XCTAssertEqual(testBlog2?.xmlrpc, "http://jetpack.example.com/xmlrpc.php")
    }

    func testSyncBlogsMigratesJetpackSSL() throws {
        HTTPStubs.stubRequest(forEndpoint: "me/sites",
                              withFileAtPath: OHPathForFile("me-sites-with-jetpack.json", Self.self)!)

        let wpComAccount = try createOrUpdateAccount(username: "user", authToken: "token")
        let dotcomBlog = Blog.createBlankBlog(with: wpComAccount)
        dotcomBlog.xmlrpc = "https://dotcom1.wordpress.com/xmlrpc.php"
        dotcomBlog.url = "https://dotcom1.wordpress.com/"
        dotcomBlog.dotComID = NSNumber(integerLiteral: 1)

        let jetpackBlog = Blog.createBlankBlog(in: mainContext)
        jetpackBlog.username = "jetpack"
        jetpackBlog.xmlrpc = "https://jetpack.example.com/xmlrpc.php" // now in https
        jetpackBlog.url = "https://jetpack.example.com/" // now in https

        contextManager.saveContextAndWait(mainContext)

        XCTAssertEqual(1, try WPAccount.lookupNumberOfAccounts(in: mainContext))
        // wp.com + jetpack (legacy)
        XCTAssertEqual(2, Blog.count(in: mainContext))
        // dotcom1.wordpress.com
        XCTAssertEqual(1, wpComAccount.blogs.count)

        let syncExpectation = expectation(description: "Blogs sync")
        blogService.syncBlogs(for: wpComAccount) {
            syncExpectation.fulfill()
        } failure: { _ in
            XCTFail("Sync blogs shouldn't fail")
        }
        wait(for: [syncExpectation], timeout: 5.0)

        // test.blog + wp.com
        XCTAssertEqual(1, try WPAccount.lookupNumberOfAccounts(in: mainContext))
        // dotcom1.wordpress.com + jetpack.example.com
        XCTAssertEqual(2, wpComAccount.blogs.count)
        // wp.com + jetpack (wpcc)
        XCTAssertEqual(2, Blog.count(in: mainContext))
    }

    /// Verify an account's blogs won't be saved if the account is deleted during a blog sync.
    func testSyncBlogsAndSignOut() throws {
        let wpComAccount = try createOrUpdateAccount(username: "user", authToken: "token")
        XCTAssertEqual(Blog.count(in: mainContext), 0)
        var deleted = false

        // Blog sync makes a series of HTTP requests: the first one fetchs all blogs, followed by a few
        // requests to get blog capabilities (one for each blog).
        //
        // See also https://github.com/wordpress-mobile/WordPress-iOS/issues/20964
        HTTPStubs.stubRequest(forEndpoint: "me/sites",
                              withFileAtPath: OHPathForFile("me-sites-with-jetpack.json", Self.self)!)
        HTTPStubs.stubRequests { request in
            (request.url?.path.matches(regex: "sites/\\d+/rewind/capabilities").count ?? 0) > 0
        } withStubResponse: { _ in
            // We can't delete the `Account` instance until the first API request completes. Because the URLSession instance
            // used in the `me/sites` API request will be invalidated upon account deletion (see `WPAccount.prepareForDeletion` method).
            self.mainContext.performAndWait {
                // Delete the account to simulate user signing out of the app.
                guard !deleted else { return }
                self.mainContext.delete(wpComAccount)
                try! self.mainContext.save()
                deleted = true
            }
            return HTTPStubsResponse(jsonObject: [String: Int](), statusCode: 200, headers: nil)
        }

        // Using a Nimble assertion to see if it makes the test not-flaky.
        // It's currently timing out every first time it runs in CI, then passes on retry.
        // See
        // https://buildkite.com/organizations/automattic/analytics/suites/wordpress-ios/tests/0188fb2d-cb96-765d-adc2-b7b76e7414fb?branch=trunk
        waitUntil { done in
            self.blogService.syncBlogs(
                for: wpComAccount,
                success: { done() },
                failure: { fail("Sync blogs expected to succeed but failed with: \($0)") }
            )
        }

        // No blogs should have been saved after the sync blogs operation finished.
        XCTAssertEqual(Blog.count(in: mainContext), 0)
    }

    // MARK: Jetpack Individual Plugins

    func testJetpackIsConnectedWithoutFullPluginGivenIndividualPluginOnlyReturnsTrue() {
        // Arrange
        let plugins = ["jetpack-search"]

        // Act
        blog.options? = makeActivePluginOption(values: plugins)

        // Assert
        XCTAssertTrue(blog.jetpackIsConnectedWithoutFullPlugin)
    }

    func testJetpackIsConnectedWithoutFullPluginGivenMultipleIndividualPluginsReturnsTrue() {
        // Arrange
        let plugins = ["jetpack-search", "jetpack-backup"]

        // Act
        blog.options? = makeActivePluginOption(values: plugins)

        // Assert
        XCTAssertTrue(blog.jetpackIsConnectedWithoutFullPlugin)
    }

    func testJetpackIsConnectedWithoutFullPluginGivenFullJetpackSiteReturnsFalse() {
        // Arrange
        let plugins = ["jetpack"]

        // Act
        blog.options? = makeActivePluginOption(values: plugins)

        // Assert
        XCTAssertFalse(blog.jetpackIsConnectedWithoutFullPlugin)
    }

    func testJetpackIsConnectedWithoutFullPluginGivenNoActivePluginsReturnsFalse() {
        // Default Blog setup doesn't have any active plugins.

        // Assert
        XCTAssertFalse(blog.jetpackIsConnectedWithoutFullPlugin)
    }

    func testJetpackIsConnectedWithoutFullPluginGivenBothIndividualAndFullJetpackPluginsReturnsFalse() {
        // Arrange
        let plugins = ["jetpack-search", "jetpack"]

        // Act
        blog.options? = makeActivePluginOption(values: plugins)

        // Assert
        XCTAssertFalse(blog.jetpackIsConnectedWithoutFullPlugin)
    }
}

// MARK: - Helpers

private extension BlogJetpackTests {

    var jetpackState: JetpackState {
        guard let jetpackState = blog.jetpack else {
            XCTFail("The blog's JetpackState is expected to exist.")
            return .init()
        }
        return jetpackState
    }

    func makeBlog() -> Blog {
        let blogToReturn = BlogBuilder(mainContext)
            .with(username: "admin")
            .build()

        blogToReturn.xmlrpc = "http://test.blog/xmlrpc.php"
        blogToReturn.url = "http://test.blog/"
        blogToReturn.options = makeBlogOptions(version: "1.8.2", clientID: "3")
        blogToReturn.settings = NSEntityDescription.insertNewObject(forEntityName: BlogSettings.entityName(), into: mainContext) as? BlogSettings

        return blogToReturn
    }

    /// `JetpackState` and `Blog`'s `options` parsing are still expecting `NSString` instances.
    func makeBlogOptions(version: String, clientID: String) -> [NSString: [NSString: Any]] {
        return [
            "jetpack_version": [
                "value": version as NSString,
                "desc": "stub" as NSString,
                "readonly": true
            ],
            "jetpack_client_id": [
                "value": clientID as NSString,
                "desc": "stub" as NSString,
                "readonly": true
            ]
        ]
    }

    func makeActivePluginOption(values: [String]) -> [NSString: [NSString: Any]] {
        return ["jetpack_connection_active_plugins": ["value": values]]
    }

    private func createOrUpdateAccount(username: String, authToken: String) throws -> WPAccount {
        let accountID = accountService.createOrUpdateAccount(withUsername: username, authToken: authToken)
        return try XCTUnwrap(contextManager.mainContext.existingObject(with: accountID) as? WPAccount)
    }
}
