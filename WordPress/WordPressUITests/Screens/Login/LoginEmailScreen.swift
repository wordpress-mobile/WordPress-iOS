import Foundation
import XCTest

class LoginEmailScreen: BaseScreen {
    let navBar: XCUIElement
    let navBackButton: XCUIElement
    let emailTextField: XCUIElement
    let nextButton: XCUIElement
    let siteAddressButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars["WordPress.LoginEmailView"]
        navBackButton = navBar.buttons["Back"]
        emailTextField = app.textFields["Login Email Address"]
        nextButton = app.buttons["Login Email Next Button"]
        siteAddressButton = app.buttons["Self Hosted Login Button"]

        super.init(element: emailTextField)
    }

    func proceedWith(email: String) -> LinkOrPasswordScreen {
        emailTextField.tap()
        emailTextField.typeText(email)
        nextButton.tap()

        return LinkOrPasswordScreen()
    }

    func goToSiteAddressLogin() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        let expectedElement = XCUIApplication().textFields["Login Email Address"]
        return expectedElement.exists && expectedElement.isHittable
    }

    static func isEmailEntered() -> Bool {
        let emailTextField = XCUIApplication().textFields["Login Email Address"]
        return emailTextField.value != nil
    }
}
