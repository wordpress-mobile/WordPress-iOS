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
        try MySiteScreen()
            .goToMoreMenu()
            .goToDomainsScreen()
            .assertScreenIsLoaded()
    }
}
