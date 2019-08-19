import Foundation
@testable import WordPress

private class TestableEditorSettingsService: EditorSettingsService {
    let mockApi: WordPressComRestApi

    init(managedObjectContext context: NSManagedObjectContext, wpcomApi: WordPressComRestApi) {
        mockApi = wpcomApi
        super.init(managedObjectContext: context)
    }

    override func api(for blog: Blog) -> WordPressComRestApi? {
        return mockApi
    }

    override var apiForDefaultAccount: WordPressComRestApi? {
        return mockApi
    }
}

class EditorSettingsServiceTest: XCTestCase {
    var contextManager: TestContextManager!
    var context: NSManagedObjectContext!
    var remoteApi: MockWordPressComRestApi!
    var service: EditorSettingsService!
    var database: KeyValueDatabase!
    var account: WPAccount!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.mainContext
        remoteApi = MockWordPressComRestApi()
        database = EphemeralKeyValueDatabase()
        service = TestableEditorSettingsService(managedObjectContext: context, wpcomApi: remoteApi)
        Environment.replaceEnvironment(contextManager: contextManager)
        setupDefaultAccount(with: context)
    }

    func setupDefaultAccount(with context: NSManagedObjectContext) {
        account = ModelTestHelper.insertAccount(context: context)
        account.authToken = "auth"
        account.uuid = "uuid"
        AccountService(managedObjectContext: context).setDefaultWordPressComAccount(account)
    }

    override func tearDown() {
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testLocalSettingsMigrationPostAztec() {
        let blog = makeTestBlog()
        // Self-Hosted sites will default to Aztec
        blog.account = nil

        sync(with: blog)

        // Call GET settings from remote
        XCTAssertTrue(remoteApi.getMethodCalled)
        // Respond with mobile editor not yet set on the server
        let response = responseWith(mobileEditor: "")
        remoteApi.successBlockPassedIn?(response, HTTPURLResponse())

        // Begin migration from local to remote

        // Should call POST local settings to remote (migration)
        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("platform=mobile&editor=aztec") ?? false)
        // Respond with mobile editor set on the server
        let finalResponse = responseWith(mobileEditor: "aztec")
        remoteApi.successBlockPassedIn?(finalResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1) { (error) in
            // The default value should be now on local and remote
            XCTAssertEqual(blog.mobileEditor, .aztec)
        }
    }

    func testAppWideGutenbergSyncWithServer() {
        service.migrateGlobalSettingToRemote(isGutenbergEnabled: true)

        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("me/gutenberg") ?? false)
        let parameters = remoteApi.parametersPassedIn as? [String: Any]
        XCTAssertEqual(parameters?["editor"] as? String, MobileEditor.gutenberg.rawValue)
    }

    func testAppWideAztecSyncWithServer() {
        database.set(false, forKey: GutenbergSettings.Key.appWideEnabled)

        service.migrateGlobalSettingToRemote(isGutenbergEnabled: false)

        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("me/gutenberg") ?? false)
        let parameters = remoteApi.parametersPassedIn as? [String: Any]
        XCTAssertEqual(parameters?["editor"] as? String, MobileEditor.aztec.rawValue)
    }

    func testPostAppWideEditorSettingResponseIsHandledProperlyWithGutenberg() {
        let numberOfBlogs = 10
        let blogs = addBlogsToAccount(count: numberOfBlogs)
        let response = bulkResponse(with: .gutenberg, count: numberOfBlogs)

        service.migrateGlobalSettingToRemote(isGutenbergEnabled: true)
        remoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        blogs.forEach {
            XCTAssertTrue($0.isGutenbergEnabled)
        }
    }

    func testPostAppWideEditorSettingResponseIsHandledProperlyWithAztec() {
        let numberOfBlogs = 10
        let blogs = addBlogsToAccount(count: numberOfBlogs)
        let response = bulkResponse(with: .aztec, count: numberOfBlogs)

        blogs.forEach {
            // Pre-set gutenberg to be sure it is overiden with aztec
            $0.mobileEditor = .gutenberg
        }

        service.migrateGlobalSettingToRemote(isGutenbergEnabled: false)
        remoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        blogs.forEach {
            XCTAssertFalse($0.isGutenbergEnabled)
            XCTAssertEqual($0.editor, .aztec)
        }
    }
}

extension EditorSettingsServiceTest {
    func addBlogsToAccount(count: Int) -> [Blog] {
        let blogs = makeTestBlogs(count: count)
        account.addBlogs(Set(blogs))
        return blogs
    }

    func makeTestBlogs(count: Int) -> [Blog] {
        return (1...count).map(makeTestBlog)
    }

    func makeTestBlog(withID id: Int = 1) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = NSNumber(value: id)
        blog.account?.authToken = "auth"
        return blog
    }

    func bulkResponse(with editor: MobileEditor, count: Int) -> [String: String] {
        return (1...count).reduce(into: [String: String]()) {
            $0["\($1)"] = editor.rawValue
        }
    }

    func responseWith(mobileEditor: String) -> AnyObject {
        return [
            "editor_mobile": mobileEditor,
            "editor_web": "classic",
        ] as AnyObject
    }

    func sync(with blog: Blog) {
        let expec = expectation(description: "success")
        expec.assertForOverFulfill = true

        service.syncEditorSettings(for: blog, success: {
            expec.fulfill()
        }) { (error) in
            XCTFail("This call should succeed. Error: \(error)")
            expec.fulfill()
        }
    }
}
