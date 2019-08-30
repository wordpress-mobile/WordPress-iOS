import Foundation
import XCTest

private struct ElementStringIDs {
    static let emailLoginButton = "Log in with Email Button"
    static let siteAddressButton = "Self Hosted Login Button"
}

class WelcomeScreenLoginComponent: BaseScreen {
    let emailLoginButton: XCUIElement
    let siteAddressButton: XCUIElement

    init() {
        emailLoginButton = XCUIApplication().buttons[ElementStringIDs.emailLoginButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        super.init(element: emailLoginButton)
    }

    func selectEmailLogin() -> LoginEmailScreen {
        emailLoginButton.tap()

        return LoginEmailScreen()
    }

    func goToSiteAddressLogin() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }
}
