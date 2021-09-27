import ScreenObject
import XCTest

public class GetStartedScreen: ScreenObject {

    private let navBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["WordPress.GetStartedView"]
    }

    private let emailTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Email address"]
    }

    private let continueButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Get Started Email Continue Button"]
    }

    private let helpButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["authenticator-help-button"]
    }

    var navBar: XCUIElement { navBarGetter(app) }
    public var emailTextField: XCUIElement { emailTextFieldGetter(app) }
    var continueButton: XCUIElement { continueButtonGetter(app) }
    var helpButton: XCUIElement { helpButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                navBarGetter,
                emailTextFieldGetter,
                continueButtonGetter,
                helpButtonGetter
            ],
            app: app
        )
    }

    public func proceedWith(email: String) -> PasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        continueButton.tap()

        return PasswordScreen()
    }

    public func selectHelp() throws -> SupportScreen {
        helpButton.tap()

        return try SupportScreen()
    }

    public static func isLoaded() -> Bool {
        (try? GetStartedScreen().isLoaded) ?? false
    }

    public static func isEmailEntered() -> Bool {
        (try? GetStartedScreen().emailTextField.value != nil) ?? false
    }
}
