import Foundation
import XCTest

class LoginSiteAddressScreen: BaseScreen {
    let navBar: XCUIElement
    let navBackButton: XCUIElement
    let siteAddressTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars["WordPressAuthenticator.LoginSiteAddressView"]
        navBackButton = navBar.buttons["Back"]
        siteAddressTextField = app.textFields["usernameField"]
        nextButton = app.buttons["Site Address Next Button"]

        super.init(element: siteAddressTextField)
    }

    func proceedWith(siteUrl: String) -> LoginUsernamePasswordScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteUrl)
        nextButton.tap()

        return LoginUsernamePasswordScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons["Site Address Next Button"].exists
    }
}
