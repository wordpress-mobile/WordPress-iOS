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

        settings = JetpackInstallPromptSettings(userDefaults: userDefaults)
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
        let blog = buildSelfHostedBlog(jetpackInstalled: false, jetpackConnected: false, isAdmin: true)
        XCTAssertTrue(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowForNonAdmins() {
        let blog = buildSelfHostedBlog(jetpackInstalled: false, jetpackConnected: false, isAdmin: false)
        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillShowForBlogsWithJetpackNotConnected() {
        let blog = buildSelfHostedBlog(jetpackInstalled: true, jetpackConnected: false, isAdmin: true)
        XCTAssertTrue(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowForBlogsWithJetpackConnected() {
        let blog = buildSelfHostedBlog(jetpackInstalled: true, jetpackConnected: true, isAdmin: true)
        XCTAssertFalse(settings.canDisplay(for: blog))
    }

    func testPromptWillNotShowIfDismissedBefore() {
        let blog = buildSelfHostedBlog(jetpackInstalled: false, jetpackConnected: false, isAdmin: true)

        settings.setPromptWasDismissed(true, for: blog)

        XCTAssertFalse(settings.canDisplay(for: blog))
    }
}

private extension JetpackInstallPromptTests {
    func buildSelfHostedBlog(jetpackInstalled: Bool, jetpackConnected: Bool, isAdmin: Bool) -> Blog {
        let version: String? = jetpackInstalled ? "1.0" : nil
        let clientId: Int? = jetpackConnected ? 1 : nil

        let blog = BlogBuilder(context).withJetpack(clientId: clientId, version: version, username: nil, email: nil).build()
        blog.isAdmin = isAdmin

        return blog
    }
}
