import ScreenObject
import XCTest

public class SignupEpilogueScreen: ScreenObject {

    private let newAccountHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["New Account Header"]
    }

    private let usernameFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Username Field"]
    }

    private let displayNameFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Display Name Field"]
    }

    private let passwordFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password Field"]
    }

    private let doneButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Done"]
    }

    var displayNameField: XCUIElement { displayNameFieldGetter(app) }
    var doneButton: XCUIElement { doneButtonGetter(app) }
    var newAccountHeader: XCUIElement { newAccountHeaderGetter(app) }
    var passwordField: XCUIElement { passwordFieldGetter(app) }
    var usernameField: XCUIElement { usernameFieldGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [newAccountHeaderGetter],
            app: app
        )
    }

    public func verifyEpilogueContains(username: String, displayName: String) -> Self {
        let actualUsername = usernameField.value as! String
        let actualDisplayName = displayNameField.value as! String

        XCTAssertEqual(username, actualUsername, "Username is set to \(actualUsername) but should be \(username)")
        XCTAssertEqual(displayName, actualDisplayName, "Display name is set to \(actualDisplayName) but should be \(displayName)")

        return self
    }

    public func setPassword(_ password: String) -> Self {
        passwordField.tap()
        passwordField.typeText(password)
        doneButton.tap()

        return self
    }

    public func continueWithSignup() throws -> MySiteScreen {
        doneButton.tap()

        return try MySiteScreen()
    }
}
