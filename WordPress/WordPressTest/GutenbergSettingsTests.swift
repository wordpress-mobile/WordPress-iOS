import XCTest
@testable import WordPress

class GutenbergSettingsTests: XCTestCase {

    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!

    fileprivate func newTestPost() -> Post {
        return NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as! Post
    }

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
    }

    override func tearDown() {
        context.rollback()
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testGutenbergDisabledByDefaultAndToggleEnablesInSecondLaunch() {
        let testClosure: () -> () = { () in
            let database = EphemeralKeyValueDatabase()

            // This simulates the first launch
            let settings = GutenbergSettings(database: database)

            XCTAssertFalse(settings.isGutenbergEnabled)

            settings.toggleGutenberg()

            // This simulates a second launch
            let secondEditorSettings = GutenbergSettings(database: database)

            XCTAssertTrue(secondEditorSettings.isGutenbergEnabled)
        }

        BuildConfiguration.localDeveloper.test(testClosure)
        BuildConfiguration.a8cBranchTest.test(testClosure)
        BuildConfiguration.a8cPrereleaseTesting.test(testClosure)
        BuildConfiguration.appStore.test(testClosure)
    }

    func testGutenbergAlwaysUsedForExistingGutenbergPosts() {
        let database = EphemeralKeyValueDatabase()
        let settings = GutenbergSettings(database: database)
        XCTAssertFalse(settings.isGutenbergEnabled)

        let post = newTestPost()
        post.content = "<!-- wp:paragraph -->\n<p>Hello world</p>\n<!-- /wp:paragraph -->"

        XCTAssertTrue(settings.mustUseGutenberg(for: post))

        settings.toggleGutenberg()
        XCTAssertTrue(settings.isGutenbergEnabled)

        XCTAssertTrue(settings.mustUseGutenberg(for: post))
    }

    func testAztecAlwaysUsedForExistingAztecPosts() {
        let database = EphemeralKeyValueDatabase()
        let settings = GutenbergSettings(database: database)
        XCTAssertFalse(settings.isGutenbergEnabled)

        let post = newTestPost()
        post.content = "<p>Hello world</p>"

        XCTAssertFalse(settings.mustUseGutenberg(for: post))

        settings.toggleGutenberg()
        XCTAssertTrue(settings.isGutenbergEnabled)

        XCTAssertFalse(settings.mustUseGutenberg(for: post))
    }

    func testUseSettingForNewPosts() {
        let database = EphemeralKeyValueDatabase()
        let settings = GutenbergSettings(database: database)
        XCTAssertFalse(settings.isGutenbergEnabled)

        let post = newTestPost()

        XCTAssertFalse(settings.mustUseGutenberg(for: post))

        settings.toggleGutenberg()
        XCTAssertTrue(settings.isGutenbergEnabled)

        XCTAssertTrue(settings.mustUseGutenberg(for: post))
    }
}
