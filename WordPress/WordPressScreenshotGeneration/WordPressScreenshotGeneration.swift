import UIKit
import XCTest

class WordPressScreenshotGeneration: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            XCUIDevice().orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice().orientation = UIDeviceOrientation.portrait
        }

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() {
        let app = XCUIApplication()

        let logInExists = app.buttons["Log In Button"].exists

        // Logout first if needed
        if !logInExists {
            app.tabBars["Main Navigation"].buttons["meTabButton"].tap()
            app.tables.element(boundBy: 0).cells.element(boundBy: 5).tap() // Tap disconnect
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 1).tap() // Tap disconnect
        }

        app.buttons["Log In Button"].tap()
        app.buttons["Self Hosted Login Button"].tap()

        let username = ""
        let password = ""

        // We have to login by site address, due to security issues with the
        // shared testing account which prevent us from signing in by email address.
        app.textFields["usernameField"].tap()
        app.textFields["usernameField"].typeText("WordPress.com")
        app.buttons["Next Button"].tap()

        guard app.secureTextFields["passwordField"].waitForExistence(timeout: 3.0) else {
            XCTFail("The password field couldn't be found.")
            return
        }

        app.textFields["usernameField"].tap()
        app.textFields["usernameField"].typeText(username)
        app.secureTextFields["passwordField"].tap()
        app.secureTextFields["passwordField"].typeText(password)

        app.buttons["submitButton"].tap()

        sleep(2)
        app.buttons["Continue"].tap()

        // Wait for the notification primer, and dismiss if present
        if app.buttons["cancelAlertButton"].waitForExistence(timeout: 3.0) {
            app.buttons["cancelAlertButton"].tap()
        }

        // Get My Site Screenshot
        // Select blog posts if on an iPad screen
        if UIDevice.current.userInterfaceIdiom == .pad {
            app.tables.cells["Blog Post Row"].tap()
            sleep(2)
        }
        snapshot("3-My-Site")

        // Get Editor Screenshot
        app.tables.cells["Blog Post Row"].tap() // tap Blog Posts
        sleep(2)

        // Tap on the first post to bring up the editor
        app.tables["PostsTable"].tap()

        // The title field gets focus automatically
        sleep(2)
        snapshot("1-PostEditor")

        app.navigationBars["Azctec Editor Navigation Bar"].buttons["Close"].tap()
        // Dismiss Unsaved Changes Alert if it shows up
        if app.sheets.element(boundBy: 0).exists {
            // Tap discard
            app.sheets.element(boundBy: 0).buttons.element(boundBy: 1).tap()
        }

        // Get Stats screenshot
        // Tap the back button if on an iPhone screen
        if UIDevice.current.userInterfaceIdiom == .phone {
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
        }
        app.tables["Blog Details Table"].cells.element(boundBy: 0).tap() // tap Stats
        app.segmentedControls.element(boundBy: 0).buttons.element(boundBy: 1).tap() // tap Days
        sleep(5)
        snapshot("4-Stats")

        // Get Reader Screenshot
        app.tabBars["Main Navigation"].buttons["readerTabButton"].tap(withNumberOfTaps: 2,
                                                                      numberOfTouches: 2)
        sleep(1)
        app.tables.cells.element(boundBy: 1).tap() // tap Discover
        sleep(5)
        snapshot("2-Reader")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["notificationsTabButton"].tap()
        snapshot("5-Notifications")
    }
}
