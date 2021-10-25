import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

public class WelcomeScreen: ScreenObject {

    private let logInButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Log In Button"]
    }

    private let signupButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Prologue Signup Button"]
    }

    var signupButton: XCUIElement { signupButtonGetter(app) }
    var logInButton: XCUIElement { logInButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [logInButtonGetter, signupButtonGetter], app: app)
    }

    public func selectSignup() throws -> WelcomeScreenSignupComponent {
        signupButton.tap()

        return try WelcomeScreenSignupComponent()
    }

    public func selectLogin() throws -> WelcomeScreenLoginComponent {
        logInButton.tap()

        return try WelcomeScreenLoginComponent()
    }

    static func isLoaded() -> Bool {
        (try? WelcomeScreen().isLoaded) ?? false
    }
}
