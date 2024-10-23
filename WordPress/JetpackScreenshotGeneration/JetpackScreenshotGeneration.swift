import ScreenObject
import UIKit
import UITestsFoundation
import XCTest

class JetpackScreenshotGeneration: XCTestCase {
    let scanWaitTime: UInt32 = 5

    @MainActor
    override func setUpWithError() throws {
        super.setUp()

        let app = XCUIApplication.jetpack

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite(for: app, removeBeforeLaunching: true)

        // The app is already launched so we can set it up for screenshots here
        setupSnapshot(app)

        if XCTestCase.isPad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }

        try LoginFlow.login(email: WPUITestCredentials.testWPcomUserEmail)
    }

    override func tearDown() {
        removeApp(.jetpack)
        super.tearDown()
    }

    func testGenerateScreenshots() throws {

        let mySite = try MySiteScreen()
        let mySiteMenu = try MySiteMoreMenuScreen()

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
        if XCTestCase.isPhone {
            try mySite.goToMoreMenu()
        }

        // Get Stats screenshot
        let statsScreen = try mySiteMenu.goToStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .thenTakeScreenshot(4, named: "Stats")

        // Get Notifications screenshot
        let notificationList = try TabNavComponent()
            .goToNotificationsScreen()
        if XCTestCase.isPad {
            notificationList
                .openNotification(withSubstring: "commented on")
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

extension XCUIApplication {

    static let jetpack = XCUIApplication(bundleIdentifier: "com.automattic.jetpack")
}
