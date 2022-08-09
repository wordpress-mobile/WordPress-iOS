import ScreenObject
import UIKit
import UITestsFoundation
import XCTest

class JetpackScreenshotGeneration: XCTestCase {
    let scanWaitTime: UInt32 = 5

    override func setUpWithError() throws {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite(for: "Jetpack")

        // The app is already launched so we can set it up for screenshots here
        let app = XCUIApplication()
        setupSnapshot(app)

        if XCUIDevice.isPad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }

        try LoginFlow.login(email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        removeApp("Jetpack")
    }

    func testGenerateScreenshots() throws {

        let mySite = try MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "yourjetpack.blog")

        // Open Home
        if XCUIDevice.isPad {
            mySite.goToHomeScreen()
        }

        // Get Site Creation screenshot
        let mySitesScreen = try mySite.showSiteSwitcher()
        let siteIntentScreen = try mySitesScreen
            .tapPlusButton()
            .thenTakeScreenshot(1, named: "SiteCreation")

        try siteIntentScreen.closeModal()
        try mySitesScreen.closeModal()

        // Get Create New screenshot
        let createSheet = try mySite.goToCreateSheet()
            .thenTakeScreenshot(2, named: "CreateNew")

        // Get Page Builder screenshot
        let chooseLayout = try createSheet.goToSitePage()
            .thenTakeScreenshot(3, named: "PageBuilder")

        try chooseLayout.closeModal()

        // Open Menu to be able to access stats
        if XCUIDevice.isPhone {
            mySite.goToMenu()
        }

        // Get Stats screenshot
        let statsScreen = try mySite.goToStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .thenTakeScreenshot(4, named: "Stats")

        // Get Notifications screenshot
        let notificationList = try TabNavComponent()
            .goToNotificationsScreen()
            .dismissNotificationAlertIfNeeded()
        if XCUIDevice.isPad {
            notificationList
                .openNotification(withText: "Reyansh Pawar commented on My Top 10 Pastry Recipes")
        }
        notificationList.thenTakeScreenshot(5, named: "Notifications")
    }
}

extension ScreenObject {

    @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
