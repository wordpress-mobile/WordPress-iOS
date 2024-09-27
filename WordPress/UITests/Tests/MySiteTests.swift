import UITestsFoundation
import XCTest

final class MySiteTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)
    }

    // We run into an issue where the People screen would crash short after loading.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/20112.
    //
    // It would be wise to add similar tests for each item in the menu (then remove this comment).
    func testLoadsPeopleScreen() throws {
        try MySiteScreen()
            .goToMoreMenu()
        try MySiteMoreMenuScreen()
            .goToPeople()
            .assertScreenIsLoaded()
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
