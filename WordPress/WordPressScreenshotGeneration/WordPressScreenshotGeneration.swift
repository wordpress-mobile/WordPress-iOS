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
        
        // Logout first if needed
        if !app.textFields["Username / Email"].exists {
            app.tabBars["Main Navigation"].buttons.elementBoundByIndex(3).tap()
            app.tables.elementBoundByIndex(0).swipeUp()
            app.tables.cells.elementBoundByIndex(5).tap()
            app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        }
        
        // Login
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText("ENTER-USERNAME-HERE")
        
        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("ENTER-PASSWORD-HERE")
        
        app.buttons.elementBoundByIndex(1).tap()
        
        // Get Reader Screenshot
        app.tabBars["Main Navigation"].buttons["Reader"].tap()
        app.navigationBars["Blogs I Follow"].buttons["Menu"].tap()
        app.tables.staticTexts["Discover"].tap()
        sleep(5)
        snapshot("1-Reader")
        
        // Get Notifications screenshot
        app.tabBars["Main Navigation"].buttons["Notifications"].tap()
        snapshot("2-Notifications")
        
        // Get "Posts" screenshot
        app.tabBars.buttons.elementBoundByIndex(0).tap()
        app.tables.staticTexts.elementBoundByIndex(7).tap() // "Blog Posts" cell
        sleep(2)
        snapshot("3-BlogPosts")
        
        // Get "Post" screenshot
        let otherElements = app.otherElements
        otherElements.elementBoundByIndex(9).tap()
        // Pull up keyboard
        app.navigationBars["WPPostView"].buttons.elementBoundByIndex(4).tap() // "Edit" button
        app.staticTexts["We hiked along the Pacific, in the town of"].tap()
        snapshot("4-PostEditor")
        
        let cancelButton = app.navigationBars["WPPostView"].buttons.elementBoundByIndex(0) // "Cancel" button
        cancelButton.tap()
        app.sheets.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(0).tap()
        cancelButton.tap()
        app.navigationBars.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        let blah = app.tables.staticTexts
        print(blah.debugDescription)
        app.tables.staticTexts.elementBoundByIndex(4).tap() // "Stats" cell
        sleep(5)
        snapshot("5-Stats")
    }
}