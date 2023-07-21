import ScreenObject
import XCTest

class LoginPasswordScreen: ScreenObject {

    private let passwordTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    private let passwordErrorLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["pswdErrorLabel"]
    }

    private let loginButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Password next Button"]
    }

    var loginButton: XCUIElement { loginButtonGetter(app) }
    var passwordErrorLabel: XCUIElement { passwordErrorLabelGetter(app) }
    var passwordTextField: XCUIElement { passwordTextFieldGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [passwordTextFieldGetter],
            app: app
        )
    }

    func proceedWith(password: String) throws -> LoginEpilogueScreen {
        tryProceed(password: password)

        return try LoginEpilogueScreen()
    }

    @discardableResult
    func tryProceed(password: String) -> Self {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        loginButton.tap()
        if loginButton.exists && !loginButton.isHittable {
            XCTAssertEqual(loginButton.waitFor(predicateString: "isEnabled == true"), .completed)
        }
        return self
    }

    func verifyLoginError() -> Self {
        XCTAssertTrue(passwordErrorLabel.waitForExistence(timeout: 2))
        return self
    }

    static func isLoaded() -> Bool {
        (try? LoginPasswordScreen().isLoaded) ?? false
    }
}
