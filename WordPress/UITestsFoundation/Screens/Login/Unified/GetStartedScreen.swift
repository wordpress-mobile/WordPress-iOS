import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.GetStartedView"
    static let emailTextField = "Email address"
    static let continueButton = "Get Started Email Continue Button"
    static let helpButton = "authenticator-help-button"
}

public class GetStartedScreen: BaseScreen {
    let navBar: XCUIElement
    public let emailTextField: XCUIElement
    let continueButton: XCUIElement
    let helpButton: XCUIElement

    public init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        continueButton = app.buttons[ElementStringIDs.continueButton]
        helpButton = app.buttons[ElementStringIDs.helpButton]

        super.init(element: emailTextField)
    }

    public func proceedWith(email: String) -> PasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        continueButton.tap()

        return PasswordScreen()
    }

    public func selectHelp() -> SupportScreen {
        helpButton.tap()

        return SupportScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }

    public static func isEmailEntered() -> Bool {
        let emailTextField = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return emailTextField.value != nil
    }

}
