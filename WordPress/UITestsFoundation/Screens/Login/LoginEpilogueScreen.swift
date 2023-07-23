import ScreenObject
import XCTest

public class LoginEpilogueScreen: ScreenObject {

    private let loginEpilogueTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["login-epilogue-table"]
    }

    var loginEpilogueTable: XCUIElement { loginEpilogueTableGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [loginEpilogueTableGetter],
            app: app,
            waitTimeout: 70
        )
    }

    public func continueWithSelectedSite(title: String? = nil) throws -> MySiteScreen {
        if let title = title {
            let selectedSite = loginEpilogueTable.cells[title]
            selectedSite.tap()
        } else {
            let firstSite = loginEpilogueTable.cells.element(boundBy: 2)
            firstSite.tap()
        }

        try dismissOnboardingQuestionsPromptIfNeeded()
        return try MySiteScreen()
    }

    // Used by "Self-Hosted after WordPress.com login" test. When a site is added from the Sites List, the Sites List modal (MySitesScreen)
    // remains active after the epilogue "done" button is tapped.
    public func continueWithSelfHostedSiteAddedFromSitesList() throws -> MySitesScreen {
        let firstSite = loginEpilogueTable.cells.element(boundBy: 2)
        firstSite.tap()

        try dismissQuickStartPromptIfNeeded()
        try dismissOnboardingQuestionsPromptIfNeeded()
        return try MySitesScreen()
    }

    public func verifyEpilogueDisplays(username: String? = nil, siteUrl: String) -> Self {
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
        XCTContext.runActivity(named: "Dismiss quick start prompt if needed.") { _ in
            Logger.log(message: "Dismising quick start prompt...", event: .i)
            do {
                _ = try QuickStartPromptScreen().selectNoThanks()
            } catch {
                return
            }
        }
    }

    private func dismissOnboardingQuestionsPromptIfNeeded() throws {
        XCTContext.runActivity(named: "Dismiss onboarding questions prompt if needed.") { _ in
            Logger.log(message: "Dismissing onboarding questions prompt...", event: .i)
            do {
                _ = try OnboardingQuestionsPromptScreen().selectSkip()
            } catch {
                return
            }
        }
    }

    private func dismissFeatureIntroductionIfNeeded() throws {
        XCTContext.runActivity(named: "Dismiss feature introduction screen if needed.") { _ in
            Logger.log(message: "Dismissing feature introduction screen...", event: .i)
            do {
                _ = try FeatureIntroductionScreen().dismiss()
            } catch {
                return
            }
        }
    }
}
