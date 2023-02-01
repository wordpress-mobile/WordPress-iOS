import XCTest
import CoreData
import OHHTTPStubs
@testable import WordPress

class BlogJetpackTests: CoreDataTestCase {

    // Properties

    private let timeout: TimeInterval = 2.0
    private var blog: Blog!
    private var accountService: AccountService!
    private var blogService: BlogService!

    override func setUp() {
        super.setUp()

        blog = makeBlog()
        accountService = .init(managedObjectContext: mainContext)
        blogService = .init(managedObjectContext: mainContext)
    }

    override func tearDown() {
        blog = nil
        accountService = nil
        blogService = nil
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

    func testJetpackSetupDoesntReplaceDotcomAccount() {
        var saveExpectation = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)
        let account = accountService.createOrUpdateAccount(withUsername: "user", authToken: "token")
        wait(for: [saveExpectation], timeout: timeout)
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: mainContext)

        // the newly added account should be assigned as the default
        XCTAssertEqual(account, defaultAccount)

        // try to add a new account
        saveExpectation = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)
        accountService.createOrUpdateAccount(withUsername: "test1", authToken: "token1")
        wait(for: [saveExpectation], timeout: timeout)

        // ensure that the previous default account isn't replaced by the new one
        XCTAssertEqual(account, defaultAccount)
    }

    func testWPCCShouldntDuplicateBlogs() {
        HTTPStubs.stubRequest(forEndpoint: "me/sites",
                              withFileAtPath: OHPathForFile("me-sites-with-jetpack.json", Self.self)!)
        let saveExpectation = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        let wpComAccount = accountService.createOrUpdateAccount(withUsername: "user", authToken: "token")
        let dotcomBlog = Blog.createBlankBlog(with: wpComAccount)
        dotcomBlog.xmlrpc = "https://dotcom1.wordpress.com/xmlrpc.php"
        dotcomBlog.url = "https://dotcom1.wordpress.com/"
        dotcomBlog.dotComID = NSNumber(integerLiteral: 1)

        let jetpackLegacyBlog = Blog.createBlankBlog(in: mainContext)
        jetpackLegacyBlog.username = "jetpack"
        jetpackLegacyBlog.xmlrpc = "http://jetpack.example.com/xmlrpc.php"
        jetpackLegacyBlog.url = "http://jetpack.example.com/"
        jetpackLegacyBlog.options = makeBlogOptions(version: "1.8.2", clientID: "2")

        // wait on the merge to be completed
        wait(for: [saveExpectation], timeout: timeout)

        // test.blog + wp.com + jetpack
        XCTAssertEqual(1, accountService.numberOfAccounts())
        // test.blog + wp.com + jetpack (legacy)
        XCTAssertEqual(3, Blog.count(in: mainContext))
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

        // test.blog + wp.com
        XCTAssertEqual(1, accountService.numberOfAccounts())
        // dotcom1.wordpress.com + jetpack.example.com
        XCTAssertEqual(2, wpComAccount.blogs.count)
        // test.blog + wp.com + jetpack (wpcc)
        XCTAssertEqual(3, Blog.count(in: mainContext))

        let testBlog = wpComAccount.blogs.first { $0.dotComID?.intValue == 1 }
        XCTAssertNotNil(testBlog)
        XCTAssertEqual(testBlog?.xmlrpc, "https://dotcom1.wordpress.com/xmlrpc.php")

        let testBlog2 = wpComAccount.blogs.first { $0.dotComID?.intValue == 2 }
        XCTAssertNotNil(testBlog2)
        XCTAssertEqual(testBlog2?.xmlrpc, "http://jetpack.example.com/xmlrpc.php")
    }

    func testSyncBlogsMigratesJetpackSSL() {
        HTTPStubs.stubRequest(forEndpoint: "me/sites",
                              withFileAtPath: OHPathForFile("me-sites-with-jetpack.json", Self.self)!)
        let saveExpectation = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        let wpComAccount = accountService.createOrUpdateAccount(withUsername: "user", authToken: "token")
        let dotcomBlog = Blog.createBlankBlog(with: wpComAccount)
        dotcomBlog.xmlrpc = "https://dotcom1.wordpress.com/xmlrpc.php"
        dotcomBlog.url = "https://dotcom1.wordpress.com/"
        dotcomBlog.dotComID = NSNumber(integerLiteral: 1)

        let jetpackBlog = Blog.createBlankBlog(in: mainContext)
        jetpackBlog.username = "jetpack"
        jetpackBlog.xmlrpc = "https://jetpack.example.com/xmlrpc.php" // now in https
        jetpackBlog.url = "https://jetpack.example.com/" // now in https

        // wait on the merge to be completed
        wait(for: [saveExpectation], timeout: timeout)

        XCTAssertEqual(1, accountService.numberOfAccounts())
        // test.blog + wp.com + jetpack (legacy)
        XCTAssertEqual(3, Blog.count(in: mainContext))
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
        XCTAssertEqual(1, accountService.numberOfAccounts())
        // dotcom1.wordpress.com + jetpack.example.com
        XCTAssertEqual(2, wpComAccount.blogs.count)
        // test.blog + wp.com + jetpack (wpcc)
        XCTAssertEqual(3, Blog.count(in: mainContext))
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
}
