import ScreenObject
import XCTest

// TODO: remove when unifiedAuth is permanent.

public class WelcomeScreenLoginComponent: ScreenObject {

    let emailLoginButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Log in with Email Button"]
    }
    let siteAddressButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Self Hosted Login Button"]
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [emailLoginButtonGetter, siteAddressButtonGetter],
            app: app
        )
    }

    public func selectEmailLogin() throws -> LoginEmailScreen {
        emailLoginButtonGetter(app).tap()

        return try LoginEmailScreen()
    }

    func goToSiteAddressLogin() throws -> LoginSiteAddressScreen {
        siteAddressButtonGetter(app).tap()

        return try LoginSiteAddressScreen()
    }
}
