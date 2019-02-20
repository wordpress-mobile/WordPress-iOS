import Foundation
import XCTest

class LoginUsernamePasswordScreen: BaseScreen {
    let navBar: XCUIElement
    let navBackButton: XCUIElement
    let usernameTextField: XCUIElement
    let passwordTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars["WordPressAuthenticator.LoginSelfHostedView"]
        navBackButton = navBar.buttons["Back"]
        usernameTextField = app.textFields["Username"]
        passwordTextField = app.secureTextFields["passwordField"]
        nextButton = app.buttons["submitButton"]

        super.init(element: passwordTextField)
    }

    func proceedWith(username: String, password: String) -> LoginEpilogueScreen {
        usernameTextField.tap()
        usernameTextField.typeText(username)
        passwordTextField.tap()
        passwordTextField.typeText(password)
        nextButton.tap()

        return LoginEpilogueScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["submitButton"].exists
    }
}
