import ScreenObject
import XCTest

public class LoginUsernamePasswordScreen: ScreenObject {

    private let usernameTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Username"]
    }

    private let passwordTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    var nextButton: XCUIElement { nextButtonGetter(app) }
    var passwordTextField: XCUIElement { passwordTextFieldGetter(app) }
    var usernameTextField: XCUIElement { usernameTextFieldGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
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

    public func proceedWith(username: String, password: String) throws -> MySiteScreen {
        fill(username: username, password: password)
        return try MySiteScreen()
    }

    public func proceedWithSelfHosted(username: String, password: String) throws {
        fill(username: username, password: password)
    }

    public static func isLoaded() -> Bool {
        (try? LoginUsernamePasswordScreen().isLoaded) ?? false
    }

    private func fill(username: String, password: String) {
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

        if #available(iOS 17.2, *) {
            app.dismissSavePasswordPrompt()
        }
    }
}
