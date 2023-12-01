import ScreenObject
import XCTest

public class MeTabScreen: ScreenObject {

    private let logOutButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["logOutFromWPcomButton"]
    }

    private let logOutAlertGetter: (XCUIApplication) -> XCUIElement = {
        $0.alerts.element(boundBy: 0)
    }

    private let logInButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Log In"]
    }

    private let appSettingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["appSettings"]
    }

    private let myProfileButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["myProfile"]
    }

    private let accountSettingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["accountSettings"]
    }

    private let notificationSettingsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["notificationSettings"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Done"]
    }

    var accountSettingsButton: XCUIElement { accountSettingsButtonGetter(app) }
    var appSettingsButton: XCUIElement { appSettingsButtonGetter(app) }
    var doneButton: XCUIElement { doneButtonGetter(app) }
    var logInButton: XCUIElement { logInButtonGetter(app) }
    var logOutAlert: XCUIElement { logOutAlertGetter(app) }
    var logOutButton: XCUIElement { logOutButtonGetter(app) }
    var myProfileButton: XCUIElement { myProfileButtonGetter(app) }
    var notificationSettingsButton: XCUIElement { notificationSettingsButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ appSettingsButtonGetter ],
            app: app
        )
    }

    public func isLoggedInToWpcom() -> Bool {
        return logOutButton.exists
    }

    public func logout() throws -> WelcomeScreen {
        logOutButton.tap()

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonAxisX {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return try WelcomeScreen()
    }

    public func logoutToPrologue() throws -> PrologueScreen {
        logOutButton.tap()

        // Some localizations have very long "log out" text, which causes the UIAlertView
        // to stack. We need to detect these cases in order to reliably tap the correct button
        if logOutAlert.buttons.allElementsShareCommonAxisX {
            logOutAlert.buttons.element(boundBy: 0).tap()
        }
        else {
            logOutAlert.buttons.element(boundBy: 1).tap()
        }

        return try PrologueScreen()
    }

    func goToLoginFlow() throws -> PrologueScreen {
        logInButton.tap()

        return try PrologueScreen()
    }

    public func dismiss() throws -> MySiteScreen {
        doneButton.tap()

        return try MySiteScreen()
    }

    public func goToAppSettings() throws -> AppSettingsScreen {
        appSettingsButton.tap()

        return try AppSettingsScreen()
    }
}
