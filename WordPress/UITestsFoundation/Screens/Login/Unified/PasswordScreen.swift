import ScreenObject
import XCTest

public class PasswordScreen: ScreenObject {

    private let passwordTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.secureTextFields["Password"]
    }

    private let passwordErrorLabelGetter: (XCUIApplication) -> XCUIElement = {
        $0.cells["Password Error"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Continue Button"]
    }

    var passwordTextField: XCUIElement { passwordTextFieldGetter(app) }
    var passwordErrorLabel: XCUIElement { passwordErrorLabelGetter(app) }
    var continueButton: XCUIElement { continueButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ passwordTextFieldGetter, continueButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func proceedWithValidPassword() throws -> LoginEpilogueScreen {
        try tryProceed(password: "pw")
        app.dismissSavePasswordPrompt()
        return try LoginEpilogueScreen()
    }

    public func proceedWithInvalidPassword() throws -> Self {
        try tryProceed(password: "invalidPswd")

        return self
    }

    public func tryProceed(password: String) throws {
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

        if Locale.current.identifier.contains("ar") {
            passwordTextField.doubleTap()
        }

        passwordTextField.typeText(password)
        continueButton.tap()
    }

    @discardableResult
    public func verifyLoginError() -> Self {
        XCTAssertTrue(passwordErrorLabel.waitForExistence(timeout: 3))
        return self
    }

    public static func isLoaded() -> Bool {
        (try? PasswordScreen().isLoaded) ?? false
    }
}
