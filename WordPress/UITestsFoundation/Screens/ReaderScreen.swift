import ScreenObject
import XCTest

public class ReaderScreen: ScreenObject {

    private let discoverButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Discover"]
    }

    var discoverButton: XCUIElement { discoverButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:skip:next opening_brace
                { $0.tables["Reader"] },
                discoverButtonGetter
            ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? ReaderScreen().isLoaded) ?? false
    }

    public func openDiscover() -> ReaderScreen {
        discoverButton.tap()

        return self
    }
}
