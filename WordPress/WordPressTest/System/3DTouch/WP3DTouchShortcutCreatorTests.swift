import XCTest
import WordPress

class WP3DTouchShortcutCreatorTests: XCTestCase
{
    var testShortcutCreator: WP3DTouchShortcutCreator!

    override func setUp() {
        super.setUp()
        testShortcutCreator = WP3DTouchShortcutCreator()
        UIApplication.sharedApplication().shortcutItems = nil
    }

    override func tearDown() {
        testShortcutCreator = nil
        super.tearDown()
    }

    private func is3DTouchAvailable() -> Bool {
        let window = UIApplication.sharedApplication().keyWindow

        return window?.traitCollection.forceTouchCapability == .Available
    }

    func testCreateShortcutLoggedOutDoesNotCreatesLoggedOutShortcutsWith3DTouchNotAvailable() {
        testShortcutCreator.createShortcutsIf3DTouchAvailable(false)
        XCTAssertEqual(UIApplication.sharedApplication().shortcutItems!.count, is3DTouchAvailable() ? 1:0)
    }
}
