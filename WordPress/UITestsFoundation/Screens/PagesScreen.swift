import ScreenObject
import XCTest

public class PagesScreen: ScreenObject {
    public let tabBar: TabNavComponent

    let pagesTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["PagesTable"]
    }

    var pagesTable: XCUIElement { pagesTableGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()

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
        XCTAssertTrue(pagesTable.staticTexts[pageTitle].waitForIsHittable(), "Pages Screen: \"\(pageTitle)\" page not displayed.")
        return self
    }
}
