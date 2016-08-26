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

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGenerateScreenshots() {
        let app = XCUIApplication()

        let username1Exist = app.textFields["Email or username"].exists
        let username2Exist = app.textFields["Username / Email"].exists

        // Logout first if needed
        if !username1Exist && !username2Exist {
            app.tabBars["Main Navigation"].buttons.elementBoundByIndex(3).tap()
            app.tables.elementBoundByIndex(0).swipeUp()
            app.tables.cells.elementBoundByIndex(5).tap()
            app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        }

        // Login
        let username = "ENTER-USERNAME-HERE"

        if  username1Exist {
            let usernameEmailTextField =  app.textFields["Email or username"]
            usernameEmailTextField.tap()
            usernameEmailTextField.typeText(username)
            app.buttons["NEXT"].tap()
        } else {
            let usernameEmailTextField =  app.textFields["Username / Email"]
            usernameEmailTextField.tap()
            usernameEmailTextField.typeText(username)
        }


        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("ENTER-PASSWORD-HERE")

        app.buttons["Sign In"].tap()

        // Get Reader Screenshot
        app.tabBars["Main Navigation"].buttons["Reader"].tap()

        app.tables.staticTexts["Discover"].tap()
        sleep(5)
        snapshot("1-Reader")

        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["Notifications"].tap()
        snapshot("2-Notifications")

        // Get "Posts" screenshot
        app.tabBars["Main Navigation"].buttons["My Sites"].tap()
        app.tables.staticTexts["Blog Posts"].tap()
        sleep(2)
        snapshot("3-BlogPosts")

        // Get "Post" screenshot
        let otherElements = app.otherElements
        otherElements.elementBoundByIndex(9).tap()

        // Dismiss Unsaved Changes Alert if it shows up
        if XCUIApplication().alerts["Unsaved changes."].exists {
            app.alerts["Unsaved changes."].collectionViews.buttons["OK"].tap()
            app.navigationBars["WPPostView"].buttons["Cancel"].tap()
            app.sheets["You have unsaved changes."].collectionViews.buttons["Discard"].tap()
            otherElements.elementBoundByIndex(9).tap()
        }

        // Pull up keyboard
        app.navigationBars["WPPostView"].buttons["Edit"].tap()
        app.staticTexts["We hiked along the Pacific, in the town of"].tap()
        snapshot("4-PostEditor")

        let cancelButton = app.navigationBars["WPPostView"].buttons.elementBoundByIndex(0) // "Cancel" button
        cancelButton.tap()
        app.sheets.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(0).tap()
        cancelButton.tap()
        app.navigationBars.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        let blah = app.tables.staticTexts
        print(blah.debugDescription)
        app.tables.staticTexts.elementBoundByIndex(2).tap() // "Stats" cell
        sleep(5)
        snapshot("5-Stats")
    }
}
