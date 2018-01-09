import Foundation
import XCTest

class MeTabScreen: BaseScreen {
    let navBar: XCUIElement

    init() {
        navBar = XCUIApplication().navigationBars["Me"].otherElements["Me"]

        super.init(element: navBar)
    }

    func logout() -> WelcomeScreen {
        app.cells["logOutFromWPcomButton"].tap()
        app.alerts.firstMatch.buttons["Log Out"].tap()

        return WelcomeScreen.init()
    }
}
