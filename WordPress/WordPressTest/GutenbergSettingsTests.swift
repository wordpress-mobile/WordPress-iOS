import XCTest
@testable import WordPress

class GutenbergSettingsTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!

    var database: EphemeralKeyValueDatabase!
    var settings: GutenbergSettings!
    var blog: Blog!
    var post: Post!

    fileprivate func newTestPost(with blog: Blog) -> Post {
        let post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as! Post
        post.blog = blog
        return post
    }

    private func newTestBlog(isWPComAPIEnabled: Bool = true) -> Blog {
        if isWPComAPIEnabled {
            let blog = ModelTestHelper.insertDotComBlog(context: context)
            blog.account?.authToken = "auth"
            return blog
        } else {
            return ModelTestHelper.insertSelfHostedBlog(context: context)
        }
    }

    var isGutenbergEnabled: Bool {
        return blog.isGutenbergEnabled
    }

    var mustUseGutenberg: Bool {
        return settings.mustUseGutenberg(for: post)
    }

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        database = EphemeralKeyValueDatabase()
        settings = GutenbergSettings(database: database)
        blog = newTestBlog()
        post = newTestPost(with: blog)
    }

    override func tearDown() {
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testGutenbergDisabledByDefaultAndToggleEnablesInSecondLaunch() {

        let testClosure: () -> () = { () in
            let database = EphemeralKeyValueDatabase()
            let blog = self.newTestBlog()
            // This simulates the first launch
            let settings = GutenbergSettings(database: database)

            XCTAssertFalse(blog.isGutenbergEnabled)

            settings.setGutenbergEnabled(true, for: blog)

            XCTAssertTrue(blog.isGutenbergEnabled)
        }

        BuildConfiguration.localDeveloper.test(testClosure)
        BuildConfiguration.a8cBranchTest.test(testClosure)
        BuildConfiguration.a8cPrereleaseTesting.test(testClosure)
        BuildConfiguration.appStore.test(testClosure)
    }

    func testGutenbergAlwaysUsedForExistingGutenbergPosts() {
        XCTAssertFalse(isGutenbergEnabled)

        post.content = "<!-- wp:paragraph -->\n<p>Hello world</p>\n<!-- /wp:paragraph -->"

        XCTAssertTrue(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertTrue(mustUseGutenberg)
    }

    func testAztecAlwaysUsedForExistingAztecPosts() {
        XCTAssertFalse(isGutenbergEnabled)

        post.content = "<p>Hello world</p>"

        XCTAssertFalse(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertFalse(mustUseGutenberg)
    }

    func testUseGutenbergForNewPostsIfWebAndMobileAreSetToGutenberg() {
        XCTAssertFalse(isGutenbergEnabled)
        XCTAssertFalse(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)
        blog.webEditor = WebEditor.gutenberg.rawValue

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertTrue(mustUseGutenberg)
    }

    // Thests for defaults when `mobile_editor` haven't been sync from remote

    func testSelfHostedDefaultsToAztec() {
        blog = newTestBlog(isWPComAPIEnabled: false)
        XCTAssertFalse(mustUseGutenberg)
    }

    func testSelfHostedUsesOldGlobalEditorSetting() {
        blog = newTestBlog(isWPComAPIEnabled: false)
        database.set(true, forKey: GutenbergSettings.Key.enabledOnce)
        XCTAssertTrue(mustUseGutenberg)
    }

    func testOldWPComAccountsDefaultsToAztec() {
        blog.account?.userID = 1
        XCTAssertFalse(mustUseGutenberg)
    }

    func testNewWPComAccountsDefaultToGutenberg() {
        blog.account?.userID = NSNumber(value: Int.max)
        XCTAssertTrue(mustUseGutenberg)
    }
}
