import XCTest
@testable import WordPress

class QuickStartSettingsTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!
    private var userDefaults: UserDefaults!
    private var quickStartSettings: QuickStartSettings!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext

        let name = String(describing: QuickStartSettingsTests.self)
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)
        quickStartSettings = QuickStartSettings(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPromptWasDismissedReturnsFalseIfNotPreviouslyDismissed() {
        let blog = newTestBlog(id: 1)
        let promptWasDismissed = quickStartSettings.promptWasDismissed(for: blog)
        XCTAssertFalse(promptWasDismissed)
    }

    func testPromptWasDismissedReturnsTrueIfPreviouslyDismissed() {
        let blog = newTestBlog(id: 1)
        quickStartSettings.setPromptWasDismissed(true, for: blog)
        let promptWasDismissed = quickStartSettings.promptWasDismissed(for: blog)
        XCTAssertTrue(promptWasDismissed)
    }

    private func newTestBlog(id: Int) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = id as NSNumber
        return blog
    }

}
