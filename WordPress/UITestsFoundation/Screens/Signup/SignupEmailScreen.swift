import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

public class SignupEmailScreen: ScreenObject {

    private let emailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Signup Email Address"]
    }

    private let nextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Signup Email Next Button"]
    }

    var emailTextField: XCUIElement { emailTextFieldGetter(app) }
    var nextButton: XCUIElement { nextButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [emailTextFieldGetter, nextButtonGetter], app: app)
    }

    public func proceedWith(email: String) throws -> SignupCheckMagicLinkScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return try SignupCheckMagicLinkScreen()
    }
}
