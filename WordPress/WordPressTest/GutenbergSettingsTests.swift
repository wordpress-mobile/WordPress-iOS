import XCTest
@testable import WordPress

class GutenbergSettingsTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!
    private let gutenbergContent = "<!-- wp:paragraph -->\n<p>Hello world</p>\n<!-- /wp:paragraph -->"

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

    var shouldAutoenableGutenberg: Bool {
        return settings.shouldAutoenableGutenberg(for: post)
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
            settings.setGutenbergEnabled(false, for: blog)

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
        settings.setGutenbergEnabled(false, for: blog)
        XCTAssertFalse(isGutenbergEnabled)

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertTrue(mustUseGutenberg)
    }

    func testAztecAlwaysUsedForExistingAztecPosts() {
        settings.setGutenbergEnabled(false, for: blog)
        XCTAssertFalse(isGutenbergEnabled)

        post.content = "<p>Hello world</p>"

        XCTAssertFalse(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertFalse(mustUseGutenberg)
    }

    // Thests for defaults when `mobile_editor` haven't been sync from remote

    func testSelfHostedDefaultsToAztec() {
        blog = newTestBlog(isWPComAPIEnabled: false)
        post = newTestPost(with: blog)
        XCTAssertFalse(mustUseGutenberg)
    }

    func testWPComAccountsDefaultsToAztec() {
        XCTAssertFalse(mustUseGutenberg)
    }

    // MARK: - Tests for Autoenabling gutenberg

    // Autoenable on new installs

    func testDoNotAutoenableIfUsersSwitchesToGutenberg() {
        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testDoNotAutoenableIfUsersSwitchesToGutenbergAndBackToAztec() {
        settings.setGutenbergEnabled(true, for: blog)
        settings.setGutenbergEnabled(false, for: blog)
        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testAutoenableWhenSetToAztecOpeningGutenbergPost() {
        post.content = gutenbergContent
        blog.mobileEditor = .aztec

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    // Autoenable on new blogs

    func testAutoenableOnNewPostAndNewBlogs() {
        settings.softSetGutenbergEnabled(true, for: blog)

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    func testAutoenableOnExistingPostAndNewBlogs() {
        settings.softSetGutenbergEnabled(true, for: blog)
        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    func testAutoenableOnNewBlogsOccoursOnlyOnce() {
        settings.softSetGutenbergEnabled(true, for: blog)

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)

        settings.willShowDialog(for: blog)

        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    // Autoenable after Migration

    func testDoNotAutoenableAfterMigrationSetToGutenberg() {
        database.set(true, forKey: GutenbergSettings.Key.appWideEnabled)
        blog.mobileEditor = .gutenberg

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testDoNotAutoenableAfterMigrationSetToAztec() {
        database.set(false, forKey: GutenbergSettings.Key.appWideEnabled)
        blog.mobileEditor = .aztec

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testAutoenableAfterMigrationNotSet() {
        database.set(nil, forKey: GutenbergSettings.Key.appWideEnabled)
        blog.mobileEditor = .aztec

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }
}
