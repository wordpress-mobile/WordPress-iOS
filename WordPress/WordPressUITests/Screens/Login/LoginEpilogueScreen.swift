import Foundation
import XCTest

private struct ElementStringIDs {
    static let usernameField = "username"
    static let siteUrlField = "siteUrl"
    static let connectSiteButton = "connectSite"
    static let continueButton = "Continue"
}

class LoginEpilogueScreen: BaseScreen {
    let continueButton: XCUIElement
    let connectSiteButton: XCUIElement
    let usernameField: XCUIElement
    let siteUrlField: XCUIElement

    init() {
        let app = XCUIApplication()
        usernameField = app.staticTexts[ElementStringIDs.usernameField]
        siteUrlField = app.staticTexts[ElementStringIDs.siteUrlField]
        connectSiteButton = app.buttons[ElementStringIDs.connectSiteButton]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: siteUrlField)
    }

    func continueWithSelectedSite() -> MySiteScreen {
        continueButton.tap()
        return MySiteScreen()
    }

    func connectSite() {
        connectSiteButton.tap()
    }

    func verifyEpilogueDisplays(username: String? = nil, siteUrl: String) -> LoginEpilogueScreen {
        if var expectedUsername = username {
            expectedUsername = "@\(expectedUsername)"
            let actualUsername = usernameField.label
            XCTAssertEqual(expectedUsername, actualUsername, "Username displayed is \(actualUsername) but should be \(expectedUsername)")
        }

        let expectedSiteUrl = siteUrl
        let actualSiteUrl = siteUrlField.label
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl, "Site URL displayed is \(actualSiteUrl) but should be \(expectedSiteUrl)")

        return self
    }
}
