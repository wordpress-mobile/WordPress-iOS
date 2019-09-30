import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPressAuthenticator.LoginSiteAddressView"
    static let siteAddressTextField = "usernameField"
    static let nextButton = "Site Address Next Button"
}

class LoginSiteAddressScreen: BaseScreen {
    let navBar: XCUIElement
    let siteAddressTextField: XCUIElement
    let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        siteAddressTextField = app.textFields[ElementStringIDs.siteAddressTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]

        super.init(element: siteAddressTextField)
    }

    func proceedWith(siteUrl: String) -> LoginUsernamePasswordScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteUrl)
        nextButton.tap()

        return LoginUsernamePasswordScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.nextButton].exists
    }
}
