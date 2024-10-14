import ScreenObject
import UIKit
import UITestsFoundation
import XCTest

class WordPressScreenshotGeneration: XCTestCase {
    let imagesWaitTime: UInt32 = 10

    @MainActor
    override func setUpWithError() throws {
        super.setUp()

        let app = XCUIApplication(bundleIdentifier: "org.wordpress")

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite(for: app, removeBeforeLaunching: true)

        // The app is already launched so we can set it up for screenshots here
        setupSnapshot(app)

        if XCTestCase.isPad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }

        try LoginFlow.login(siteAddress: "WordPress.com", username: ScreenshotCredentials.username, password: ScreenshotCredentials.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        removeApp()
    }

    func testGenerateScreenshots() throws {

        // Get post editor screenshot
        let postList = try MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "fourpawsdoggrooming.wordpress.com")
            .goToPostsScreen()
            .showOnly(.drafts)

        let postEditorScreenshot = try postList.selectPost(withSlug: "our-services")
        sleep(imagesWaitTime) // wait for post images to load
        if XCTestCase.isPad {
            try BlockEditorScreen()
                .thenTakeScreenshot(1, named: "Editor")
        } else {
            try BlockEditorScreen()
                .openBlockPicker()
                .thenTakeScreenshot(1, named: "Editor-With-BlockPicker")
                .closeBlockPicker()
        }
        postEditorScreenshot.close()

        // Get a screenshot of the editor with keyboard (iPad only)
        if XCTestCase.isPad {
            let ipadScreenshot = try MySiteScreen()
                .showSiteSwitcher()
                .switchToSite(withTitle: "weekendbakesblog.wordpress.com")
                .goToPostsScreen()
                .showOnly(.drafts)
                .selectPost(withSlug: "easy-blueberry-muffins")
            try BlockEditorScreen().selectBlock(containingText: "Ingredients")
            sleep(imagesWaitTime) // wait for post images to load
            try BlockEditorScreen().thenTakeScreenshot(7, named: "Editor-With-Keyboard")
            ipadScreenshot.close()
        } else {
            postList.pop()
        }

        // Get My Site screenshot
        let mySite = try MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "tricountyrealestate.wordpress.com")
            .thenTakeScreenshot(4, named: "MySite")

        // Get Media screenshot
        _ = try mySite.goToMediaScreen()
        sleep(imagesWaitTime) // wait for post images to load
        mySite.thenTakeScreenshot(6, named: "Media")

        if !XCTestCase.isPad {
            postList.pop()
        }

        // Get Stats screenshot
        let statsScreen = try mySite.goToStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: "months")
            .thenTakeScreenshot(3, named: "Stats")

        // Get Discover screenshot
        // Currently, the view includes the "You Might Like" section
        try TabNavComponent()
            .goToReaderScreen()
            .openDiscoverTab()
            .thenTakeScreenshot(2, named: "Discover")

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
