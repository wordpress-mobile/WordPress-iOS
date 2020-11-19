import UIKit
import XCTest

class WordPressScreenshotGeneration: XCTestCase {
    let imagesWaitTime: UInt32 = 10

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // This does the shared setup including injecting mocks and launching the app
        setUpTestSuite()

        // The app is already launched so we can set it up for screenshots here
        let app = XCUIApplication()
        setupSnapshot(app)

        if isIpad {
            XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        }

        LoginFlow.login(siteUrl: "WordPress.com", username: ScreenshotCredentials.username, password: ScreenshotCredentials.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() {

        // Get post editor screenshot
        let postList = MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "fourpawsdoggrooming.wordpress.com")
            .gotoPostsScreen()
            .showOnly(.drafts)

        let postEditorScreenshot = postList.selectPost(withSlug: "our-services")
        sleep(imagesWaitTime) // wait for post images to load
        if isIpad {
            BlockEditorScreen()
                .thenTakeScreenshot(1, named: "Editor")
        } else {
            BlockEditorScreen()
                .openBlockPicker()
                .thenTakeScreenshot(1, named: "Editor-With-BlockPicker")
                .closeBlockPicker()
        }
        postEditorScreenshot.close()

        // Get a screenshot of the editor with keyboard (iPad only)
        if isIpad {
            let ipadScreenshot = MySiteScreen()
                .showSiteSwitcher()
                .switchToSite(withTitle: "weekendbakesblog.wordpress.com")
                .gotoPostsScreen()
                .showOnly(.drafts)
                .selectPost(withSlug: "easy-blueberry-muffins")
            BlockEditorScreen().selectBlock(containingText: "Ingredients")
            sleep(imagesWaitTime) // wait for post images to load
            BlockEditorScreen().thenTakeScreenshot(7, named: "Editor-With-Keyboard")
            ipadScreenshot.close()
        } else {
            postList.pop()
        }

        // Get My Site screenshot
        let mySite = MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "tricountyrealestate.wordpress.com")
            .thenTakeScreenshot(4, named: "MySite")

        // Get Media screenshot
        _ = mySite.gotoMediaScreen()
        sleep(imagesWaitTime) // wait for post images to load
        mySite.thenTakeScreenshot(6, named: "Media")

        if !isIpad {
            postList.pop()
        }

        // Get Stats screenshot
        let statsScreen = mySite.gotoStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .months)
            .thenTakeScreenshot(3, named: "Stats")

        // Get Discover screenshot
        // Currently, the view includes the "You Might Like" section
        TabNavComponent()
            .gotoReaderScreen()
            .openDiscover()
            .thenTakeScreenshot(2, named: "Discover")

        // Get Notifications screenshot
        let notificationList = TabNavComponent()
            .gotoNotificationsScreen()
            .dismissNotificationAlertIfNeeded()
        if isIpad {
            notificationList
                .openNotification(withText: "Reyansh Pawar commented on My Top 10 Pastry Recipes")
                .replyToNotification()
        }
        notificationList.thenTakeScreenshot(5, named: "Notifications")
    }
}

extension BaseScreen {
    @discardableResult
    func thenTakeScreenshot(_ index: Int, named title: String) -> Self {
        let mode = isDarkMode ? "dark" : "light"
        let filename = "\(index)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
