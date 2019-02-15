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

        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            XCUIDevice().orientation = UIDeviceOrientation.landscapeLeft
        } else {
            XCUIDevice().orientation = UIDeviceOrientation.portrait
        }

        login()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        SDStatusBarManager.sharedInstance()?.disableOverrides()

        super.tearDown()
    }

    func login() {
        let app = XCUIApplication()

        let loginButton = app.buttons["Prologue Log In Button"]

        // Logout first if needed
        if !loginButton.waitForExistence(timeout: 3.0) {
            logout()
        }

        loginButton.tap()
        app.buttons["Self Hosted Login Button"].tap()

        // We have to login by site address, due to security issues with the
        // shared testing account which prevent us from signing in by email address.
        let selfHostedUsernameField = app.textFields["usernameField"]
        waitForElementToExist(element: selfHostedUsernameField)
        selfHostedUsernameField.tap()
        selfHostedUsernameField.typeText("WordPress.com")
        app.buttons["Site Address Next Button"].tap()

        let usernameField = app.textFields["usernameField"]
        let passwordField = app.secureTextFields["passwordField"]

        waitForElementToExist(element: passwordField)
        usernameField.tap()
        usernameField.typeText(ScreenshotCredentials.username)
        passwordField.tap()
        passwordField.typeText(ScreenshotCredentials.password)

        app.buttons["submitButton"].tap()

        let continueButton = app.buttons["Continue"]
        waitForElementToExist(element: continueButton)
        continueButton.tap()

        // Wait for the notification primer, and dismiss if present
        let cancelAlertButton = app.buttons["cancelAlertButton"]
        if cancelAlertButton.waitForExistence(timeout: 3.0) {
            cancelAlertButton.tap()
        }
    }

    func logout() {
        let app = XCUIApplication()
        app.tabBars["Main Navigation"].buttons["meTabButton"].tap()

        let loginButton = app.buttons["Prologue Log In Button"]
        let logoutButton = app.tables.element(boundBy: 0).cells.element(boundBy: 5)
        let logoutAlert = app.alerts.element(boundBy: 0)

        // The order of cancel and log out in the alert varies by language
        // There is no way to set accessibility identifers on them, so we must try both
        logoutButton.tap()
        logoutAlert.buttons.element(boundBy: 1).tap()

        if !loginButton.waitForExistence(timeout: 3.0) {
            // Still not logged out, try the other button
            logoutButton.tap()
            logoutAlert.buttons.buttons.element(boundBy: 0).tap()
        }

        waitForElementToExist(element: loginButton)
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            blogDetailsTable.cells["Blog Post Row"].tap()
            waitForElementToExist(element: app.tables["PostsTable"])
            sleep(imagesWaitTime) // Wait for post images to load
        }

        // Get Editor Screenshot
        blogDetailsTable.cells["Blog Post Row"].tap() // tap Blog Posts
        waitForElementToExist(element: app.tables["PostsTable"])

        // Switch the filter to drafts
        app.buttons["drafts"].tap()

        // Tap on the editor post
        app.tables.cells["summer-band-jam"].tap()

        let editorNavigationBar = app.navigationBars["Azctec Editor Navigation Bar"]
        waitForElementToExist(element: editorNavigationBar)

        sleep(imagesWaitTime) // wait for post images to load
        // The title field gets focus automatically
        snapshot("1-PostEditor")

        editorNavigationBar.buttons["Close"].tap()
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
        blogDetailsTable.cells["Stats Row"].tap() // tap Stats
        app.segmentedControls.element(boundBy: 0).buttons.element(boundBy: 1).tap() // tap Days

        // Wait for stats to be loaded
        waitForElementToExist(element: app.otherElements["visitorsViewsGraph"])
        waitForElementToNotExist(element: app.progressIndicators.firstMatch)

        snapshot("4-Stats")

        blogDetailsTable.cells["Media Row"].tap() // Tap Media
        sleep(imagesWaitTime) // wait for post images to load

        snapshot("2-Media")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["notificationsTabButton"].tap()
        XCTAssert(app.tables["Notifications Table"].exists, "Notifications Table not found")

        //Tap the "Not Now" button to dismiss the notifications prompt
        let notNowButton = app.buttons["no-button"]
        if notNowButton.exists {
            notNowButton.tap()
        }

        snapshot("5-Notifications")
    }
}
