import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let usernameField = "login-epilogue-username-label"
    static let siteUrlField = "siteUrl"
    static let connectSiteButton = "connectSite"
    static let continueButton = "Done"
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
        connectSiteButton = app.cells[ElementStringIDs.connectSiteButton]
        continueButton = app.buttons[ElementStringIDs.continueButton]

        super.init(element: continueButton)
    }

    func continueWithSelectedSite() -> MySiteScreen {
        continueButton.tap()
        return MySiteScreen()
    }

    //Used by "Self-Hosted after WordPress.com login" test. When a site is added from the Sites List, the Sites List modal remains active after the epilogue "done" button is tapped.
    func continueWithSelfHostedSiteAddedFromSitesList() -> MySitesScreen {
        continueButton.tap()
        return MySitesScreen()
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

        let expectedSiteUrl = getDisplayUrl(for: siteUrl)
        let actualSiteUrl = siteUrlField.firstMatch.label
        XCTAssertEqual(expectedSiteUrl, actualSiteUrl, "Site URL displayed is \(actualSiteUrl) but should be \(expectedSiteUrl)")

        return self
    }

    private func getDisplayUrl(for siteUrl: String) -> String {
        var displayUrl = siteUrl.replacingOccurrences(of: "http(s?)://", with: "", options: .regularExpression)
        if displayUrl.hasSuffix("/") {
            displayUrl = String(displayUrl.dropLast())
        }

        return displayUrl
    }
}
