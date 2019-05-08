import Foundation
import XCTest

class MeTabScreen: BaseScreen {
    let meTable: XCUIElement
    let tabBar: TabNavComponent
    let logOutButton: XCUIElement

    init() {
        let app = XCUIApplication()
        meTable = app.tables["Me Table"]
        tabBar = TabNavComponent()
        logOutButton = app.cells["logOutFromWPcomButton"]

        super.init(element: meTable)
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
