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

        XCUIDevice().orientation = UIDeviceOrientation.landscapeLeft

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() {
        let app = XCUIApplication()

        let usernameFieldExists = app.textFields["Email or username"].exists

        // Logout first if needed
        if !usernameFieldExists {
            app.tabBars["Main Navigation"].buttons["Me"].tap()
            app.tables.element(boundBy: 0).cells.element(boundBy: 5).tap() // Tap disconnect
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 1).tap() // Tap disconnect
        }

        // Login
        let username = ""

        let usernameEmailTextField =  app.textFields["Email or username"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(username)
        app.buttons["Next Button"].tap()


        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("")

        app.buttons["Log In Button"].tap()

        // Get Reader Screenshot
        app.tabBars["Main Navigation"].buttons["Reader"].tap(withNumberOfTaps: 2, numberOfTouches: 2)
        app.tables.staticTexts["Discover"].tap()
        sleep(5)
        snapshot("1-Reader")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["Notifications"].tap()
        snapshot("2-Notifications")

        // Get "Posts" screenshot
        app.tabBars["Main Navigation"].buttons["My Sites"].tap()
        app.tables.cells.element(boundBy: 4).tap() // tap Blog Posts
        sleep(2)
        snapshot("3-BlogPosts")

        // Get "Post" screenshot

        // Tap on the first post to bring up the editor
//        app.otherElements.element(boundBy: 9).tap()
//        app.tables["PostsTable"].cells.element(boundBy: 0).tap()
        app.tables["PostsTable"].tap()

        // Give the title field the focus
        app.otherElements["ZSSRichTextEditor"].children(matching: .textView).element(boundBy: 0).tap()
        snapshot("4-PostEditor")

        app.navigationBars["WPPostView"].buttons["Cancel"].tap()

        // Dismiss Unsaved Changes Alert if it shows up
        if app.sheets.element(boundBy: 0).exists {
            app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }

        // Get "Stats" screenshot
//        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap() // back button
        app.tables.element(boundBy: 0).cells.element(boundBy: 0).tap()
        sleep(1)
        snapshot("5-Stats")
    }
}
