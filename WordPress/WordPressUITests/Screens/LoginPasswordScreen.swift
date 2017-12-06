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
        tryProceed(password: password)
        return LoginEpilogueScreen.init()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        loginButton.tap()
        waitFor(predicate: "isEnabled == true", element: loginButton)
        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        XCTAssert(XCUIApplication().staticTexts["pswdErrorLabel"].exists)
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["Log In Button"].exists
    }
}
