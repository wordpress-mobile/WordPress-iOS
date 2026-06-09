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

extension UIApplication {
    // The test host adopts the UIScene life cycle (the app Info.plist declares a scene
    // manifest) but never connects a window scene, so `keyWindow` is nil here. Fall back to
    // the app delegate's window (`TestingAppDelegate` creates one) so `mainWindow` resolves
    // during tests. This override is loaded after the framework copies, so it wins.
    @objc var mainWindow: UIWindow? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
            ?? (delegate?.window ?? nil)
    }
}
