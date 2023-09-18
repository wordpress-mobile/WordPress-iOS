import UITestsFoundation
import XCTest

final class MenuNavigationTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow
            .login(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    // This test is JP only.
    func testDomainsNavigation() throws {
        // On iPad, the menu items are already listed on screen, so we don't need to tap More Menu button
        if XCUIDevice.isPhone {
            try MySiteScreen()
                .goToMoreMenu()
        }

        try MySiteMoreMenuScreen()
            .goToDomainsScreen()
            .assertScreenIsLoaded()
    }

    func testViewSiteFromMySite() throws {
        let siteTitle = try MySiteScreen()
            .getSiteTitle()

        try MySiteScreen()
            .tapSiteAddress()
            .verifySiteDisplayedInWebView(siteTitle)
    }

}
