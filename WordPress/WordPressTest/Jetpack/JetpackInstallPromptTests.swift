import XCTest
@testable import WordPress

class JetpackInstallPromptTests: XCTestCase {
    private var contextManager: ContextManagerMock!
    private var context: NSManagedObjectContext!
    private var userDefaults: UserDefaults!
    private var settings: JetpackInstallPromptSettings!

    override func setUp() {
        super.setUp()

        contextManager = ContextManagerMock()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext

        let name = String(describing: JetpackInstallPromptSettings.self)
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)

        settings = JetpackInstallPromptSettings(
            userDefaults: userDefaults,
            showJetpackPluginInstallPrompt: true
        )
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPromptWillNotShowForDotComSites() {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = 1

        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillShowForSitesWithoutJetpack() {
        let blog = BlogBuilder(context).withJetpack(version: nil, username: nil, email: nil).build()
        blog.isAdmin = true
        XCTAssertTrue(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowForNonAdmins() {
        let blog = BlogBuilder(context).withJetpack(version: nil, username: nil, email: nil).build()
        blog.isAdmin = false
        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowForBlogsWithJetpack() {
        let blog = BlogBuilder(context).withJetpack(version: "1.0", username: "test", email: "test@example.com").build()
        blog.isAdmin = true
        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowIfDismissedBefore() {
        let blog = BlogBuilder(context).withJetpack(version: nil, username: nil, email: nil).build()
        blog.isAdmin = true

        settings.setPromptWasDismissed(true, for: blog)

        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowForSitesWithoutJetpackPluginInstallPromptFlagEnabled() {
        settings = JetpackInstallPromptSettings(
            userDefaults: userDefaults,
            showJetpackPluginInstallPrompt: false
        )
        let blog = BlogBuilder(context).withJetpack(version: nil, username: nil, email: nil).build()
        blog.isAdmin = true

        XCTAssertFalse(settings.canDisplay(for: blog))
    }
}
