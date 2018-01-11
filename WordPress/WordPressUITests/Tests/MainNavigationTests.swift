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
            .login(email: WPUITestCredentials.testUserEmail, password: WPUITestCredentials.testUserPassword)
    }

    override func tearDown() {
        LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testTabBarNavigation() {
        mySiteScreen
            .switchSite()
            .tabBar.gotoReaderScreen()
            .tabBar.gotoMeScreen()
            .tabBar.gotoNotificationsScreen()
            .tabBar.gotoEditorScreen()
            .goBack()

        XCTAssert(NotificationsScreen().isLoaded())
    }
}
