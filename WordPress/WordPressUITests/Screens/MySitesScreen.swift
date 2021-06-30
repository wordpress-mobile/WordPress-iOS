import UITestsFoundation
import XCTest

class MySitesScreen: BaseScreen {
    init() {
        let blogsTable = XCUIApplication().tables["Blogs"]
        // need to add "+" button here for Add Site options. Something like:
        // let plusButton = XCUIApplication().buttons["+"]
        // And then the bottom-sheet "add Self-hosted site" option.

        super.init(element: blogsTable)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().tables["Blogs"].exists
    }

    @discardableResult
    func switchToSite(withTitle title: String) -> MySiteScreen {
        XCUIApplication().cells[title].tap()
        return MySiteScreen()
    }
}
