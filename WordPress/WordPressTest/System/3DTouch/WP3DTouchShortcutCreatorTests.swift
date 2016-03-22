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
    
    func testCreateShortcutLoggedOutDoesNotCreatesLoggedOutShortcutsWith3DTouchNotAvailable() {
        testShortcutCreator.createShortcutsIf3DTouchAvailable(false)
        XCTAssertEqual(UIApplication.sharedApplication().shortcutItems!.capacity, 1)
    }
}
