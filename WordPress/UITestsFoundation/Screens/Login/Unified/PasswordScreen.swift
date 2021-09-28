import XCTest

private struct ElementStringIDs {
    static let passwordTextField = "Password"
    static let continueButton = "Continue Button"
    static let errorLabel = "Password Error"
}

public class PasswordScreen: BaseScreen {
    let passwordTextField: XCUIElement
    let continueButton: XCUIElement

    public init() {
        let app = XCUIApplication()
        passwordTextField = app.secureTextFields[ElementStringIDs.passwordTextField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: passwordTextField)
    }

    public func proceedWith(password: String) -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return LoginEpilogueScreen()
    }

    public func tryProceed(password: String) -> PasswordScreen {
        // A hack to make tests pass for RtL languages.
        //
        // An unintended side effect of calling passwordTextField.tap() while testing a RtL language is that the
        // text field's secureTextEntry property gets set to 'false'. I suspect this happens because for RtL langagues,
        // the secure text entry toggle button is displayed in the tap area of the passwordTextField.
        //
        // As a result, tests fail with the following error:
        //
        // "No matches found for Descendants matching type SecureTextField from input"
        //
        // Calling passwordTextField.doubleTap() prevents tests from failing by ensuring that the text field's
        // secureTextEntry property remains 'true'.
        passwordTextField.doubleTap()

        passwordTextField.typeText(password)
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }
        return self
    }

    public func verifyLoginError() -> PasswordScreen {
        let errorLabel = app.cells[ElementStringIDs.errorLabel]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
