import Foundation
import XCTest

class MySitesScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        tabBar = TabNavComponent()
        let blogsTable = XCUIApplication().tables["Blogs"]

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
