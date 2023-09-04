import ScreenObject
import XCTest

public class LoginEmailScreen: ScreenObject {

    let emailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Login Email Address"]
    }

    let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Login Email Next Button"]
    }

    let selfHostedLoginButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Self Hosted Login Button"]
    }

    var emailTextField: XCUIElement { emailTextFieldGetter(app) }
    var nextButton: XCUIElement { nextButtonGetter(app) }
    var selfHostedLoginButton: XCUIElement { selfHostedLoginButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [emailTextFieldGetter, nextButtonGetter],
            app: app
        )
    }

    public func proceedWith(email: String) throws -> LinkOrPasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return try LinkOrPasswordScreen()
    }

    func goToSiteAddressLogin() throws -> LoginSiteAddressScreen {
        selfHostedLoginButton.tap()

        return try LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        (try? LoginEmailScreen().isLoaded) ?? false
    }

    static func isEmailEntered() -> Bool {
        (try? LoginEmailScreen().emailTextField.value != nil) ?? false
    }
}
