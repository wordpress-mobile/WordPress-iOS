import ScreenObject
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

public class LoginUsernamePasswordScreen: ScreenObject {

    let usernameTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields[ElementStringIDs.usernameTextField]
    }

    let passwordTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields[ElementStringIDs.passwordTextField]
    }

    let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons[ElementStringIDs.nextButton]
    }

    var usernameTextField: XCUIElement { usernameTextFieldGetter(app) }
    var passwordTextField: XCUIElement { passwordTextFieldGetter(app) }
    var nextButton: XCUIElement { nextButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        // Notice that we don't use the "next button" getter because, at the time the screen loads,
        // that element is disabled. `ScreenObject` uses `isEnabled == true` on the elements we
        // pass at `init`.
        try super.init(
            expectedElementGetters: [
                usernameTextFieldGetter,
                passwordTextFieldGetter
            ],
            app: app
        )
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
        (try? LoginUsernamePasswordScreen().isLoaded) ?? false
    }
}
