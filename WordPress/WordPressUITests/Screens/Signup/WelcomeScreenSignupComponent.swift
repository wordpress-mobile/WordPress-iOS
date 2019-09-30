import Foundation
import XCTest

private struct ElementStringIDs {
    static let emailSignupButton = "Sign up with Email Button"
}

class WelcomeScreenSignupComponent: BaseScreen {
    let emailSignupButton: XCUIElement

    init() {
        emailSignupButton = XCUIApplication().buttons[ElementStringIDs.emailSignupButton]

        super.init(element: emailSignupButton)
    }

    func selectEmailSignup() -> SignupEmailScreen {
        emailSignupButton.tap()

        return SignupEmailScreen()
    }
}
