import Foundation
import XCTest

class LoginPasswordScreen: BaseScreen {
    let passwordTextField: XCUIElement
    let loginButton: XCUIElement

    init() {
        passwordTextField = XCUIApplication().secureTextFields["Password"]
        loginButton = XCUIApplication().buttons["Log In Button"]
        super.init(element: passwordTextField)
    }

    func proceedWith(password: String) -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        let alertModal = XCUIApplication().alerts["“WordPress” Would Like to Send You Notifications"]
        if alertModal.waitForExistence(timeout: 3) {
            alertModal.buttons["Don’t Allow"].tap()
        }

        return LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        loginButton.tap()
        if loginButton.exists && !loginButton.isHittable {
            _ = waitFor(element: loginButton, predicate: "isEnabled == true")
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
        return XCUIApplication().buttons["Log In Button"].exists
    }
}
