import Foundation
@testable import WordPress

class EditorSettingsServiceTest: XCTestCase {
    var contextManager: TestContextManager!
    var context: NSManagedObjectContext!
    var remoteApi: MockWordPressComRestApi!
    var service: EditorSettingsService!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
        remoteApi = MockWordPressComRestApi()
        Environment.replaceEnvironment(contextManager: contextManager, userDefaults: EphemeralKeyValueDatabase())
        service = EditorSettingsService(managedObjectContext: context, wpcomApi: remoteApi)
    }

    override func tearDown() {
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testLocalSettingsMigrationPostAztec() {
        // Blog from an old account should default to Aztec
        let blog = blogWith(userId: 1)

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
            XCTAssertEqual(blog.editor.mobile, .aztec)
        }
    }

    func testLocalSettingsMigrationPostGutenberg() {
        // Blog from a new account should default to Gutenberg
        let blog = blogWith(userId: Int.max)

        // Mobile editor not yet set on the server
        let response = responseWith(mobileEditor: "")

        sync(with: blog)

        // Call GET settings from remote
        XCTAssertTrue(remoteApi.getMethodCalled)
        remoteApi.successBlockPassedIn?(response as AnyObject, HTTPURLResponse())

        // Begin migration from local to remote

        // Should call POST local settings to remote (migration)
        XCTAssertTrue(remoteApi.postMethodCalled)
        XCTAssertTrue(remoteApi.URLStringPassedIn?.contains("platform=mobile&editor=gutenberg") ?? false)
        // Respond with mobile editor set on the server
        let finalResponse = responseWith(mobileEditor: "gutenberg")
        remoteApi.successBlockPassedIn?(finalResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1) { (error) in
            // The default value should be now on local and remote
            XCTAssertEqual(blog.editor.mobile, .gutenberg)
        }
    }
}

extension EditorSettingsServiceTest {
    func blogWith(userId: Int) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = 1
        blog.account?.userID = NSNumber(value: userId)
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
