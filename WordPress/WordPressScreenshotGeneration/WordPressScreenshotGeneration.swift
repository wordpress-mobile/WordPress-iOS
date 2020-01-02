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
            XCUIDevice().orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice().orientation = UIDeviceOrientation.portrait
        }

        LoginFlow.login(siteUrl: "WordPress.com", username: ScreenshotCredentials.username, password: ScreenshotCredentials.password)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        SDStatusBarManager.sharedInstance()?.disableOverrides()

        super.tearDown()
    }

    func testGenerateScreenshots() {
        let app = XCUIApplication()

        // Switch to the correct site
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.tables.cells["infocusphotographers.com"].tap()

        // Get My Site Screenshot
        let blogDetailsTable = app.tables["Blog Details Table"]
        XCTAssert(blogDetailsTable.exists, "My site view not visibile")
        // Select blog posts if on an iPad screen
        if isIpad {
            blogDetailsTable.cells["Blog Post Row"].tap()
            waitForElementToExist(element: app.tables["PostsTable"])
            sleep(imagesWaitTime) // Wait for post images to load
        }

        // Get Editor Screenshot
        blogDetailsTable.cells["Blog Post Row"].tap() // tap Blog Posts
        waitForElementToExist(element: app.tables["PostsTable"])

        // Switch the filter to drafts
        app.buttons["drafts"].tap()

        // Get a screenshot of the post editor
        screenshotGutenPost(withSlug: "summer-band-jam", called: "1-PostEditor")

        // Get a screenshot of the drafts feature
        screenshotAztecPost(withSlug: "ideas", called: "5-DraftEditor")

        // Get a screenshot of the full-screen editor
        if isIpad {
            screenshotAztecPost(withSlug: "now-booking-summer-sessions", called: "6-No-Keyboard-Editor")
        }

        // Tap the back button if on an iPhone screen
        if isIPhone {
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
        }

        blogDetailsTable.cells["Media Row"].tap() // Tap Media
        sleep(imagesWaitTime) // wait for post images to load

        snapshot("4-Media")

        // Tap the back button if on an iPhone screen
        if isIPhone {
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
        }

        // Get Stats screenshot
        blogDetailsTable.cells["Stats Row"].tap() // tap Stats

        if app.buttons["dismiss-customize-insights-cell"].exists {
            app.buttons["dismiss-customize-insights-cell"].tap()
        }

        app.buttons["years"].tap()

//        app.segmentedControls.element(boundBy: 0).buttons.element(boundBy: 1).tap() // tap Days

        // This line is for stats v2
        // app.buttons["insights"].tap()

        // Wait for stats to be loaded
//        waitForElementToExist(element: app.otherElements["visitorsViewsGraph"])
//        waitForElementToNotExist(element: app.progressIndicators.firstMatch)

        snapshot("2-Stats")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["notificationsTabButton"].tap()
        XCTAssert(app.tables["Notifications Table"].exists, "Notifications Table not found")

        //Tap the "Not Now" button to dismiss the notifications prompt
        let notNowButton = app.buttons["no-button"]
        if notNowButton.exists {
            notNowButton.tap()
        }

        snapshot("3-Notifications")
    }

    private func screenshotAztecPost(withSlug slug: String, called screenshotName: String, withKeyboard: Bool = false) {

        let app = XCUIApplication()

        tapStatusBarToScrollToTop()
        let cell = app.tables.cells[slug]
        waitForElementToExist(element: cell)

        scrollElementIntoView(element: cell, within: app.tables["PostsTable"])
        cell.tap()

        let editorNavigationBar = app.navigationBars["Azctec Editor Navigation Bar"]
        waitForElementToExist(element: editorNavigationBar)

        if !withKeyboard {
            app.textViews["aztec-editor-title"].tap(withNumberOfTaps: 1, numberOfTouches: 5)
        }

        sleep(imagesWaitTime) // wait for post images to load
        // The title field gets focus automatically
        snapshot(screenshotName)

        editorNavigationBar.buttons["Close"].tap()
        // Dismiss Unsaved Changes Alert if it shows up
        if app.sheets.element(boundBy: 0).exists {
            // Tap discard
            app.sheets.element(boundBy: 0).buttons.element(boundBy: 1).tap()
        }
    }

    private func screenshotGutenPost(withSlug slug: String, called screenshotName: String, withKeyboard: Bool = false) {
        let app = XCUIApplication()

        tapStatusBarToScrollToTop()
        let cell = app.tables.cells[slug]
        waitForElementToExist(element: cell)

        scrollElementIntoView(element: cell, within: app.tables["PostsTable"])
        cell.tap()


        let editorNavigationBar = app.navigationBars["Gutenberg Editor Navigation Bar"]
        waitForElementToExist(element: editorNavigationBar)

        //Tap the "OK" button to dismiss the Gutenberg Prompt
        let notNowButton = app.buttons["defaultAlertButton"]
        if notNowButton.exists {
            notNowButton.tap()
        }

        sleep(imagesWaitTime) // wait for post images to load
        // The title field gets focus automatically
        snapshot(screenshotName)

        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
    }
}
