import XCTest
@testable import WordPress

class QuickStartSettingsTests: CoreDataTestCase {

    private var userDefaults: UserDefaults!
    private var quickStartSettings: QuickStartSettings!

    override func setUp() {
        super.setUp()

        let name = String(describing: QuickStartSettingsTests.self)
        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)
        quickStartSettings = QuickStartSettings(userDefaults: userDefaults)
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
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = id as NSNumber
        return blog
    }

}
