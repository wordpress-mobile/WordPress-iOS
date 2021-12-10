import ScreenObject
import XCTest

public class LoginEpilogueScreen: ScreenObject {

    private let loginEpilogueTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["login-epilogue-table"]
    }

    var loginEpilogueTable: XCUIElement { loginEpilogueTableGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [loginEpilogueTableGetter], app: app)
    }

    public func continueWithSelectedSite() throws -> MySiteScreen {
        let firstSite = loginEpilogueTable.cells.element(boundBy: 2)
        firstSite.tap()

        try dismissQuickStartPromptIfNeeded()
        return try MySiteScreen()
    }

    // Used by "Self-Hosted after WordPress.com login" test. When a site is added from the Sites List, the Sites List modal (MySitesScreen)
    // remains active after the epilogue "done" button is tapped.
    public func continueWithSelfHostedSiteAddedFromSitesList() throws -> MySitesScreen {
        let firstSite = loginEpilogueTable.cells.element(boundBy: 2)
        firstSite.tap()

        try dismissQuickStartPromptIfNeeded()
        return try MySitesScreen()
    }

    public func verifyEpilogueDisplays(username: String? = nil, siteUrl: String) -> LoginEpilogueScreen {
        if var expectedUsername = username {
            expectedUsername = "@\(expectedUsername)"
            let actualUsername = app.staticTexts["login-epilogue-username-label"].label
            XCTAssertEqual(expectedUsername, actualUsername, "Username displayed is \(actualUsername) but should be \(expectedUsername)")
        }

        let expectedSiteUrl = getDisplayUrl(for: siteUrl)
        let actualSiteUrl = app.staticTexts["siteUrl"].firstMatch.label
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

    private func dismissQuickStartPromptIfNeeded() throws {
        try XCTContext.runActivity(named: "Dismiss quick start prompt if needed.") { _ in
            guard QuickStartPromptScreen.isLoaded() else { return }

            Logger.log(message: "Dismising quick start prompt...", event: .i)
            _ = try QuickStartPromptScreen().selectNoThanks()
        }
    }
}
