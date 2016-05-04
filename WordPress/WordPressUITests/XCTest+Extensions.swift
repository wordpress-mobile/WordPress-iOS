import XCTest

extension XCTestCase {

     public func waitForElementToAppear(element: XCUIElement,
                                        file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectationForPredicate(existsPredicate,
                                evaluatedWithObject: element, handler: nil)

        waitForExpectationsWithTimeout(5) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 5 seconds."
                self.recordFailureWithDescription(message,
                                                  inFile: file, atLine: line, expected: true)
            }
        }
    }

    public func logoutIfNeeded() {
        let app = XCUIApplication()
        if !app.textFields["Username / Email"].exists && !app.textFields["Username"].exists{
            app.tabBars["Main Navigation"].buttons["Me"].tap()
            app.tables.elementBoundByIndex(0).swipeUp()
            app.tables.cells.staticTexts["Disconnect from WordPress.com"].tap()
            app.alerts.buttons["Disconnect"].tap()
            //Give some time to everything get proper saved.
            sleep(2)
        }
    }

    public func login() {
        let app = XCUIApplication()
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.oneStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.oneStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }

    public func loginOther() {
        let app = XCUIApplication()
        let usernameEmailTextField =  app.textFields["Username / Email"]
        usernameEmailTextField.tap()
        usernameEmailTextField.typeText(WordPressTestCredentials.twoStepUser)

        let passwordSecureTextField = app.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText(WordPressTestCredentials.twoStepPassword)

        app.buttons["Sign In"].tap()

        self.waitForElementToAppear(app.tabBars["Main Navigation"])
    }
}
