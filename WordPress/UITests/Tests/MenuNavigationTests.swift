import UITestsFoundation
import XCTest

final class MenuNavigationTests: XCTestCase {

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(
            siteUrl: WPUITestCredentials.testWPcomPaidSite,
            email: WPUITestCredentials.testWPcomUserEmail,
            password: WPUITestCredentials.testWPcomPassword
        )
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    // This test is JP only.
    func testDomainsNavigation() throws {
        try MySiteScreen()
            .goToMenu()
            .goToDomainsScreen()
            .assertScreenIsLoaded()
    }
}
