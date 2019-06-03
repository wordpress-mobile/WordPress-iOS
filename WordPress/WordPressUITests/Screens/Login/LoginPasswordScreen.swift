import Foundation
import XCTest

private struct ElementStringIDs {
    static let passwordTextField = "Password"
    static let loginButton = "Password Next Button"
    static let errorLabel = "pswdErrorLabel"
}

class LoginPasswordScreen: BaseScreen {
    let passwordTextField: XCUIElement
    let loginButton: XCUIElement

    init() {
        passwordTextField = XCUIApplication().secureTextFields[ElementStringIDs.passwordTextField]
        loginButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        super.init(element: passwordTextField)
    }

    func proceedWith(password: String) -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        loginButton.tap()
        if loginButton.exists && !loginButton.isHittable {
            waitFor(element: loginButton, predicate: "isEnabled == true")
        }
        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        let errorLabel = app.staticTexts[ElementStringIDs.errorLabel]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
