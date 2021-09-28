import XCTest

// TODO: remove when unifiedAuth is permanent.

private struct ElementStringIDs {
    static let emailSignupButton = "Sign up with Email Button"
}

public class WelcomeScreenSignupComponent: BaseScreen {
    let emailSignupButton: XCUIElement

    init() {
        emailSignupButton = XCUIApplication().buttons[ElementStringIDs.emailSignupButton]

        super.init(element: emailSignupButton)
    }

    public func selectEmailSignup() -> SignupEmailScreen {
        emailSignupButton.tap()

        return SignupEmailScreen()
    }
}
