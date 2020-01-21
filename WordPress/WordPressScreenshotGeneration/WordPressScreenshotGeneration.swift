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

        let mySite = MySiteScreen()
            .showSiteSwitcher()
            .switchToSite(withTitle: "infocusphotographers.com")

        let postList = mySite
            .gotoPostsScreen()
            .showOnly(.drafts)

        let firstPostEditorScreenshot = postList.selectPost(withSlug: "summer-band-jam")
        snapshot("1-PostEditor")
        firstPostEditorScreenshot.close()

        // Get a screenshot of the drafts feature
        let secondPostEditorScreenshot = postList.selectPost(withSlug: "ideas")
        snapshot("5-DraftEditor")
        secondPostEditorScreenshot.close()

        // Get a screenshot of the full-screen editor
        if isIpad {
            let ipadScreenshot = postList.selectPost(withSlug: "now-booking-summer-sessions")
            snapshot("6-No-Keyboard-Editor")
            ipadScreenshot.close()
        }

        if !isIpad {
            postList.pop()
        }

        _ = mySite.gotoMediaScreen()
        sleep(imagesWaitTime) // wait for post images to load
        snapshot("4-Media")

        if !isIpad {
            postList.pop()
        }
        // Get Stats screenshot
        let statsScreen = mySite.gotoStatsScreen()
        statsScreen
            .dismissCustomizeInsightsNotice()
            .switchTo(mode: .years)

        snapshot("2-Stats")

        TabNavComponent()
            .gotoNotificationsScreen()
            .dismissNotificationMessageIfNeeded()

        snapshot("3-Notifications")
    }
}
