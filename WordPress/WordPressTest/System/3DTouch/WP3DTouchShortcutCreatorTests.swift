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
        let provider = MockShortcutsProvider(available: false)
        let testShortcutCreator = WP3DTouchShortcutCreator(shortcutsProvider: provider)
        testShortcutCreator.createShortcutsIf3DTouchAvailable(false)
        XCTAssertEqual(provider.shortcutItems!.count, 0)
    }

    func testCreateShortcutLoggedOutCreatesLoggedInShortcutWith3DTouchAvailable() {
        let provider = MockShortcutsProvider(available: true)
        let testShortcutCreator = WP3DTouchShortcutCreator(shortcutsProvider: provider)
        testShortcutCreator.createShortcutsIf3DTouchAvailable(false)
        XCTAssertEqual(provider.shortcutItems!.count, 1)
        XCTAssertEqual(provider.shortcutItems![0].type, "org.wordpress.LogIn")
    }
}

class MockShortcutsProvider: ApplicationShortcutsProvider {
    var shortcutItems: [UIApplicationShortcutItem]? = []
    let is3DTouchAvailable: Bool

    init(available: Bool) {
        is3DTouchAvailable = available
    }
}
