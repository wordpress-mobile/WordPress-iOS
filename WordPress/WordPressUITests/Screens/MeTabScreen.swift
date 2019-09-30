import Foundation
import XCTest

class MeTabScreen: BaseScreen {
    let tabBar: TabNavComponent
    let logOutButton: XCUIElement
    let logOutAlert: XCUIElement
    let appSettingsButton: XCUIElement
    let myProfileButton: XCUIElement
    let accountSettingsButton: XCUIElement
    let notificationSettingsButton: XCUIElement

    init() {
        let app = XCUIApplication()
        tabBar = TabNavComponent()
        logOutButton = app.cells["logOutFromWPcomButton"]
        logOutAlert = app.alerts.element(boundBy: 0)
        appSettingsButton = app.cells["appSettings"]
        myProfileButton = app.cells["myProfile"]
        accountSettingsButton = app.cells["accountSettings"]
        notificationSettingsButton = app.cells["notificationSettings"]

        super.init(element: appSettingsButton)
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
