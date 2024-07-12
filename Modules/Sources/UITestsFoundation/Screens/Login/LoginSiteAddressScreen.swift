import ScreenObject
import XCTest

public class LoginSiteAddressScreen: ScreenObject {

    private let siteAddressTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textFields["Site address"]
    }

    private let siteAddressNextButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Site Address Next Button"]
    }

    var siteAddressTextField: XCUIElement { siteAddressTextFieldGetter(app) }
    var siteAddressNextButton: XCUIElement { siteAddressNextButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [siteAddressTextFieldGetter],
            app: app
        )
    }

    public func proceedWith(siteAddress: String) throws -> LoginUsernamePasswordScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteAddress)
        siteAddressNextButton.tap()

        return try LoginUsernamePasswordScreen()
    }

    public func proceedWithWordPress(_ siteAddress: String) throws -> GetStartedScreen {
        siteAddressTextField.tap()
        siteAddressTextField.typeText(siteAddress)
        siteAddressNextButton.tap()

        return try GetStartedScreen()
    }

    public static func isLoaded() -> Bool {
        (try? LoginSiteAddressScreen().isLoaded) ?? false
    }
}
