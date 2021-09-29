import XCTest
import XCUITestHelpers

private struct ElementStringIDs {
    // TODO: clean up comments when unifiedSiteAddress is permanently enabled.

    // For original Site Address. These match accessibilityIdentifier in Login.storyboard.
    // Leaving here for now in case unifiedSiteAddress is disabled.
    // static let usernameTextField = "usernameField"
    // static let passwordTextField = "passwordField"
    // static let nextButton = "submitButton"

    // For unified Site Address. This matches TextFieldTableViewCell.accessibilityIdentifier.
    static let usernameTextField = "Username"
    static let passwordTextField = "Password"
    static let nextButton = "Continue Button"
}

public class LoginUsernamePasswordScreen: BaseScreen {
    let usernameTextField: XCUIElement
    let passwordTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        usernameTextField = app.textFields[ElementStringIDs.usernameTextField]
        passwordTextField = app.secureTextFields[ElementStringIDs.passwordTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]

        super.init(element: passwordTextField)
    }

    public func proceedWith(username: String, password: String) -> LoginEpilogueScreen {
        usernameTextField.tap()
        usernameTextField.typeText(username)
        passwordTextField.tap()
        // Workaround to enter password in languages where typing doesn't work
        // Pasting is not reliable enough to use all the time so we only use it where it's necessary
        if ["ru", "th"].contains(Locale.current.languageCode) {
            passwordTextField.paste(text: password)
        } else {
            passwordTextField.typeText(password)
        }
        nextButton.tap()

        return LoginEpilogueScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.nextButton].exists
    }
}
