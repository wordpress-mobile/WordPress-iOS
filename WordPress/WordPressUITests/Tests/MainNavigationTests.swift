import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = TabNavComponent()
         .gotoMySiteScreen()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        XCTAssert(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")

        _ = mySiteScreen
            .tabBar.gotoReaderScreen()

        XCTAssert(ReaderScreen.isLoaded(), "Reader screen isn't loaded.")

        _ = mySiteScreen
            .tabBar.gotoNotificationsScreen()

        XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
            XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
            XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
        }
    }
}
