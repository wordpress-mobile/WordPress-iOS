import Foundation
import XCTest

private struct ElementStringIDs {
    static let loginButton = "Prologue Log In Button"
    static let signupButton = "Prologue Signup Button"
}

class WelcomeScreen: BaseScreen {
    let logInButton: XCUIElement
    let signupButton: XCUIElement

    init() {
        logInButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        signupButton = XCUIApplication().buttons[ElementStringIDs.signupButton]

        super.init(element: logInButton)
    }

    func selectSignup() -> WelcomeScreenSignupComponent {
        signupButton.tap()

        return WelcomeScreenSignupComponent()
    }

    func selectLogin() -> WelcomeScreenLoginComponent {
        logInButton.tap()

        return WelcomeScreenLoginComponent()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
