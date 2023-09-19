import ScreenObject
import XCTest

public class PagesScreen: ScreenObject {

    private let pagesTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["PagesTable"]
    }

    private let publishedButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["published"]
    }

    var pagesTable: XCUIElement { pagesTableGetter(app) }
    var publishedButton: XCUIElement { publishedButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {

        try super.init(
            expectedElementGetters: [ pagesTableGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? PagesScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyPagesScreen(hasPage pageTitle: String) -> Self {
        // If test is not on Published tab, tap to go to Published tab before asserting
        if !publishedButton.isSelected {
            publishedButton.tap()
        }

        XCTAssertTrue(pagesTable.staticTexts[pageTitle].waitForIsHittable(), "Pages Screen: \"\(pageTitle)\" page not displayed.")
        return self
    }
}
