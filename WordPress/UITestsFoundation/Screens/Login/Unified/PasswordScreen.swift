import ScreenObject
import XCTest

public class PasswordScreen: ScreenObject {

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            // swiftlint:disable:next opening_brace
            expectedElementGetters: [ { $0.secureTextFields["Password"] } ],
            app: app
        )
    }

    public func proceedWith(password: String) throws -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return try LoginEpilogueScreen()
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
        let passwordTextField = expectedElement
        passwordTextField.doubleTap()

        passwordTextField.typeText(password)
        let continueButton = app.buttons["Continue Button"]
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            XCTAssertEqual(continueButton.waitFor(predicateString: "isEnabled == true"), .completed)
        }
        return self
    }

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
