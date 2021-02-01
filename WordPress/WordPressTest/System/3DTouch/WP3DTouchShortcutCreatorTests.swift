import XCTest
import WordPress

class WP3DTouchShortcutCreatorTests: XCTestCase {
    var testShortcutCreator: WP3DTouchShortcutCreator!

    override func setUp() {
        super.setUp()
        testShortcutCreator = WP3DTouchShortcutCreator()
        UIApplication.shared.shortcutItems = nil
    }

    override func tearDown() {
        testShortcutCreator = nil
        super.tearDown()
    }

    fileprivate func is3DTouchAvailable() -> Bool {
        let window = UIApplication.shared.mainWindow

        return window?.traitCollection.forceTouchCapability == .available
    }

    func testCreateShortcutLoggedOutDoesNotCreatesLoggedOutShortcutsWith3DTouchNotAvailable() {
        testShortcutCreator.createShortcutsIf3DTouchAvailable(false)
        XCTAssertEqual(UIApplication.shared.shortcutItems!.count, is3DTouchAvailable() ? 1 : 0)
    }
}
