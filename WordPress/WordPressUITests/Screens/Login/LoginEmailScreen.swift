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
        emailTextField = app.textFields["Login Email Address"]
        nextButton = app.buttons["Login Email Next Button"]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> LinkOrPasswordScreen {
        emailTextField.clearAndEnterText(text: email)
        nextButton.tap()

        return LinkOrPasswordScreen()
    }

    static func isLoaded() -> Bool {
        let expectedElement = XCUIApplication().textFields["Login Email Address"]
        return expectedElement.exists && expectedElement.isHittable
    }
}
