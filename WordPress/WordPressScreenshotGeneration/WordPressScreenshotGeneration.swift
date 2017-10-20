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

        let logInExists = app.buttons["Log In"].exists

        // Logout first if needed
        if !logInExists {
            app.tabBars["Main Navigation"].buttons["meTabButton"].tap()
            app.tables.element(boundBy: 0).cells.element(boundBy: 5).tap() // Tap disconnect
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 1).tap() // Tap disconnect
        }

        app.buttons["Log In"].tap()

        let email = ""
        let password = ""

        // Login step 1: email
        let emailTextField =  app.textFields["Email address"]
        emailTextField.tap()
        emailTextField.typeText(email)
        app.buttons["Next Button"].tap()

        // Login step 2: ignore magic link
        app.buttons["Use Password"].tap()

        // Login step 3: password
        let passwordTextField = app.secureTextFields["Password"]
        passwordTextField.typeText(password)
        app.buttons["Log In Button"].tap()

        // Login step 4: epilogue, continue
        app.buttons["Continue"].tap()

        // Get Reader Screenshot
        app.tabBars["Main Navigation"].buttons["readerTabButton"].tap(withNumberOfTaps: 2,
                                                                      numberOfTouches: 2)
        sleep(1)
        app.tables.cells.element(boundBy: 1).tap() // tap Discover
        sleep(5)
        snapshot("1-Reader")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["notificationsTabButton"].tap()
        snapshot("2-Notifications")

        // Get Posts screenshot
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        app.tables.cells.element(boundBy: 2).tap() // tap Blog Posts
        sleep(2)
        snapshot("3-BlogPosts")

        // Get Editor screenshot
        // Tap on the first post to bring up the editor
        app.tables["PostsTable"].tap()
        // The title field gets focus automatically
        sleep(2)
        snapshot("4-PostEditor")

        app.navigationBars["Azctec Editor Navigation Bar"].buttons["Close"].tap()
        // Dismiss Unsaved Changes Alert if it shows up
        if app.sheets.element(boundBy: 0).exists {
            app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }

        // Get Stats screenshot
        // Tap the back button if on an iPhone screen
        if UIDevice.current.userInterfaceIdiom == .phone {
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
        }
        app.tables["Blog Details Table"].cells.element(boundBy: 0).tap()
        sleep(1)
        snapshot("5-Stats")
    }
}
