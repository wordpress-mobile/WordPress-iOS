import UITestsFoundation
import XCTest

class MainNavigationTests: XCTestCase {
    private var mySiteScreen: MySiteScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.login(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        mySiteScreen = try TabNavComponent()
            .goToMySiteScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        removeApp()
    }

    // We run into an issue where the People screen would crash short after loading.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/20112.
    //
    // It would be wise to add similar tests for each item in the menu (then remove this comment).
    func testLoadsPeopleScreen() throws {
        XCTAssert(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")

        mySiteScreen.goToMenu()
        mySiteScreen.goToPeople()

        // We don't have a ScreenObject for the people screen,
        // so we just check that the previous screen is not loaded
        XCTAssertFalse(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")
    }

   func testTabBarNavigation() throws {
       XCTAssert(MySiteScreen.isLoaded(), "MySitesScreen screen isn't loaded.")

       _ = try mySiteScreen
           .tabBar.goToReaderScreen()

       XCTAssert(ReaderScreen.isLoaded(), "Reader screen isn't loaded.")

       // We may get a notifications fancy alert when loading the reader for the first time
       if let alert = try? FancyAlertComponent() {
           alert.cancelAlert()
       }

       _ = try mySiteScreen
           .tabBar.goToNotificationsScreen()
           .dismissNotificationAlertIfNeeded()

       XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
           XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
           XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
       }
   }
}
