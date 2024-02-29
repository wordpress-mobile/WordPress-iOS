import UITestsFoundation
import XCTest

final class MenuNavigationTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    // This test is JP only.
    func testDomainsNavigation() throws {
        try MySiteScreen()
            .goToMoreMenu()
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
