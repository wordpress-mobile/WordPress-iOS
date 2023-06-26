import Foundation
import XCTest
import Nimble
@testable import WordPress

private class TestableEditorSettingsService: EditorSettingsService {
    let mockApi: WordPressComRestApi

    init(coreDataStack: CoreDataStack, wpcomApi: WordPressComRestApi) {
        mockApi = wpcomApi
        super.init(coreDataStack: coreDataStack)
    }

    override func api(for blog: Blog) -> WordPressComRestApi? {
        return mockApi
    }

    override var apiForDefaultAccount: WordPressComRestApi? {
        return mockApi
    }
}

class EditorSettingsServiceTest: CoreDataTestCase {
    var remoteApi: MockWordPressComRestApi!
    var service: EditorSettingsService!
    var database: KeyValueDatabase!
    var account: WPAccount!

    override func setUp() {
        super.setUp()
        remoteApi = MockWordPressComRestApi()
        database = EphemeralKeyValueDatabase()
        service = TestableEditorSettingsService(coreDataStack: contextManager, wpcomApi: remoteApi)
        Environment.replaceEnvironment(contextManager: contextManager)
        setupDefaultAccount(with: mainContext)
    }

    func setupDefaultAccount(with context: NSManagedObjectContext) {
        // Note: an auth token is required to set the account as the default for WP.com.
        // To have an auth token, we first need to set a username.
        account = AccountBuilder(context)
            .with(username: "test_user")
            .with(authToken: "auth")
            .build()
        AccountService(coreDataStack: contextManager).setDefaultWordPressComAccount(account)
    }

    func testLocalSettingsMigrationPostAztec() {
        let blog = makeTestBlog()
        // Self-Hosted sites will default to Aztec
        blog.account = nil
        contextManager.saveContextAndWait(mainContext)

        sync(with: blog)

        // Call GET settings from remote
        XCTAssertTrue(remoteApi.getMethodCalled)
        // Respond with mobile editor not yet set on the server
        let response = responseWith(mobileEditor: "")
        remoteApi.successBlockPassedIn?(response, HTTPURLResponse())

        // Begin migration from local to remote

        // Should call POST local settings to remote (migration)
        expect(self.remoteApi.postMethodCalled).toEventually(beTrue())
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("platform=mobile&editor=gutenberg") ?? false)
        // Respond with mobile editor set on the server
        let finalResponse = responseWith(mobileEditor: "gutenberg")
        remoteApi.successBlockPassedIn?(finalResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1) { (error) in
            // The default value should be now on local and remote
            XCTAssertEqual(blog.mobileEditor, .gutenberg)
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

        contextManager.saveContextAndWait(mainContext)

        service.migrateGlobalSettingToRemote(isGutenbergEnabled: false)
        remoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        blogs.forEach { blog in
            expect(blog.isGutenbergEnabled).toEventually(beFalse())
            expect(blog.editor).toEventually(equal(.aztec))
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
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
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
