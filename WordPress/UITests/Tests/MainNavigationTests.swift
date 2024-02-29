import UITestsFoundation
import XCTest

class MainNavigationTests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)

        try MySiteScreen().goToMoreMenu()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
    }

    // We run into an issue where the People screen would crash short after loading.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/20112.
    //
    // It would be wise to add similar tests for each item in the menu (then remove this comment).
    func testLoadsPeopleScreen() throws {
        try MySiteMoreMenuScreen()
            .goToPeople()
            .assertScreenIsLoaded()
    }

   func testTabBarNavigation() throws {
       try TabNavComponent()
           .goToReaderScreen()
           .assertScreenIsLoaded()

       // We may get a notifications fancy alert when loading the reader for the first time
       if let alert = try? FancyAlertComponent() {
           alert.cancelAlert()
       }

       try TabNavComponent()
           .goToNotificationsScreen()
           .dismissNotificationAlertIfNeeded()

       XCTContext.runActivity(named: "Confirm Notifications screen and main navigation bar are loaded.") { (activity) in
           XCTAssert(NotificationsScreen.isLoaded(), "Notifications screen isn't loaded.")
           XCTAssert(TabNavComponent.isVisible(), "Main navigation bar isn't visible.")
       }
   }
}
