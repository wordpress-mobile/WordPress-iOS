import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUp() {
        setUpTestSuite()

        _ = LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, username: WPUITestCredentials.testWPcomUsername, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = EditorFlow
            .toggleBlockEditor(to: .on)
            .tabBar.gotoMeScreen()
            .tabBar.gotoMySiteScreen()
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
            .tabBar.gotoBlockEditorScreen()
            .closeEditor()

        XCTAssert(NotificationsScreen.isLoaded())
    }
}
