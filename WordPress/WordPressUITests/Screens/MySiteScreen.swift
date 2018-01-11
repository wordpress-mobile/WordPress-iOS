import Foundation
import XCTest

class MySiteScreen: BaseScreen {
    let tabBar: TabNavComponent

    init() {
        let blogTable = XCUIApplication().tables["Blog Details Table"]
        tabBar = TabNavComponent()

        super.init(element: blogTable)
    }

    func switchSite() -> MySitesScreen {
        app.buttons["Switch Site"].tap()
        return MySitesScreen()
    }
}
