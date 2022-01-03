import ScreenObject
import XCTest

private struct ElementStringIDs {
    static let nextButton = "Site Address Next Button"

    // TODO: clean up comments when unifiedSiteAddress is permanently enabled.

    // For original Site Address. This matches accessibilityIdentifier in Login.storyboard.
    // Leaving here for now in case unifiedSiteAddress is disabled.
    // static let siteAddressTextField = "usernameField"

    // For unified Site Address. This matches TextFieldTableViewCell.accessibilityIdentifier.
    static let siteAddressTextField = "Site address"
}

public class LoginSiteAddressScreen: ScreenObject {

    let siteAddressTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Site address"]
    }

    var siteAddressTextField: XCUIElement { siteAddressTextFieldGetter(app) }
    var nextButton: XCUIElement { app.buttons[ElementStringIDs.nextButton] }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [siteAddressTextFieldGetter], app: app)
    }

    public func proceedWith(siteUrl: String) throws -> LoginUsernamePasswordScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteUrl)
        nextButton.tap()

        return try LoginUsernamePasswordScreen()
    }

    public func proceedWithWP(siteUrl: String) throws -> GetStartedScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteUrl)
        nextButton.tap()

        return try GetStartedScreen()
    }

    public static func isLoaded() -> Bool {
        (try? LoginSiteAddressScreen().isLoaded) ?? false
    }
}
