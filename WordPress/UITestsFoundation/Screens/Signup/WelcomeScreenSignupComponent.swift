import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

public class WelcomeScreenSignupComponent: ScreenObject {

    private let emailSignupButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Sign up with Email Button"]
    }

    var emailSignupButton: XCUIElement { emailSignupButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [emailSignupButtonGetter], app: app)
    }

    public func selectEmailSignup() throws -> SignupEmailScreen {
        emailSignupButton.tap()

        return try SignupEmailScreen()
    }
}
