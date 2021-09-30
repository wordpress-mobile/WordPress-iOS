import UITestsFoundation
import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = TabNavComponent()
         .gotoMySiteScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        try LoginFlow.logoutIfNeeded()
        try super.tearDownWithError()
    }

    func testTabBarNavigation() {
        XCTAssert(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")

        _ = mySiteScreen
            .tabBar.gotoReaderScreen()

        XCTAssert(ReaderScreen.isLoaded(), "Reader screen isn't loaded.")

        _ = mySiteScreen
            .tabBar.gotoNotificationsScreen()
            .dismissNotificationAlertIfNeeded()

        XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
            XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
            XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
        }
    }
}
