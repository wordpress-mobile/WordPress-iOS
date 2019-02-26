import Foundation
import XCTest

class MeTabScreen: BaseScreen {
    let navBar: XCUIElement
    let tabBar: TabNavComponent
    let logOutButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars["Me"].otherElements["Me"]
        tabBar = TabNavComponent()
        logOutButton = app.cells["logOutFromWPcomButton"]

        super.init(element: navBar)
    }

    func isLoggedInToWpcom() -> Bool {
        return logOutButton.exists
    }

    func logout() -> WelcomeScreen {
        app.cells["logOutFromWPcomButton"].tap()
        app.alerts.firstMatch.buttons["Log Out"].tap()

        return WelcomeScreen()
    }
}
