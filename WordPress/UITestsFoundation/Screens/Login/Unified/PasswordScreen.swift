import ScreenObject
import XCTest

public class PasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // swiftlint:disable:next opening_brace
            expectedElementGetters: [ { $0.secureTextFields["Password"] } ],
            app: app,
            waitTimeout: 10
        )
    }

    public func proceedWithValidPassword() throws -> LoginEpilogueScreen {
        try tryProceed(password: "pw")

        app.dismissSavePasswordPrompt()

        return try LoginEpilogueScreen()
    }

    public func proceedWithInvalidPassword() throws -> PasswordScreen {
        try tryProceed(password: "invalidPswd")

        return try PasswordScreen()
    }

    public func tryProceed(password: String) throws {
        let passwordTextField = expectedElement

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
        let continueButton = app.buttons["Continue Button"]
        continueButton.tap()

        let exists = continueButton.waitForExistence(timeout: 5)
        if exists {
            let startTime = Date()
            let timeout: TimeInterval = 60

            while continueButton.exists && continueButton.isEnabled == false {
                if Date().timeIntervalSince(startTime) > timeout {
                    XCTFail("Continue button still disabled!")
                    break
                }

                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }

        app.dismissSavePasswordPrompt()
    }

    @discardableResult
    public func verifyLoginError() -> PasswordScreen {
        let errorLabel = app.cells["Password Error"]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    public static func isLoaded() -> Bool {
        (try? PasswordScreen().isLoaded) ?? false
    }
}
