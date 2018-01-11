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
        let switchSiteButton = app.buttons["Switch Site"]
        switchSiteButton.tap()
        return MySitesScreen()
    }
}
