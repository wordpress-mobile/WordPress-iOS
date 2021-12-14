import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

class LoginPasswordScreen: ScreenObject {

    let passwordTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [passwordTextFieldGetter], app: app)
    }

    func proceedWith(password: String) throws -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return try LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        let passwordTextField = passwordTextFieldGetter(app)
        passwordTextField.tap()
        passwordTextField.typeText(password)
        let loginButton = app.buttons["Password next Button"]
        loginButton.tap()
        if loginButton.exists && !loginButton.isHittable {
            XCTAssertEqual(loginButton.waitFor(predicateString: "isEnabled == true"), .completed)
        }
        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        let errorLabel = app.staticTexts["pswdErrorLabel"]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    static func isLoaded() -> Bool {
        (try? LoginPasswordScreen().isLoaded) ?? false
    }
}
