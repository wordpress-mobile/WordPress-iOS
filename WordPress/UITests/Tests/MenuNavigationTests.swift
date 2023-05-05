import UITestsFoundation
import XCTest

final class MenuNavigationTests: XCTestCase {

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
    func testDomainsNavigation() throws {
        try MySiteScreen()
            .goToMenu()
            .goToDomainsScreen()
            .verifyDomainsScreenLoaded()
    }
}
