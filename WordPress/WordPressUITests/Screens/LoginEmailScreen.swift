import Foundation
import XCTest

class LoginEmailScreen: BaseScreen {
    let navBar: XCUIElement
    let navBackButton: XCUIElement
    let emailTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars["WordPress.LoginEmailView"]
        navBackButton = navBar.buttons["Back"]
        emailTextField = app.textFields["Email address"]
        nextButton = app.buttons["Next Button"]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> LinkOrPasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return LinkOrPasswordScreen.init()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["Log In Button"].exists
    }

}
