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

    override func apiForDefaultAccount() -> WordPressComRestApi? {
        return mockApi
    }
}

class EditorSettingsServiceTest: XCTestCase {
    var contextManager: TestContextManager!
    var context: NSManagedObjectContext!
    var remoteApi: MockWordPressComRestApi!
    var service: EditorSettingsService!
    var database: KeyValueDatabase!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        remoteApi = MockWordPressComRestApi()
        database = EphemeralKeyValueDatabase()
        service = TestableEditorSettingsService(managedObjectContext: context, wpcomApi: remoteApi)
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
        database.set(true, forKey: GutenbergSettings.Key.appWideEnabled)

        service.postAppWideEditorSettingToRemoteForAllBlogsAfterMigration(database: database)

        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("me/gutenberg") ?? false)
        let parameters = remoteApi.parametersPassedIn as? [String: String]
        XCTAssertEqual(parameters?["editor"], MobileEditor.gutenberg.rawValue)
    }

    func testAppWideAztecSyncWithServer() {
        database.set(false, forKey: GutenbergSettings.Key.appWideEnabled)

        service.postAppWideEditorSettingToRemoteForAllBlogsAfterMigration(database: database)

        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("me/gutenberg") ?? false)
        let parameters = remoteApi.parametersPassedIn as? [String: String]
        XCTAssertEqual(parameters?["editor"], MobileEditor.aztec.rawValue)
    }

    func testAppWideNilSyncAztecWithServer() {
        database.set(nil, forKey: GutenbergSettings.Key.appWideEnabled)

        service.postAppWideEditorSettingToRemoteForAllBlogsAfterMigration(database: database)

        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("me/gutenberg") ?? false)
        let parameters = remoteApi.parametersPassedIn as? [String: String]
        XCTAssertEqual(parameters?["editor"], MobileEditor.aztec.rawValue)
    }
}

extension EditorSettingsServiceTest {
    func makeTestBlog() -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = 1
        blog.account?.authToken = "auth"
        return blog
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
