import XCTest

// TODO: remove when unifiedAuth is permanent.

private struct ElementStringIDs {
    static let loginButton = "Prologue Log In Button"
    static let signupButton = "Prologue Signup Button"
}

public class WelcomeScreen: BaseScreen {
    let logInButton: XCUIElement
    let signupButton: XCUIElement

    public init() {
        logInButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        signupButton = XCUIApplication().buttons[ElementStringIDs.signupButton]

        super.init(element: logInButton)
    }

    public func selectSignup() throws -> WelcomeScreenSignupComponent {
        signupButton.tap()

        return try WelcomeScreenSignupComponent()
    }

    public func selectLogin() -> WelcomeScreenLoginComponent {
        logInButton.tap()

        return WelcomeScreenLoginComponent()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
