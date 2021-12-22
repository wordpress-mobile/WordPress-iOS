import ScreenObject
import XCTest

public class GetStartedScreen: ScreenObject {

    private let navBarGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Get Started"]
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

    private let backButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Back"]
    }

    var navBar: XCUIElement { navBarGetter(app) }
    public var emailTextField: XCUIElement { emailTextFieldGetter(app) }
    var continueButton: XCUIElement { continueButtonGetter(app) }
    var helpButton: XCUIElement { helpButtonGetter(app) }
    var backButton: XCUIElement { backButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        // Notice we are not checking for the continue button, because that's visible but not
        // enabled, and `ScreenObject` checks for enabled elements.
        try super.init(
            expectedElementGetters: [
                navBarGetter,
                emailTextFieldGetter,
                helpButtonGetter
            ],
            app: app
        )
    }

    public func proceedWith(email: String) throws -> PasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        continueButton.tap()

        return try PasswordScreen()
    }

    public func goBackToPrologue() {
        backButton.tap()
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
