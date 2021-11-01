import XCTest

// TODO: remove when unifiedAuth is permanent.

private struct ElementStringIDs {
    static let emailTextField = "Login Email Address"
    static let nextButton = "Login Email Next Button"
    static let siteAddressButton = "Self Hosted Login Button"
}

public class LoginEmailScreen: BaseScreen {
    let emailTextField: XCUIElement
    let nextButton: XCUIElement
    let siteAddressButton: XCUIElement

    init() {
        let app = XCUIApplication()
        emailTextField = app.textFields[ElementStringIDs.emailTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]
        siteAddressButton = app.buttons[ElementStringIDs.siteAddressButton]

        super.init(element: emailTextField)
    }

    public func proceedWith(email: String) -> LinkOrPasswordScreen {
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
        let expectedElement = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return expectedElement.exists && expectedElement.isHittable
    }

    static func isEmailEntered() -> Bool {
        let emailTextField = XCUIApplication().textFields[ElementStringIDs.emailTextField]
        return emailTextField.value != nil
    }
}
