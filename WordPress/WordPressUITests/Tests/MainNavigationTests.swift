import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchArguments = ["NoAnimations"]
        app.activate()

        mySiteScreen = LoginFlow
            .login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
    }

    override func tearDown() {
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        mySiteScreen
            .tabBar.gotoMySitesScreen()
            .tabBar.gotoReaderScreen()
            .tabBar.gotoMeScreen()
            .tabBar.gotoNotificationsScreen()
            .tabBar.gotoEditorScreen()
            .closeEditor()

        XCTAssert(NotificationsScreen.isLoaded())
    }
}
