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

    func testDomainsCardNavigation() throws {
        try MySiteScreen()
            .verifyDomainsCard()
            .tapDomainsCard()

        XCTAssertTrue(DomainsScreen.isLoaded(), "\"Domains\" screen isn't loaded after \"Domains\" card tap.")
    }
}
