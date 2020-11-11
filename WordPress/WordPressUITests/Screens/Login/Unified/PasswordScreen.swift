import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPress.PasswordView"
    static let passwordTextField = "Password"
    static let continueButton = "Continue Button"
    static let errorLabel = "Password Error"
}

class PasswordScreen: BaseScreen {
    let navBar: XCUIElement
    let passwordTextField: XCUIElement
    let continueButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        passwordTextField = app.secureTextFields[ElementStringIDs.passwordTextField]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: passwordTextField)
    }

    func proceedWith(password: String) -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> PasswordScreen {
        passwordTextField.tap()
        passwordTextField.typeText(password)
        continueButton.tap()
        if continueButton.exists && !continueButton.isHittable {
            waitFor(element: continueButton, predicate: "isEnabled == true")
        }
        return self
    }

    func verifyLoginError() -> PasswordScreen {
        let errorLabel = app.cells[ElementStringIDs.errorLabel]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssertTrue(errorLabel.exists)
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
