import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = EditorFlow
            .toggleBlockEditor(to: .on)
            .goBackToMySite()
    }

    override func tearDown() {
        takeScreenshotOfFailedTest()
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        mySiteScreen
            .tabBar.gotoMySitesScreen()
            .tabBar.gotoReaderScreen()
            .tabBar.gotoMeScreen()
            .tabBar.gotoNotificationsScreen()
            .tabBar.gotoBlockEditorScreen()
            .closeEditor()

        XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
            XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
            XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
        }
    }
}
