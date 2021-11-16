import XCTest

// TODO: remove when unifiedAuth is permanent.

private struct ElementStringIDs {
    static let emailLoginButton = "Log in with Email Button"
    static let siteAddressButton = "Self Hosted Login Button"
}

public class WelcomeScreenLoginComponent: BaseScreen {
    let emailLoginButton: XCUIElement
    let siteAddressButton: XCUIElement

    init() {
        emailLoginButton = XCUIApplication().buttons[ElementStringIDs.emailLoginButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        super.init(element: emailLoginButton)
    }

    public func selectEmailLogin() throws -> LoginEmailScreen {
        emailLoginButton.tap()

        return try LoginEmailScreen()
    }

    func goToSiteAddressLogin() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }
}
