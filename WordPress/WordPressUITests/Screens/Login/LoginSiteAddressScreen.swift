import Foundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPressAuthenticator.LoginSiteAddressView"
    static let nextButton = "Site Address Next Button"

    // TODO: clean up comments when unifiedSiteAddress is permanently enabled.

    // For original Site Address. This matches accessibilityIdentifier in Login.storyboard.
    // Leaving here for now in case unifiedSiteAddress is disabled.
    // static let siteAddressTextField = "usernameField"

    // For unified Site Address. This matches TextFieldTableViewCell.accessibilityIdentifier.
    static let siteAddressTextField = "Site address"
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
