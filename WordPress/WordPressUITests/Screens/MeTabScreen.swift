import Foundation
import XCTest

class MeTabScreen: BaseScreen {
    let meTable: XCUIElement
    let tabBar: TabNavComponent
    let logOutButton: XCUIElement
    let logOutAlert: XCUIElement

    init() {
        let app = XCUIApplication()
        meTable = app.tables["Me Table"]
        tabBar = TabNavComponent()
        logOutButton = app.cells["logOutFromWPcomButton"]
        logOutAlert = app.alerts.element(boundBy: 0)

        super.init(element: meTable)
    }

    func isLoggedInToWpcom() -> Bool {
        return logOutButton.exists
    }

    func logout() -> WelcomeScreen {
        app.cells["logOutFromWPcomButton"].tap()
        logOutAlert.buttons.element(boundBy: 1).tap() // Log out confirmation button

        return WelcomeScreen()
    }
}
