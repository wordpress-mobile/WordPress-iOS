import UIKit
import XCTest
import SimulatorStatusMagic

class WordPressScreenshotGeneration: XCTestCase {
    let imagesWaitTime: UInt32 = 10

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.
        SDStatusBarManager.sharedInstance()?.enableOverrides()

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
        SDStatusBarManager.sharedInstance()?.disableOverrides()

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
            snapshot("1-Editor")
        } else {
            BlockEditorScreen().openBlockPicker()
            snapshot("1-Editor-With-BlockPicker")
            BlockEditorScreen().closeBlockPicker()
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
            snapshot("7-Editor-With-Keyboard")
            ipadScreenshot.close()
        } else {
            postList.pop()
        }

        // Get My Site screenshot
        let mySite = MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "tricountyrealestate.wordpress.com")
        snapshot("4-MySite")

        // Get Media screenshot
        _ = mySite.gotoMediaScreen()
        sleep(imagesWaitTime) // wait for post images to load
        snapshot("6-Media")

        if !isIpad {
            postList.pop()
        }

        // Get Stats screenshot
        let statsScreen = mySite.gotoStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .months)
        snapshot("3-Stats")

        // Get Discover screenshot
        // Currently, the view includes the "You Might Like" section
        TabNavComponent()
            .gotoReaderScreen()
            .openDiscover()
        snapshot("2-Discover")

        // Get Notifications screenshot
        let notificationList = TabNavComponent()
            .gotoNotificationsScreen()
            .dismissNotificationAlertIfNeeded()
        if isIpad {
            notificationList.openNotification(withText: "Reyansh Pawar commented on My Top 10 Pastry Recipes")
            .replyToNotification()
        }
        snapshot("5-Notifications")
    }
}
