import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.GetStartedView"
    static let emailTextField = "Email address"
    static let continueButton = "Get Started Email Continue Button"
}

class GetStartedScreen: BaseScreen {
    let navBar: XCUIElement
    let emailTextField: XCUIElement
    let continueButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> PasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        continueButton.tap()

        return PasswordScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }

    static func isEmailEntered() -> Bool {
        let emailTextField = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return emailTextField.value != nil
    }

}
