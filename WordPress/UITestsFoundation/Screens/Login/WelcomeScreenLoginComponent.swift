import ScreenObject
import XCTest

public class WelcomeScreenLoginComponent: ScreenObject {

    private let emailLoginButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Log in with Email Button"]
    }

    private let siteAddressButtonGetter: (XCUIApplication) -> XCUIElement = {
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
