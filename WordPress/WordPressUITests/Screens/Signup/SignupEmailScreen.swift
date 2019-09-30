import Foundation
import XCTest

private struct ElementStringIDs {
    static let emailTextField = "Signup Email Address"
    static let nextButton = "Signup Email Next Button"
}

class SignupEmailScreen: BaseScreen {
    let emailTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> SignupCheckMagicLinkScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return SignupCheckMagicLinkScreen()
    }
}
