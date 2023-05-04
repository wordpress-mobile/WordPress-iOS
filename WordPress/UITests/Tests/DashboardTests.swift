import UITestsFoundation
import XCTest

class DashboardTests: XCTestCase {

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomSiteAddress,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword
        )
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp()
    }

    // This test is JP only.
    func testDomainsCardNavigation() throws {
        try MySiteScreen()
            .scrollToDomainsCard()
            .verifyDomainsCard()
            .tapDomainsCard()
            .verifyDomainsSuggestionsScreenLoaded()
    }
}
