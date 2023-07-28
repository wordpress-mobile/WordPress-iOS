import UITestsFoundation
import XCTest

final class MenuNavigationTests: XCTestCase {

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
        try MySiteScreen()
            .goToMenu()
            .goToDomainsScreen()
            .assertScreenIsLoaded()
    }
}
